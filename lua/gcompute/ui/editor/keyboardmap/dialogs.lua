GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_F,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return false end
		
		GCompute.OpenFindDialog (
			function (searchString, caseSensitive)
				if not caseSensitive then
					searchString = string.lower (searchString)
				end
				
				local caretLocation = self:GetDocument ():ColumnToCharacter (self:GetCaretPos (), self:GetTextRenderer ())
				
				local lineNumber = caretLocation:GetLine ()
				local text = self:GetDocument ():GetLine (lineNumber):GetText ()
				text = caseSensitive and text or string.lower (text)
				local foundPosition = string.find (text, searchString, GLib.UTF8.CharacterToOffset (text, caretLocation:GetCharacter () + 2), true)
				local foundCharacter = foundPosition and GLib.UTF8.Length (string.sub (text, 1, foundPosition - 1))
				
				if not foundCharacter then
					for i = lineNumber + 1, self:GetDocument ():GetLineCount () - 1 do
						text = self:GetDocument ():GetLine (i):GetText ()
						text = caseSensitive and text or string.lower (text)
						foundPosition = string.find (text, searchString, 1, true)
						if foundPosition then
							lineNumber = i
							foundCharacter = GLib.UTF8.Length (string.sub (text, 1, foundPosition - 1))
							break
						end
					end
				end
				
				if foundCharacter then
					self:SetCaretPos (
						self:GetDocument ():CharacterToColumn (
							GCompute.Editor.LineCharacterLocation (
								lineNumber,
								foundCharacter
							),
							self:GetTextRenderer ()
						)
					)
					self:SetSelection (self:GetCaretPos (), self:GetCaretPos ())
					return
				end
			end
		)
	end
)

GCompute.Editor.CodeEditorKeyboardMap:Register (KEY_G,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return false end
		
		GCompute.OpenGoToDialog (
			function (line)
				line = line - 1
				if line < 0 then line = 0 end
				if line >= self:GetDocument ():GetLineCount () then line = self:GetDocument ():GetLineCount () - 1 end
				self:SetCaretPos (GCompute.Editor.LineColumnLocation (line, 0))
			end
		)
	end
)