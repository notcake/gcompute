local self = {}
GCompute.Editor.TokenizedLineColorer = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:ColorLine (line, tabWidth)
	local lineNumber = line:GetLineNumber ()
	local token = line:GetStartToken ()
	
	local renderInstructions = GCompute.Containers.LinkedList ()
	
	if token.EndLine > lineNumber then
		-- Multi-line comment, ending on a line below us.
		renderInstructions:AddLast (
			{
				StartColumn = 0,
				EndColumn = line:GetWidth (tabWidth),
				String = line:GetText (),
				Color = self:GetTokenColor (token),
				Token = token
			}
		)
	else
		local column = 0
		local character = 0
		local startOffset = 1
		while token and token.Line <= lineNumber do
			local endCharacter = token.EndCharacter
			if token.EndLine > lineNumber then
				endCharacter = line:Length ()
			end
			
			local str = GLib.UTF8.SubOffset (line:GetText (), startOffset, 1, endCharacter - character)
			character = endCharacter
			startOffset = startOffset + str:len ()
			endColumn = column
			
			for _, character in GLib.UTF8.Iterator (str) do
				endColumn = endColumn + line:GetCharacterWidth (character, tabWidth)
			end
			
			renderInstructions:AddLast (
				{
					StartColumn = column,
					EndColumn   = endColumn,
					String      = str,
					Color       = self:GetTokenColor (token),
					Token = token
				}
			)
			
			column = endColumn
			token = token.Next
		end
	end
	
	renderInstructions:Filter (
		function (linkedListNode)
			return linkedListNode.Value.Token.TokenType ~= GCompute.TokenType.Whitespace
		end
	)
	line.CachedRenderInstructions = renderInstructions:ToArray ()
end

function self:GetTokenColor (token)
	local tokenType = token.TokenType
	if tokenType == GCompute.TokenType.String then
		return GLib.Colors.Gray
	elseif tokenType == GCompute.TokenType.Number then
		return GLib.Colors.SandyBrown
	elseif tokenType == GCompute.TokenType.Comment then
		return GLib.Colors.ForestGreen
	elseif tokenType == GCompute.TokenType.Keyword then
		return GLib.Colors.RoyalBlue
	elseif tokenType == GCompute.TokenType.Preprocessor then
		return GLib.Colors.Yellow
	elseif tokenType == GCompute.TokenType.Identifier then
		return GLib.Colors.LightSkyBlue
	elseif tokenType == GCompute.TokenType.Unknown then
		return GLib.Colors.Tomato
	end
	return GLib.Colors.White
end

GCompute.Editor.TokenizedLineColorer = GCompute.Editor.TokenizedLineColorer ()