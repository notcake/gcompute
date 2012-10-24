local self = EditorHelper

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

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	local menu = vgui.Create ("GMenu")
	local playerMenu = vgui.Create ("GMenu")
	menu:AddOption ("Run on self")
		:SetIcon ("icon16/user_go.png")
		:AddEventListener ("Click",
			function ()
				RunStringEx (codeEditor:GetText (), codeEditor:GetSourceFile ():GetId ())
			end
		)
	menu:AddOption ("Run on server")
		:SetIcon ("icon16/server_go.png")
		:AddEventListener ("Click",
			function ()
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
				luadev.RunOnClients (codeEditor:GetText ())
			end
		)
	menu:AddOption ("Run on shared")
		:SetIcon ("icon16/world_go.png")
		:AddEventListener ("Click",
			function ()
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
					luadev.RunOnClient (codeEditor:GetText (), nil, v)
				end
			)
	end
	
	menu:Open ()
end

function self:ShouldOutdent (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local beforeCaret = " " .. line:Sub (1, location:GetCharacter ())
	
	if location:GetCharacter () < line:LengthExcludingLineBreak () then return false end
	
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