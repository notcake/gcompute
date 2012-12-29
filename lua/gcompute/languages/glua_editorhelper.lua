local self = EditorHelper

function self:ctor (language)
	self.RootNamespace = nil
	
	self.LastStdOut = nil
	self.LastStdErr = nil
	
	GCompute.EPOE:AddEventListener ("LineReceived", tostring (self),
		function (_, lineData)
			self:ProcessEPOELine (lineData)
		end
	)
end

function self:dtor ()
	GCompute.EPOE:RemoveEventListener ("LineReceived", tostring (self))
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
		self.RootNamespace = GCompute.Lua.Table (nil, _G)
	end
	return self.RootNamespace
end

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	self.LastStdOut = stdOut
	self.LastStdErr = stdErr
	
	local menu = vgui.Create ("GMenu")
	local playerMenu = vgui.Create ("GMenu")
	menu:AddOption ("Run on self")
		:SetIcon ("icon16/user_go.png")
		:AddEventListener ("Click",
			function ()
				local document = codeEditor:GetDocument ()
				local fileId = document:HasPath () and document:GetPath () or ("@anonymous_" .. document:GetId ())
				
				if not self:ValidateCode (codeEditor:GetText (), fileId, compilerStdOut, compilerStdErr) then return end
				local f = CompileString (codeEditor:GetText (), fileId)
				
				local _ErrorNoHalt = ErrorNoHalt
				local _Msg         = Msg
				local _MsgN        = MsgN
				local _MsgC        = MsgC
				local _print       = print
				
				local function makeOutputter (outputFunction, separator)
					return function (...)
						local args = {...}
						for i = 1, table.maxn (args) do
							args [i] = tostring (args [i])
						end
						outputFunction (table.concat (args, separator))
					end
				end
				ErrorNoHalt = makeOutputter (
					function (text)
						stdErr:WriteLine (text)
						_ErrorNoHalt (text)
					end
				)
				Msg = makeOutputter (
					function (text)
						stdOut:WriteColor (text, GLib.Colors.SandyBrown)
					end
				)
				MsgN = makeOutputter (
					function (text)
						stdOut:WriteColor (text .. "\n", GLib.Colors.SandyBrown)
					end
				)
				MsgC = function (color, ...)
					local args = {...}
					for i = 1, table.maxn (args) do
						args [i] = tostring (args [i])
					end
					
					stdOut:WriteColor (
						table.concat (args),
						type (color) == "table" and
						type (color.r) == "number" and
						type (color.g) == "number" and
						type (color.b) == "number" and
						type (color.a) == "number" and
						color or GLib.Colors.White
					)
				end
				print = makeOutputter (
					function (text)
						stdOut:WriteLine (text)
					end,
					"\t"
				)
				
				xpcall (f,
					function (message)
						stdErr:WriteLine (message)
						stdErr:WriteLine (GLib.StackTrace (nil, 3))
						_ErrorNoHalt (message)
					end
				)
				
				ErrorNoHalt = _ErrorNoHalt
				Msg         = _Msg
				MsgN        = _MsgN
				MsgC        = _MsgC
				print       = _print
			end
		)
	menu:AddOption ("Run on server")
		:SetIcon ("icon16/server_go.png")
		:AddEventListener ("Click",
			function ()
				local document = codeEditor:GetDocument ()
				local fileId = document:HasPath () and document:GetPath () or ("@anonymous_" .. document:GetId ())
				
				if not self:ValidateCode (codeEditor:GetText (), fileId, compilerStdOut, compilerStdErr) then return end
				luadev.RunOnServer (codeEditor:GetText ())
			end
		)
	menu:AddOption ("Run on client")
		:SetIcon ("icon16/user_go.png")
		:SetSubMenu (playerMenu)
	menu:AddOption ("Run on clients")
		:SetIcon ("icon16/group_go.png")
		:AddEventListener ("Click",
			function ()
				local document = codeEditor:GetDocument ()
				local fileId = document:HasPath () and document:GetPath () or ("@anonymous_" .. document:GetId ())
				
				if not self:ValidateCode (codeEditor:GetText (), fileId, compilerStdOut, compilerStdErr) then return end
				luadev.RunOnClients (codeEditor:GetText ())
			end
		)
	menu:AddOption ("Run on shared")
		:SetIcon ("icon16/world_go.png")
		:AddEventListener ("Click",
			function ()
				local document = codeEditor:GetDocument ()
				local fileId = document:HasPath () and document:GetPath () or ("@anonymous_" .. document:GetId ())
				
				if not self:ValidateCode (codeEditor:GetText (), fileId, compilerStdOut, compilerStdErr) then return end
				luadev.RunOnShared (codeEditor:GetText ())
			end
		)
	menu:AddEventListener ("MenuClosed",
		function ()
			menu:Remove ()
			playerMenu:Remove ()
		end
	)
	
	local players = player.GetAll ()
	table.sort (players,
		function (a, b)
			return a:Name ():lower () < b:Name ():lower ()
		end
	)
	for _, v in ipairs (players) do
		playerMenu:AddOption (v:Name ())
			:SetIcon (v:IsAdmin () and "icon16/shield_go.png" or "icon16/user_go.png")
			:AddEventListener ("Click",
				function ()
					local document = codeEditor:GetDocument ()
					local fileId = document:HasPath () and document:GetPath () or ("@anonymous_" .. document:GetId ())
					
					if not self:ValidateCode (codeEditor:GetText (), fileId, compilerStdOut, compilerStdErr) then return end
					luadev.RunOnClient (codeEditor:GetText (), nil, v)
				end
			)
	end
	
	menu:Open ()
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