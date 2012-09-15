local self = EditorHelper

function self:GetNewLineIndentation (codeEditor, location)
	local line = codeEditor:GetDocument ():GetLine (location:GetLine ())
	local baseIndentation = string.match (line:GetText (), "^[ \t]*")
	local beforeCaret = line:Sub (1, location:GetCharacter ())
	if beforeCaret:find ("{[^}]*$") then
		return baseIndentation .. "\t"
	end
	return baseIndentation
end