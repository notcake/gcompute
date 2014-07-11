local self = EditorHelper

function self:ctor (language)
	self.RootNamespace = nil
	
	self.LastStdOut = nil
	self.LastStdErr = nil
	
	GCompute.EPOE:AddEventListener ("LineReceived", self:GetHashCode (),
		function (_, lineData)
			self:ProcessEPOELine (lineData)
		end
	)
end

function self:dtor ()
	GCompute.EPOE:RemoveEventListener ("LineReceived", self:GetHashCode ())
end

function self:GetCommentFormat ()
	return "--", "--[[", "]]"
end

function self:GetNewLineIndentation (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local baseIndentation = string.match (line:GetText (), "^[ \t]*")
	local beforeCaret = " " .. line:Sub (1, location:GetCharacter ()) .. " "
	
	local doString       = string.match (beforeCaret, "^.*[^_a-zA-Z0-9]do[^_a-zA-Z0-9]")       or ""
	local repeatString   = string.match (beforeCaret, "^.*[^_a-zA-Z0-9]repeat[^_a-zA-Z0-9]")   or ""
	local thenString     = string.match (beforeCaret, "^.*[^_a-zA-Z0-9]then[^_a-zA-Z0-9]")     or ""
	local functionString = string.match (beforeCaret, "^.*[^_a-zA-Z0-9]function[^_a-zA-Z0-9]") or ""
	local found = doString ~= "" or repeatString ~= "" or thenString ~= "" or functionString ~= ""
	local endSearchStart = math.max (
		string.len (doString),
		string.len (repeatString),
		string.len (thenString),
		string.len (functionString)
	)
	
	local isRepeat = endSearchStart == string.len (repeatString)
	
	if found then
		if isRepeat then
			if not string.find (beforeCaret, "[^_a-zA-Z0-9]until[^_a-zA-Z0-9]", endSearchStart) then
				return baseIndentation .. "\t"
			end
		else
			if not string.find (beforeCaret, "[^_a-zA-Z0-9]end[^_a-zA-Z0-9]", endSearchStart) then
				return baseIndentation .. "\t"
			end
		end
	end
	if beforeCaret:find ("{[^}]*$") then
		return baseIndentation .. "\t"
	end
	return baseIndentation
end

function self:GetRootNamespace ()
	if not self.RootNamespace then
		self.RootNamespace = GCompute.Lua.Table ("_G", _G)
	end
	return self.RootNamespace
end

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	self.LastStdOut = stdOut
	self.LastStdErr = stdErr
	
	local function ExecuteCode (hostId)
		if GLib.CallSelfInThread () then return end
		
		local document = codeEditor:GetDocument ()
		local fileId = document:HasUri () and document:GetUri () or ("@anonymous_" .. document:GetId ())
		
		local code = codeEditor:GetText ()
		if not self:ValidateCode (code, fileId, compilerStdOut, compilerStdErr) then return end
		
		-- Execution context
		local executionContext, returnCode = GCompute.Execution.ExecutionService:CreateExecutionContext (GLib.GetLocalId (), hostId, "GLua", GCompute.Execution.ExecutionContextOptions.EasyContext)
		if not executionContext then
			compilerStdErr:WriteLine ("Failed to create execution context (" .. GCompute.ReturnCode [returnCode] .. ").")
			return
		end
		
		-- Execution instance
		local executionInstance, returnCode = executionContext:CreateExecutionInstance (code, nil, GCompute.Execution.ExecutionInstanceOptions.EasyContext + GCompute.Execution.ExecutionInstanceOptions.ExecuteImmediately + GCompute.Execution.ExecutionInstanceOptions.CaptureOutput)
		if executionInstance then
			executionInstance:GetCompilerStdOut ():ChainTo (compilerStdOut)
			executionInstance:GetCompilerStdErr ():ChainTo (compilerStdErr)
			executionInstance:GetStdOut ():ChainTo (stdOut)
			executionInstance:GetStdErr ():ChainTo (stdErr)
		else
			compilerStdErr:WriteLine ("Failed to create execution instance (" .. GCompute.ReturnCode [returnCode] .. ").")
		end
	end
	
	local menu = Gooey.Menu ()
	local playerMenu = Gooey.Menu ()
	menu:AddItem ("Run on self")
		:SetIcon ("icon16/user_go.png")
		:AddEventListener ("Click",
			function ()
				ExecuteCode (GLib.GetLocalId ())
			end
		)
	menu:AddItem ("Run on server")
		:SetEnabled (GCompute.Execution.RemoteExecutionService:IsAvailable ())
		:SetIcon ("icon16/server_go.png")
		:AddEventListener ("Click",
			function ()
				ExecuteCode (GLib.GetServerId ())
			end
		)
	menu:AddItem ("Run on client")
		:SetEnabled (GCompute.Execution.RemoteExecutionService:IsAvailable ())
		:SetIcon ("icon16/user_go.png")
		:SetSubMenu (playerMenu)
	menu:AddItem ("Run on clients")
		:SetEnabled (GCompute.Execution.RemoteExecutionService:IsAvailable ())
		:SetIcon ("icon16/group_go.png")
		:AddEventListener ("Click",
			function ()
				ExecuteCode ("Clients")
			end
		)
	menu:AddItem ("Run on shared")
		:SetEnabled (GCompute.Execution.RemoteExecutionService:IsAvailable ())
		:SetIcon ("icon16/world_go.png")
		:AddEventListener ("Click",
			function ()
				ExecuteCode ("Shared")
			end
		)
	menu:AddEventListener ("MenuClosed",
		function ()
			menu:dtor ()
			playerMenu:dtor ()
		end
	)
	
	local players = player.GetAll ()
	table.sort (players,
		function (a, b)
			return a:Name ():lower () < b:Name ():lower ()
		end
	)
	for _, v in ipairs (players) do
		playerMenu:AddItem (v:Name ())
			:SetEnabled (GCompute.Execution.RemoteExecutionService:IsAvailable ())
			:SetIcon (v:IsAdmin () and "icon16/shield_go.png" or "icon16/user_go.png")
			:AddEventListener ("Click",
				function ()
					ExecuteCode (GLib.GetPlayerId (v))
				end
			)
	end
	
	menu:Show (codeEditor)
end

function self:ShouldOutdent (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local beforeCaret = " " .. line:Sub (1, location:GetCharacter ())
	
	if location:GetCharacter () < line:GetLengthExcludingLineBreak () then return false end
	
	if beforeCaret:match ("[^_a-zA-Z0-9]if[^_a-zA-Z0-9].*[^_a-zA-Z0-9]end$") then
	elseif beforeCaret:sub (-4, -1):match ("[^_a-zA-Z0-9]end$") then
		return true
	end
	
	if beforeCaret:sub (-6, -1):match ("[^_a-zA-Z0-9]until$") then
		return true
	end
	
	if beforeCaret:sub (-1, -1) == "}" then
		if not beforeCaret:find ("{[^}]*}$") then
			return true
		end
	end
	
	return false
end

-- Internal, do not call
function self:ProcessEPOELine (lineData)
	if not self.LastStdErr then return end
	
	local localSteamId = GLib.GetLocalId ():sub (string.len ("STEAM_") + 1)
	if lineData.Text:find (localSteamId) then
		for _, segmentData in ipairs (lineData) do
			self.LastStdErr:WriteColor (segmentData.Text, segmentData.Color)
		end
		self.LastStdErr:WriteLine ("")
	end
end

function self:ValidateCode (code, sourceId, stdOut, stdErr)
	local f = CompileString (code, sourceId, false)
	if type (f) == "string" then
		stdErr:WriteLine (f)
		return false
	end
	
	return true
end