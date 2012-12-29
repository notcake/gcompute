local self = EditorHelper

function self:ctor (language)
end

function self:GetCommentFormat ()
	return "#", "#[", "]#"
end

function self:GetNewLineIndentation (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local baseIndentation = string.match (line:GetText (), "^[ \t]*")
	local beforeCaret = line:Sub (1, location:GetCharacter ())
	if beforeCaret:find ("{[^}]*$") then
		return baseIndentation .. "\t"
	end
	return baseIndentation
end

function self:ShouldOutdent (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local beforeCaret = " " .. line:Sub (1, location:GetCharacter ())
	
	if location:GetCharacter () < line:GetLengthExcludingLineBreak () then return false end
	
	if beforeCaret:sub (-1, -1) == "}" then
		if not beforeCaret:find ("{[^}]*}$") then
			return true
		end
	end
	
	return false
end