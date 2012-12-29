local self = {}
GCompute.Editor.IdentifierHighlighter = GCompute.MakeConstructor (self)

--[[
	Events:
]]

function self:ctor (document, syntaxHighlighter)
	self.Document = document
	self.SyntaxHighlighter = syntaxHighlighter
	
	self.UnprocessedLines = {}
	
	self.Enabled = true
	
	self.Language = nil
	self.EditorHelper = nil
	
	self.RootNamespace = nil
	self.RootNamespaceSet = GCompute.NamespaceSet ()
	self.UsingSource = nil
	self.ObjectResolver = GCompute.ObjectResolver (self.RootNamespaceSet)
	
	self.Document:AddEventListener ("LanguageChanged", tostring (self),
		function (_, oldLanguage, language)
			self:HandleLanguageChange (language)
		end
	)
	self.SyntaxHighlighter:AddEventListener ("LineHighlighted", tostring (self),
		function (_, lineNumber, tokens)
			self.UnprocessedLines [lineNumber] = tokens
		end
	)
	
	self:HandleLanguageChange (self.Document:GetLanguage ())
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	self.Document:RemoveEventListener ("LanguageChanged", tostring (self))
	self.SyntaxHighlighter:RemoveEventListener ("LineHighlighted", tostring (self))
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

function self:IsEnabled ()
	return self.Enabled
end

function self:SetEnabled (enabled)
	self.Enabled = enabled
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

function self:Think ()
	if not next (self.UnprocessedLines) then return end
	
	local startTime = SysTime ()
	local lineNumber
	local tokens
	while SysTime () - startTime < 0.001 do
		lineNumber, tokens = next (self.UnprocessedLines)
		if not lineNumber then break end
		
		self.UnprocessedLines [lineNumber] = nil
		if lineNumber < self.Document:GetLineCount () then
			self:ProcessLine (lineNumber, tokens)
		end
	end
end

-- Internal, do not call
function self:HandleLanguageChange (language)
	if self.Language == language then return end
	
	self.RootNamespaceSet:RemoveNamespace (self.RootNamespace)
	
	self.Language = language
	self.LanguageName = self.Language and self.Language:GetName () or nil
	self.EditorHelper = self.Language and self.Language:GetEditorHelper ()
	self.RootNamespace = self.EditorHelper and self.EditorHelper:GetRootNamespace ()
	
	self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	
	self.UsingSource = GCompute.NamespaceDefinition ()
	if self.Language then
		for usingDirective in self.Language:GetIntrinsicUsings ():GetEnumerator () do
			self.UsingSource:AddUsing (usingDirective:GetQualifiedName ())
		end
	end
	self.UsingSource:ResolveUsings (self.ObjectResolver)
end

function self:ProcessLine (lineNumber, tokens)
	local indexing = false
	local lastResolutionResults = nil
	local previousTokenType
	for _, token in ipairs (tokens) do
		if previousTokenType ~= GCompute.TokenType.Preprocessor and
		   token.TokenType == GCompute.TokenType.Identifier then
			token.ResolutionResults = GCompute.ResolutionResults ()
			
			if not lastResolutionResults then
				indexing = false
			end
			
			if indexing then
				self.ObjectResolver:ResolveQualifiedIdentifier (token.ResolutionResults, lastResolutionResults, token.Value, self.UsingSource)
			else
				self.ObjectResolver:ResolveUnqualifiedIdentifier (token.ResolutionResults, token.Value, self.UsingSource)
			end
			
			if token.ResolutionResults:GetFilteredResultCount () > 0 then
				token.ResolutionResults:FilterByLocality ()
				self.Document:GetLine (lineNumber):SetColor (GLib.Colors.SkyBlue, token.StartCharacter, token.EndCharacter)
			end
			
			lastResolutionResults = token.ResolutionResults
		elseif token.TokenType == GCompute.TokenType.MemberIndexer then
			indexing = true
		elseif token.TokenType == GCompute.TokenType.Whitespace or
			   token.TokenType == GCompute.TokenType.Newline then
		else
			indexing = false
			lastResolutionResults = nil
		end
		
		previousTokenType = token.TokenType
	end
end