local self = {}
GCompute.Editor.DefaultLineColorer = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:ColorLine (line, tabWidth)
	self:ColorLineWithColor (line, GLib.Colors.White, tabWidth)
end

function self:ColorLineWithColor (line, color, tabWidth)
	color = color or GLib.Colors.Lime
	
	local startColumn = 0
	local column = 0
	local str = ""
	local characterWidth = 0
	for _, character in GLib.UTF8.Iterator (line:GetText ()) do
		if character:len () > 1 then
			line.CachedRenderInstructions [#line.CachedRenderInstructions + 1] =
			{
				StartColumn = startColumn,
				EndColumn = column,
				String = str,
				Color = color
			}
			
			startColumn = column
			str = ""
		end
		
		str = str .. character
		characterWidth = line:GetCharacterWidth (character, tabWidth)
		column = column + characterWidth
		
		if character:len () > 1 or characterWidth ~= 1 or column - startColumn > 100 then
			line.CachedRenderInstructions [#line.CachedRenderInstructions + 1] =
			{
				StartColumn = startColumn,
				EndColumn   = column,
				String      = str,
				Color       = color
			}
			
			startColumn = column
			str = ""
		end
	end
	
	if str ~= "" then
		line.CachedRenderInstructions [#line.CachedRenderInstructions + 1] =
		{
			StartColumn = startColumn,
			EndColumn   = column,
			String      = str,
			Color       = color
		}
	end
end

GCompute.Editor.DefaultLineColorer = GCompute.Editor.DefaultLineColorer ()