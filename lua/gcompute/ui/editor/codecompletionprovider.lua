local self = {}
GCompute.Editor.CodeCompletionProvider = GCompute.MakeConstructor (self)

function self:ctor (codeEditor)
	self.Editor = codeEditor
	
	self.Language     = nil
	self.EditorHelper = nil
	
	self.RootNamespace    = nil
	self.RootNamespaceSet = nil
	self.UsingSource      = nil
	self.ObjectResolver   = nil
	
	self.Editor:AddEventListener ("CaretMoved", tostring (self),
		function (_, mouseCode)
			if not self.SuggestionFrame then return end
			if not self.SuggestionFrame:IsVisible () then return end
			self:Trigger ()
		end
	)
	self.Editor:AddEventListener ("LanguageChanged", tostring (self),
		function (_, oldLanguage, language)
			self:HandleLanguageChange (language)
		end
	)
	self.Editor:AddEventListener ("MouseUp", tostring (self),
		function (_, mouseCode)
			if mouseCode ~= MOUSE_LEFT then return end
			self:Trigger ()
		end
	)
	self.Editor:GetParent ():AddEventListener ("VisibleChanged", tostring (self),
		function (_, visible)
			if visible then return end
			if not self.SuggestionFrame then return end
			self.SuggestionFrame:SetVisible (false)
		end
	)
	
	self.SuggestionFrame = nil
	
	self:HandleLanguageChange (self.Editor:GetLanguage ())
end

function self:dtor ()
	self.Editor:RemoveEventListener ("CaretMoved",      tostring (self))
	self.Editor:RemoveEventListener ("LanguageChanged", tostring (self))
	self.Editor:RemoveEventListener ("MouseUp",         tostring (self))
	self.Editor:GetParent ():RemoveEventListener ("VisibleChanged",  tostring (self))
	
	if self.SuggestionFrame then
		self.SuggestionFrame:Remove ()
	end
end

function self:GetDocument ()
	if not self.Editor then return nil end
	return self.Editor:GetDocument ()
end

function self:GetEditor ()
	return self.Editor
end

function self:GetEditorHelper ()
	return self.EditorHelper
end

function self:GetLanguage ()
	return self.Language
end

function self:IsVisible ()
	if not self.SuggestionFrame then return false end
	return self.SuggestionFrame:IsVisible ()
end

function self:Trigger ()
	local lineNumber = self.Editor:GetCaretPos ():GetLine ()
	local column     = self.Editor:GetCaretPos ():GetColumn ()
	local line       = self:GetDocument ():GetLine (lineNumber)
	
	self.Editor:GetSyntaxHighlighter ():ForceHighlightLine (lineNumber)
	
	local character  = line:ColumnToCharacter (column, self.Editor:GetTextRenderer ())
	local tokens = line.Tokens
	local token = tokens and tokens [1]
	if not token then
		if self.SuggestionFrame then
			self.SuggestionFrame:SetVisible (false)
		end
		return
	end
	
	local previousToken = token.Previous
	while token and token.EndCharacter <= character do
		previousToken = token
		print (token.Value, token.StartCharacter, token.EndCharacter)
		token = token.Next
	end
	
	local namePrefix = token and GLib.UTF8.Sub (token.Value or "", 1, character - token.StartCharacter) or ""
	local shouldShowCodeCompletion = false
	
	if previousToken and previousToken.EndCharacter == character then
		if previousToken.TokenType == GCompute.TokenType.MemberIndexer then
			shouldShowCodeCompletion = true
		elseif previousToken.TokenType == GCompute.TokenType.Identifier then
			shouldShowCodeCompletion = true
			namePrefix = previousToken.Value
			previousToken = previousToken.Previous
		end
	else
		shouldShowCodeCompletion = token.TokenType == GCompute.TokenType.Identifier
	end
	print (namePrefix, GCompute.TokenType [token and token.TokenType])
	if not shouldShowCodeCompletion then
		if self.SuggestionFrame then
			self.SuggestionFrame:SetVisible (false)
		end
		return
	end
	
	self:CreateObjectResolver ()
	self:CreateSuggestionFrame ()
	self:CreateUsingSource ()
	
	self.SuggestionFrame:Clear ()
	
	-- Generate suggestions
	namePrefix = namePrefix:lower ()
	for name, member in self.RootNamespace:GetEnumerator () do
		if string.sub (name, 1, #namePrefix):lower () == namePrefix then
			self.SuggestionFrame:AddObjectDefinition (member)
		end
	end
	for usingDirective in self.UsingSource:GetUsings ():GetEnumerator () do
		local targetDefinition = usingDirective:GetNamespace ()
		if targetDefinition and targetDefinition:HasNamespace () then
			for name, member in targetDefinition:GetNamespace ():GetEnumerator () do
				if string.sub (name, 1, #namePrefix):lower () == namePrefix then
					self.SuggestionFrame:AddObjectDefinition (member)
				end
			end
		end
	end
	
	self.SuggestionFrame:Sort ()
	
	self.SuggestionFrame:SetVisible (true)
	self.SuggestionFrame:SetPos (
		self.Editor:LocalToScreen (self.Editor:LocationToPoint (lineNumber + 1, column))
	)
end

-- Internal, do not call
function self:CreateObjectResolver ()
	if self.ObjectResolver then return end
	
	self.RootNamespaceSet = GCompute.NamespaceSet ()
	self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	self.ObjectResolver = GCompute.ObjectResolver (self.RootNamespaceSet)
	
	return self.ObjectResolver
end

function self:CreateSuggestionFrame ()
	if self.SuggestionFrame then return end
	
	self.SuggestionFrame = vgui.Create ("GComputeCodeSuggestionFrame")
	self.SuggestionFrame:SetControl (self.Editor)
	
	return self.SuggestionFrame
end

function self:CreateUsingSource ()
	if self.UsingSource then return end
	
	self:CreateObjectResolver ()
	
	self.UsingSource = GCompute.NamespaceDefinition ()
	if self.Language then
		for usingDirective in self.Language:GetIntrinsicUsings ():GetEnumerator () do
			self.UsingSource:AddUsing (usingDirective:GetQualifiedName ()):Resolve (self.ObjectResolver)
		end
	end
	self.UsingSource:ResolveUsings (self.ObjectResolver)
end

function self:HandleLanguageChange (language)
	if self.Language == language then return end
	
	self.Language = language
	self.EditorHelper = self.Language and self.Language:GetEditorHelper ()
	
	local oldRootNamespace = self.RootNamespace
	self.RootNamespace = self.EditorHelper and self.EditorHelper:GetRootNamespace ()
	if self.RootNamespaceSet then
		self.RootNamespaceSet:RemoveNamespace (self.RootNamespace)
		self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	end
end