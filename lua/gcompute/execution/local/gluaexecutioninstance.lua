local self = {}
GCompute.Execution.GLuaExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (gluaExecutionContext, instanceOptions)
	self.UpvalueDetours = {}
	self.UpvalueBackup = {}
	self.LuaCompiler = GCompute.GLua.LuaCompiler ()
	
	self.ExecutionFunction = nil
	
	local captureOutput  = self:CapturesOutput ()
	local suppressOutput = self:SuppressesHostOutput ()
	if captureOutput or suppressOutput then
		local function concat (separator, ...)
			local args = {...}
			for i = 1, table.maxn (args) do
				args [i] = tostring (args [i])
			end
			return table.concat (args, separator)
		end
		
		self.UpvalueDetours ["ErrorNoHalt"] = function (...)
			if captureOutput      then self:GetStdErr ():Write (concat (nil, ...) .. "\n" .. GLib.Lua.StackTrace ():ToString ()) end
			if not suppressOutput then self.UpvalueBackup.ErrorNoHalt (...) end
		end
		
		self.UpvalueDetours ["Msg"] = function (...)
			if captureOutput      then self:GetStdOut ():WriteColor (concat (nil, ...), GLib.Colors.SandyBrown) end
			if not suppressOutput then self.UpvalueBackup.Msg (...) end
		end
		
		self.UpvalueDetours ["MsgN"] = function (...)
			if captureOutput      then self:GetStdOut ():WriteColor (concat (nil, ...) .. "\n", GLib.Colors.SandyBrown) end
			if not suppressOutput then self.UpvalueBackup.MsgN (...) end
		end
		
		self.UpvalueDetours ["MsgC"] = function (color, ...)
			if captureOutput then
				self:GetStdOut ():WriteColor (
					concat (nil, ...),
					type (color) == "table" and
					type (color.r) == "number" and
					type (color.g) == "number" and
					type (color.b) == "number" and
					type (color.a) == "number" and
					color or GLib.Colors.White
				)
			end
			if not suppressOutput then self.UpvalueBackup.MsgC (color, ...) end
		end
		
		self.UpvalueDetours ["print"] = function (...)
			if captureOutput      then self:GetStdOut ():WriteColor (concat ("\t", ...) .. "\n", GLib.Colors.White) end
			if not suppressOutput then self.UpvalueBackup.print (...) end
		end
		
		for upvalueName, upvalue in pairs (self.UpvalueDetours) do
			self.LuaCompiler:AddUpvalue (upvalueName, upvalue)
		end
	end
	
	if self:GetExecutionContext ():IsEasyContext () then
		local ownerEntity = GCompute.PlayerMonitor:GetUserEntity (self:GetOwnerId ())
		self.LuaCompiler:AddUpvalue ("me", ownerEntity)
		
		if ownerEntity and ownerEntity:IsValid () then
			self.LuaCompiler:AddUpvalue ("here",  ownerEntity:GetPos ())
			self.LuaCompiler:AddUpvalue ("there", ownerEntity:GetEyeTrace ().HitPos)
			self.LuaCompiler:AddUpvalue ("this",  ownerEntity:GetEyeTrace ().Entity)
		end
	end
end

-- Control
function self:Compile ()
	if self:IsCompiling () then return end
	if self:IsCompiled  () then return end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiling)
	
	if self:GetExecutionContext ():IsReplContext () then
		self.ExecutionFunction = self.LuaCompiler:Compile ("return " .. self.SourceFiles [1], self.SourceIds [1])
	end
	
	if not self.ExecutionFunction then
		local f, compilerError = self.LuaCompiler:Compile (self.SourceFiles [1], self.SourceIds [1])
		self.ExecutionFunction = f
		if compilerError then
			self:GetCompilerStdErr ():Write (compilerError)
		end
	end
	
	if self.ExecutionFunction then
		debug.setfenv (self.ExecutionFunction, self:GetExecutionContext ():GetEnvironment ())
	end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiled)
end

