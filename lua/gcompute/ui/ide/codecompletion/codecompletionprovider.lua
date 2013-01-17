local self = {}
GCompute.IDE.CodeCompletion.CodeCompletionProvider = GCompute.MakeConstructor (self)

function self:ctor (codeEditor)
	self.Editor = codeEditor
	
	self.Language     = nil
	self.EditorHelper = nil
	
	self.RootNamespace    = nil
	self.RootNamespaceSet = nil
	self.UsingSource      = nil
	self.ObjectResolver   = nil
	
	self.TriggerOnBackspace = false
	
	self.SuggestionFrame = nil
	self.AnchorLine      = 0
	self.AnchorCharacter = 0
	
	self.NameLine = 0
	self.NameStartCharacter = 0
	self.NameEndCharacter   = 0
	self.NamePrefix = ""
	self.FullName   = ""
	
	self.Editor:AddEventListener ("CaretMoved", tostring (self),
		function (_, caretLocation)
			if not self.SuggestionFrame then return end
			if not self.TriggerOnBackspace and
			   not self.SuggestionFrame:IsVisible () and
			   caretLocation:GetLine () ~= self.NameLine then
				return
			end
			self:SetVisible (false)
			self:SetToolTipVisible (false)
		end
	)
	self.Editor:AddEventListener ("ItemRedone", tostring (self),
		function (_)
			self:Trigger ()
		end
	)
	self.Editor:AddEventListener ("ItemUndone", tostring (self),
		function (_)
			self:Trigger ()
		end
	)
	self.Editor:AddEventListener ("LanguageChanged", tostring (self),
		function (_, oldLanguage, language)
			self:HandleLanguageChange (language)
		end
	)
	self.Editor:AddEventListener ("SizeChanged", tostring (self),
		function (_)
			if not self:IsVisible () then return end
			if self.Editor:IsCaretVisible () then return end
			self.SuggestionFrame:SetVisible (false)
		end
	)
	self.Editor:AddEventListener ("ViewLocationChanged", tostring (self),
		function (_)
			if not self:IsVisible () then return end
			if self.Editor:IsCaretVisible () then
				self:UpdateSuggestionFramePosition ()
			else
				self.SuggestionFrame:SetVisible (false)
			end
		end
	)
	self.Editor:GetParent ():AddEventListener ("VisibleChanged", tostring (self),
		function (_, visible)
			if visible then return end
			if not self.SuggestionFrame then return end
			self.SuggestionFrame:SetVisible (false)
			self.TriggerOnBackspace = false
		end
	)
	
	self:HandleLanguageChange (self.Editor:GetLanguage ())
end

function self:dtor ()
	self.Editor:RemoveEventListener ("CaretMoved",          tostring (self))
	self.Editor:RemoveEventListener ("ItemRedone",          tostring (self))
	self.Editor:RemoveEventListener ("ItemUndone",          tostring (self))
	self.Editor:RemoveEventListener ("LanguageChanged",     tostring (self))
	self.Editor:RemoveEventListener ("MouseUp",             tostring (self))
	self.Editor:RemoveEventListener ("SizeChanged",         tostring (self))
	self.Editor:RemoveEventListener ("ViewLocationChanged", tostring (self))
	self.Editor:GetParent ():RemoveEventListener ("VisibleChanged",  tostring (self))
	
	if self.SuggestionFrame then
		self.SuggestionFrame:Remove ()
	end
end

function self:CommitSuggestion (itemType, item)
	itemType = itemType or self.SuggestionFrame:GetSelectedItemType ()
	item     = item     or self.SuggestionFrame:GetSelectedItem ()
	if itemType == GCompute.IDE.CodeCompletion.SuggestionType.None then return end
	
	local replacementName
	if itemType == GCompute.IDE.CodeCompletion.SuggestionType.Keyword then
		replacementName = item
	elseif itemType == GCompute.IDE.CodeCompletion.SuggestionType.Definition then
		replacementName = item:GetShortName ()
	else
		GCompute.Error ("CodeCompletionProvider:CommitSuggestion : Unhandled item type (" .. itemType .. ")")
	end
	
	local toolTipVisible = self.SuggestionFrame:IsToolTipVisible ()
	
	if replacementName == self.FullName then
		self.Editor:SetCaretPos (
			self.Editor:GetDocument ():CharacterToColumn (
				GCompute.IDE.LineCharacterLocation (
					self.NameLine,
					self.NameEndCharacter
				),
				self.Editor:GetTextRenderer ()
			)
		)
		self.Editor:SetSelection (self.Editor:GetCaretPos (), self.Editor:GetCaretPos ())
	else
		self.Editor:ReplaceText (
			GCompute.IDE.LineCharacterLocation (self.NameLine, self.NameStartCharacter),
			GCompute.IDE.LineCharacterLocation (self.NameLine, self.NameEndCharacter),
			replacementName
		)
	end
	
	self.SuggestionFrame:SetVisible (false)
	self.SuggestionFrame:SetToolTipVisible (toolTipVisible)
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

