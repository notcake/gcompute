local self = {}
GCompute.Editor.IdentifierHighlighter = GCompute.MakeConstructor (self)

function self:ctor (document, syntaxHighlighter)
	self.Document = document
	self.SyntaxHighlighter = syntaxHighlighter
	
	self.UnprocessedLines = {}
	
	self.Enabled = true
	
	self.Language     = nil
	self.EditorHelper = nil
	
	self.RootNamespace    = nil
	self.RootNamespaceSet = nil
	self.UsingSource      = nil
	self.ObjectResolver   = nil
	
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
end

function self:dtor ()
	self:UnhookLanguage (self.Language)
	
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

function self:Think ()
	if not next (self.UnprocessedLines) then return end
	
	self:CreateObjectResolver ()
	self:CreateUsingSource ()
	
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
function self:CreateObjectResolver ()
	if self.ObjectResolver then return end
	
	self.RootNamespaceSet = GCompute.NamespaceSet ()
	self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	self.ObjectResolver = GCompute.ObjectResolver (self.RootNamespaceSet)
	
	return self.ObjectResolver
end

function self:CreateUsingSource ()
	if self.UsingSource then return end
	
	self:CreateObjectResolver ()
	
	self.UsingSource = GCompute.NamespaceDefinition ()
	if self.Language then
		for usingDirective in self.Language:GetIntrinsicUsings ():GetEnumerator () do
			self.UsingSource:AddUsing (usingDirective:GetQualifiedName ())
		end
	end
	self.UsingSource:ResolveUsings (self.ObjectResolver)
end

function self:HandleLanguageChange (language)
	if self.Language == language then return end
	
	self:UnhookLanguage (self.Language)
	self.Language = language
	self:HookLanguage (self.Language)
	self.LanguageName = self.Language and self.Language:GetName () or nil
	self.EditorHelper = self.Language and self.Language:GetEditorHelper ()
	
	self:HandleNamespaceChange ()
end

function self:HandleNamespaceChange ()
	local oldRootNamespace = self.RootNamespace
	self.RootNamespace = self.EditorHelper and self.EditorHelper:GetRootNamespace ()
	if self.RootNamespaceSet then
		self.RootNamespaceSet:RemoveNamespace (oldRootNamespace)
		self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	end
	
	-- Invalidate using source
	self.UsingSource = nil
	
	for i = 0, self.Document:GetLineCount () - 1 do
		self.UnprocessedLines [i] = self.Document:GetLine (i).Tokens
	end
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

function self:HookLanguage (language)
	if not language then return end
	
	language:AddEventListener ("NamespaceChanged", tostring (self),
		function ()
			self:HandleNamespaceChange ()
		end
	)
end

function self:UnhookLanguage (language)
	if not language then return end
	
	language:RemoveEventListener ("NamespaceChanged", tostring (self))
end