function self:Start ()
	if self:IsStarted    () then return end
	if self:IsTerminated () then return end
	
	-- CanStartExecution event
	if not self:DispatchEvent ("CanStartExecution") == false then return end
	
	if GLib.CallSelfInThread () then return end
	
	if not self:IsCompiled () then
		self:Compile ()
	end
	
	if not self.ExecutionFunction then
		self:SetState (GCompute.Execution.ExecutionInstanceState.Terminated)
		return
	end
	
	-- Setup printing function detours
	GLib.GetCurrentThread ():AddEventListener ("ExecutionSliceStarted", "GLuaExecutionInstance." .. self:GetHashCode (),
		function ()
			self:DetourPrintingFunctions ()
		end
	)
	GLib.GetCurrentThread ():AddEventListener ("ExecutionSliceEnded", "GLuaExecutionInstance." .. self:GetHashCode (),
		function ()
			self:UndetourPrintingFunctions ()
		end
	)
	
	self:DetourPrintingFunctions ()
	
	-- Run the code
	self:SetState (GCompute.Execution.ExecutionInstanceState.Running)
	
	;(
		function (success, ...)
			-- Restore printing functions
			self:UndetourPrintingFunctions ()
			
			GLib.GetCurrentThread ():RemoveEventListener ("ExecutionSliceStarted", "GLuaExecutionInstance." .. self:GetHashCode ())
			GLib.GetCurrentThread ():RemoveEventListener ("ExecutionSliceEnded",   "GLuaExecutionInstance." .. self:GetHashCode ())
			
			if self:GetExecutionContext ():IsReplContext () then
				if success then
					local printer = GCompute.GLua.Printing.DefaultPrinter:Clone ()
					printer:SetColorScheme (GCompute.SyntaxColoring.PlaceholderSyntaxColoringScheme)
					
					local returns = { ... }
					local returnCount = select ("#", ...)
					for i = 1, returnCount do
						if self:GetStdOut ():GetBytesWritten () > 0 then
							self:GetStdOut ():Write ("\n")
						end
						
						printer:Print (self:GetStdOut (), returns [i])
						
						self:HandleReplValue (returns [i])
					end
				else
					self:GetStdErr ():Write (...)
				end
			end
		end
	) (
		xpcall (self.ExecutionFunction,
			function (message)
				if message == "stack overflow" and pcall (debug.getlocal, 1024, 1) then return message end
				
				message = tostring (message)
				if self:CapturesOutput () then self:GetStdErr ():Write (message .. "\n" .. GLib.Lua.StackTrace (nil, nil, GLib.Lua.StackCaptureOptions.Arguments):ToString ()) end
				if not self:SuppressesHostOutput () then self.UpvalueBackup.ErrorNoHalt (message) end
			end
		)
	)
end

-- Internal, do not call
function self:DetourPrintingFunctions ()
	for upvalueName, upvalue in pairs (self.UpvalueDetours) do
		self.UpvalueBackup [upvalueName] = _G [upvalueName]
		_G [upvalueName] = upvalue
	end
end

function self:UndetourPrintingFunctions ()
	for upvalueName, upvalue in pairs (self.UpvalueDetours) do
		if _G [upvalueName] == upvalue then
			_G [upvalueName] = self.UpvalueBackup [upvalueName]
		end
	end
end

function self:HandleReplValue (obj)
	local type = type (obj)
	if type == "Panel" then
		self:HandlePanelReplValue (obj)
	end
end

function self:HandlePanelReplValue (panel)
	if self:GetOwnerId () ~= GLib.GetLocalId () then return end
	if not panel:IsValid () then return end
	
	local hookId = string.format ("GCompute.GLua.Repl.FlashPanel.%p", panel)
	local startTime = SysTime ()
	hook.Add ("PostRenderVGUI", hookId,
		function ()
			local t = SysTime () - startTime
			
			if not panel:IsValid () or
			   t > 3 then
				hook.Remove ("PostRenderVGUI", hookId)
				return
			end
			
			local x, y = panel:LocalToScreen (0, 0)
			local w, h = panel:GetSize ()
			
			-- Highlight children
			for _, child in ipairs (panel:GetChildren ()) do
				local childX, childY = child:LocalToScreen (0, 0)
				local childW, childH = child:GetSize ()
				surface.SetDrawColor (GLib.Colors.Orange)
				surface.DrawOutlinedRect (childX, childY, childW, childH)
			end
			
			-- Flashing border
			local borderThickness = 8
			if math.sin (2 * math.pi * 3.5 * t) > 0 then
				surface.SetDrawColor (GLib.Colors.Red)
				surface.DrawRect (x, y,                       w, borderThickness) -- Top border
				surface.DrawRect (x, y + h - borderThickness, w, borderThickness) -- Bottom border
				surface.DrawRect (x, y,                       borderThickness, h) -- Left border
				surface.DrawRect (x + w - borderThickness, y, borderThickness, h) -- Right border
			end
			
			local textLines = {}
			local textWidths = {}
			if panel.ClassName then
				textLines [#textLines + 1] = panel.ClassName
			end
			textLines [#textLines + 1] = tostring (w) .. " x " .. tostring (h)
			
			-- Text
			surface.SetFont ("DermaLarge")
			surface.SetTextColor (GLib.Colors.White)
			
			-- Measure text
			local textWidth  = 0
			local textHeight = 0
			local lineHeight = 0
			for i = 1, #textLines do
				textWidths [i], lineHeight = surface.GetTextSize (textLines [i])
				textWidth = math.max (textWidth, textWidths [i])
			end
			textWidth  = textWidth + 16
			textHeight = lineHeight * #textLines + 16
			
			-- Draw text background
			local textX = math.max (0, x + w / 2 - textWidth  / 2)
			local textY = math.max (0, y + h / 2 - textHeight / 2)
			surface.SetDrawColor (Color (0, 0, 0, 128))
			surface.DrawRect (textX, textY, textWidth, textHeight)
			
			if textX + textWidth  > ScrW () then textX = ScrW () - textWidth  end
			if textY + textHeight > ScrH () then textY = ScrH () - textHeight end
			
			-- Draw text
			local centreX = textX + textWidth / 2
			for i = 1, #textLines do
				surface.SetTextPos (centreX - textWidths [i] / 2, textY + 8 + (i - 1) * lineHeight)
				surface.DrawText (textLines [i])
			end
		end
	)
end