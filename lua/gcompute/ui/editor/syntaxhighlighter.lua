local self = {}
GCompute.Editor.SyntaxHighlighter = GCompute.MakeConstructor (self, GCompute.Editor.ITokenSink)

--[[
	Events:
		HighlightingFinished ()
			Fired when syntax highlighting has finished.
		HighlightingProgress (linesProcessed, totalLines)
			Fired when syntax highlighting has advanced.
		HighlightingStarted ()
			Fired when syntax highlighting has started.
		LineHighlighted (lineNumber, tokenArray)
			Fired when a line has been syntax highlighted.
]]

function self:ctor (document)
	self.Document = document
	
	self.Enabled = true
	
	self.Language = nil
	self.LanguageName = nil
	self.EditorHelper = nil
	
	self.LastThinkTime = CurTime ()
	
	self.CurrentLine = 0
	self.CurrentLineTokens = {}
	self.TokenizationStartTime = SysTime ()
	
	self.Document:AddEventListener ("LanguageChanged", tostring (self),
		function (_, oldLanguage, language)
			self:HandleLanguageChange (language)
		end
	)
	self.Document:AddEventListener ("LinesShifted", tostring (self),
		function (_, startLine, endLine, shift)
			self:InvalidateLine (startLine)
			self:InvalidateLine (startLine + shift)
		end
	)
	self.Document:AddEventListener ("TextCleared", tostring (self),
		function (_)
			self:InvalidateLine (0)
		end
	)
	self.Document:AddEventListener ("TextDeleted", tostring (self),
		function (_, deletionStart)
			self:InvalidateLine (deletionStart:GetLine ())
		end
	)
	self.Document:AddEventListener ("TextInserted", tostring (self),
		function (_, insertionLocation)
			self:InvalidateLine (insertionLocation:GetLine ())
		end
	)
	
	self:HandleLanguageChange (self.Document:GetLanguage ())
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	self.Document:RemoveEventListener ("LanguageChanged", tostring (self))
	self.Document:RemoveEventListener ("TextChanged",     tostring (self))
end

function self:GetDocument ()
	return self.Document
end

function self:GetEditorHelper ()
	return self.EditorHelper
end

function self:GetLanguage ()
	return self.Language
end

function self:GetProgress ()
	if self.Document:GetLineCount () == 0 then return 1 end
	return self.CurrentLine / self.Document:GetLineCount ()
end

function self:IsEnabled ()
	return self.Enabled
end

function self:SetEnabled (enabled)
	self.Enabled = enabled
end

function self:Think ()
	if self.LastThinkTime == CurTime () then return end
	self.LastThinkTime = CurTime ()
	
	if not self.EditorHelper then return end
	
	if self:IsEnabled () then
		if self.CurrentLine >= self.Document:GetLineCount () then return end
		
		local startTime = SysTime ()
		
		local previousLine = self.Document:GetLine (self.CurrentLine - 1)
		local previousOutState = previousLine and previousLine.TokenizationOutState
		local line
		
		while self.CurrentLine < self.Document:GetLineCount () do
			if SysTime () - startTime > 0.010 then break end
			
			line = self.Document:GetLine (self.CurrentLine)
			
			if line.TokenizationLanguage ~= self.LanguageName or
			   not self:StateEquals (line.TokenizationInState, previousOutState) or
			   not line.TokenizationOutState then
				line.TokenizationLanguage = self.LanguageName
				line.TokenizationInState  = previousOutState or {}
				line.TokenizationOutState = {}
				self.CurrentLineTokens = {}
				self.EditorHelper:TokenizeLine (line:GetText (), self, line.TokenizationInState, line.TokenizationOutState)
				line.Tokens = self.CurrentLineTokens
				
				self:DispatchEvent ("LineHighlighted", self.CurrentLine, line.Tokens)
			end
			
			previousLine = line
			previousOutState = line.TokenizationOutState
			self.CurrentLine = self.CurrentLine + 1
		end
		
		self:DispatchEvent ("HighlightingProgress", self.CurrentLine, self.Document:GetLineCount ())
		
		if self.CurrentLine >= self.Document:GetLineCount () then
			self:DispatchEvent ("HighlightingFinished")
			self.TokenizationStartTime = nil
		end
	end
end

-- ITokenSink
function self:Token (startCharacter, endCharacter, tokenType)
	if endCharacter <= 0 then return end
	
	local line = self.Document:GetLine (self.CurrentLine)
	local color = self:GetTokenColor (tokenType)
	
	line:SetColor (color, startCharacter, endCharacter)
	line:SetAttribute ("TokenType", tokenType, startCharacter, endCharacter)
	
	self.CurrentLineTokens [#self.CurrentLineTokens + 1] =
	{
		StartCharacter = startCharacter,
		EndCharacter   = endCharacter,
		TokenType      = tokenType
	}
end

function self:GetTokenColor (tokenType)
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

-- Internal, do not call
function self:HandleLanguageChange (language)
	self.Language = language
	self.LanguageName = self.Language and self.Language:GetName () or nil
	self.EditorHelper = self.Language and self.Language:GetEditorHelper ()
	
	self:InvalidateLine (0)
end

function self:InvalidateLine (line)
	if line < 0 then return end
	if line >= self.Document:GetLineCount () then return end
	
	if self.CurrentLine >= self.Document:GetLineCount () then
		self.TokenizationStartTime = SysTime ()
		self:DispatchEvent ("HighlightingStarted")
	end
	self.Document:GetLine (line).TokenizationOutState = nil
	self.CurrentLine = math.min (self.CurrentLine, line)
end

function self:StateEquals (s1, s2)
	if s1 == s2 then return true end
	if not s1 and s2     then return false end
	if     s1 and not s2 then return false end
	
	for k, v in pairs (s1) do
		if s2 [k] ~= v then return false end
	end
	for k, v in pairs (s2) do
		if s1 [k] ~= v then return false end
	end
	return true
end