function self:HandleKey (keyCode, ctrl, shift, alt)
	if not self:IsVisible () then return false end
	if ctrl or shift or alt then return false end
	
	if keyCode == KEY_UP then
		self.SuggestionFrame:SelectPrevious ()
		return true
	elseif keyCode == KEY_DOWN then
		self.SuggestionFrame:SelectNext ()
		return true
	elseif keyCode == KEY_TAB then
		self:CommitSuggestion ()
		return true
	elseif keyCode == KEY_ESCAPE then
		self:SetToolTipVisible (false)
		self:SetVisible (false)
		gui.HideGameUI ()
		return true
	end
end

function self:HandlePostKey (keyCode, ctrl, shift, alt)
	if keyCode == KEY_BACKSPACE then
		self:Trigger ()
	end
end

function self:HandleText (text, pasted)
	if not self:IsVisible () then return end
	if pasted then return end
	
	if GLib.Unicode.IsLetterOrDigit (text) then return end
end

function self:IsVisible ()
	if not self.SuggestionFrame then return false end
	return self.SuggestionFrame:IsVisible ()
end

function self:IsToolTipVisible ()
	if not self.SuggestionFrame then return false end
	return self.SuggestionFrame:IsToolTipVisible ()
end

function self:SetToolTipVisible (toolTipVisible)
	if not self.SuggestionFrame then return end
	self.SuggestionFrame:SetToolTipVisible (toolTipVisible)
end

function self:SetVisible (visible)
	if not self.SuggestionFrame then return end
	self.SuggestionFrame:SetVisible (visible)
end

function self:Trigger (forceShow)
	local lineNumber = self.Editor:GetCaretPos ():GetLine ()
	local column     = self.Editor:GetCaretPos ():GetColumn ()
	local line       = self:GetDocument ():GetLine (lineNumber)
	
	if self.Editor:IsSelectionMultiline () then
		self:SetVisible (false)
		self:SetToolTipVisible (false)
		return
	end
	self.Editor:GetSyntaxHighlighter ():ForceHighlightLine (lineNumber)
	
	local character  = line:ColumnToCharacter (column, self.Editor:GetTextRenderer ())
	local tokens = line.Tokens
	local token = tokens and tokens [1]
	
	local previousToken = token and token.Previous
	while token and token.EndCharacter <= character do
		previousToken = token
		token = token.Next
	end
	
	-- Work out the parameters for name completion
	local nameStartCharacter
	local nameEndCharacter
	local namePrefix = token and GLib.UTF8.Sub (token.Value or "", 1, character - token.StartCharacter) or ""
	local fullName   = namePrefix
	local shouldShowCodeCompletion = false
	
	local acceptKeywords = forceShow
	local tokenType = token and token.TokenType
	if previousToken and previousToken.EndCharacter == character then
		-- Caret is at the end of a token
		
		nameStartCharacter = previousToken.EndCharacter
		nameEndCharacter   = previousToken.EndCharacter
		fullName           = ""
		
		if previousToken.TokenType == GCompute.TokenType.MemberIndexer then
			shouldShowCodeCompletion = true
			if tokenType == GCompute.TokenType.Identifier or
			   tokenType == GCompute.TokenType.Keyword then
				-- The caret is also at the start of an identifier
				nameEndCharacter   = token.EndCharacter
				fullName           = token.Value
			end
		elseif previousToken.TokenType == GCompute.TokenType.Identifier or
		       acceptKeywords and previousToken.TokenType == GCompute.TokenType.Keyword then
			shouldShowCodeCompletion = true
			nameStartCharacter       = previousToken.StartCharacter
			nameEndCharacter         = previousToken.EndCharacter
			namePrefix               = previousToken.Value
			fullName                 = previousToken.Value
			previousToken            = previousToken.Previous
		end
	elseif token then
		-- Caret is mid-way through a token OR at the start of the first token
		local isIdentifierToken = token and tokenType == GCompute.TokenType.Identifier
		isIdentifierToken = isIdentifierToken or acceptKeywords and tokenType == GCompute.TokenType.Keyword
		shouldShowCodeCompletion = isIdentifierToken
		
		nameStartCharacter = token and token.StartCharacter or 0
		nameEndCharacter   = token and token.EndCharacter   or 0
		fullName           = token and token.Value or fullName
		
		if not previousToken then
			-- Caret is at the start of the first token
			shouldShowCodeCompletion = false
			nameEndCharacter = isIdentifierToken and token.EndCharacter or nameStartCharacter
			fullName         = isIdentifierToken and token.Value        or ""
		end
	else
		-- Line is empty
		nameStartCharacter = 0
		nameEndCharacter   = 0
		fullName           = ""
	end
	shouldShowCodeCompletion = shouldShowCodeCompletion or forceShow
	
	-- Abort if the caret is not visible or
	-- it does not make sense to search for a name
	if not shouldShowCodeCompletion or
	   not self.Editor:IsCaretVisible () then
		self:SetVisible (false)
		return
	end
	
	self:CreateObjectResolver ()
	self:CreateSuggestionFrame ()
	self:CreateUsingSource ()
	
	if self:IsVisible () and
	   self.NameLine == lineNumber and
	   self.NameStartCharacter == nameStartCharacter and
	   self.NamePrefix == namePrefix then
		-- The suggestion box is already open, do not regenerate it
		return
	end
	
	-- Remember parameters
	self.NameLine           = lineNumber
	self.NameStartCharacter = nameStartCharacter
	self.NameEndCharacter   = nameEndCharacter
	self.NamePrefix         = namePrefix
	self.FullName           = fullName
	
	-- Build chain of member indexes
	local resolutionResults = GCompute.ResolutionResults ()
	resolutionResults:AddResult (GCompute.ResolutionResult (self.RootNamespace))
	local nameTokenChain = self:BuildPreviousIndexingTokenChain (previousToken)
	
	-- Resolve member chain
	if #nameTokenChain > 0 then
		local newResolutionResults = GCompute.ResolutionResults ()
		self.ObjectResolver:ResolveUnqualifiedIdentifier (newResolutionResults, nameTokenChain [1].Value, self.UsingSource)
		newResolutionResults:FilterByLocality ()
		resolutionResults = newResolutionResults
		
		for i = 2, #nameTokenChain do
			newResolutionResults = GCompute.ResolutionResults ()
			self.ObjectResolver:ResolveQualifiedIdentifier (newResolutionResults, resolutionResults, nameTokenChain [i].Value, self.UsingSource)
			newResolutionResults:FilterByLocality ()
			resolutionResults = newResolutionResults
			if resolutionResults:GetFilteredResultCount () == 0 then break end
		end
	end
	
	self.SuggestionFrame:Clear ()
	
	-- Generate suggestions
	local lowercaseNamePrefix = namePrefix:lower ()
	local preferredItem = nil
	
	for definition in resolutionResults:GetFilteredResultObjectEnumerator () do
		definition = definition:UnwrapAlias ()
		if definition:IsOverloadedClass () then
			definition = definition:GetDefaultClass ()
		end
		
		if definition:HasNamespace () and not definition:IsMethod () then
			-- Probe names of interest so that they show up in lazily-resolved namespaces
			preferredItem = preferredItem or self.SuggestionFrame:AddObjectDefinition (definition:GetNamespace ():GetMember (fullName))
			preferredItem = preferredItem or self.SuggestionFrame:AddObjectDefinition (definition:GetNamespace ():GetMember (namePrefix))
			
			for name, member in definition:GetNamespace ():GetEnumerator () do
				if self.SuggestionFrame:GetItemCount () >= 20 then break end
				if string.sub (name, 1, #lowercaseNamePrefix):lower () == lowercaseNamePrefix then
					self.SuggestionFrame:AddObjectDefinition (member)
				end
			end
		end
	end
	
	if #nameTokenChain == 0 then
		-- Global lookup, we have to take usings into account
		for usingDirective in self.UsingSource:GetUsings ():GetEnumerator () do
			local targetDefinition = usingDirective:GetNamespace ()
			if targetDefinition and targetDefinition:HasNamespace () then
				-- Probe names of interest so that they show up in lazily-resolved namespaces
				preferredItem = preferredItem or self.SuggestionFrame:AddObjectDefinition (targetDefinition:GetNamespace ():GetMember (namePrefix))
				preferredItem = preferredItem or self.SuggestionFrame:AddObjectDefinition (targetDefinition:GetNamespace ():GetMember (fullName))
				
				for name, member in targetDefinition:GetNamespace ():GetEnumerator () do
					if self.SuggestionFrame:GetItemCount () >= 20 then break end
					if string.sub (name, 1, #lowercaseNamePrefix):lower () == lowercaseNamePrefix then
						self.SuggestionFrame:AddObjectDefinition (member)
					end
				end
			end
		end
		
		-- Global lookup, keywords are acceptable
		for keyword in self.Language:GetKeywordEnumerator () do
			if string.sub (keyword, 1, #lowercaseNamePrefix):lower () == lowercaseNamePrefix then
				self.SuggestionFrame:AddKeyword (keyword)
			end
		end
	end
	
	self.SuggestionFrame:Sort ()
	if preferredItem then
		self.SuggestionFrame:SelectItem (preferredItem)
		timer.Simple (0.001,
			function ()
				if not preferredItem:IsValid () then return end
				self.SuggestionFrame:EnsureVisible (preferredItem)
			end
		)
	else
		self.SuggestionFrame:SelectById (1)
	end
	
	self.TriggerOnBackspace = true
	self:SetVisible (not self.SuggestionFrame:IsEmpty ())
	self:SetToolTipVisible (not self.SuggestionFrame:IsEmpty ())
	self.AnchorLine      = lineNumber
	self.AnchorCharacter = nameStartCharacter
	self:UpdateSuggestionFramePosition ()
end

-- Internal, do not call
function self:BuildPreviousIndexingTokenChain (token)
	local expectingIndexer = true
	local reverseTokens = {}
	while token do
		if expectingIndexer then
			if token.TokenType == GCompute.TokenType.MemberIndexer then
				expectingIndexer = false
			elseif token.TokenType == GCompute.TokenType.Whitespace or
			       token.TokenType == GCompute.TokenType.Newline then
			else
				break
			end
		else
			if token.TokenType == GCompute.TokenType.Identifier or
			   token.TokenType == GCompute.TokenType.Keyword then
				reverseTokens [#reverseTokens + 1] = token
				expectingIndexer = true
			elseif token.TokenType == GCompute.TokenType.Whitespace or
			       token.TokenType == GCompute.TokenType.Newline then
			else
				break
			end
		end
		
		token = token.Previous
	end
	
	-- Reverse the array
	local tokens = {}
	for i = #reverseTokens, 1, -1 do
		tokens [#tokens + 1] = reverseTokens [i]
	end
	return tokens
end

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
	self.SuggestionFrame:SetFont (self.Editor.Settings.Font)
	
	self.SuggestionFrame:AddEventListener ("ItemChosen",
		function (_, itemType, item)
			self:CommitSuggestion (itemType, item)
		end
	)
	
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
		self.RootNamespaceSet:RemoveNamespace (oldRootNamespace)
		self.RootNamespaceSet:AddNamespace (self.RootNamespace)
	end
	
	-- Invalidate using source
	self.UsingSource = nil
end

function self:UpdateSuggestionFramePosition ()
	self.SuggestionFrame:SetAlignedPos (
		self.Editor:LocalToScreen (
			self.Editor:LocationToPoint (
				self.AnchorLine + 1,
				self.Editor:GetDocument ():GetLine (self.AnchorLine):CharacterToColumn (self.AnchorCharacter, self.Editor:GetTextRenderer ())
			)
		)
	)
end