local self = {}
GCompute.IEditorHelper = GCompute.MakeConstructor (self)

function self:ctor (language)
	self.Language = language
end

function self:CanBlockComment ()
	local _, blockStart, blockEnd = self:GetCommentFormat ()
	return blockStart ~= nil and blockEnd ~= nil
end

function self:CanLineComment ()
	return self:GetCommentFormat () ~= nil
end

--- Returns the comment format of the language
-- @return The string used to start line comments
-- @return The string used to start block comments
-- @return The string used to end block comments
function self:GetCommentFormat ()
	return nil, nil, nil
end

function self:GetNewLineIndentation (codeEditor, location)
	return string.match (codeEditor:GetDocument ():GetLine (location:GetLine ()):GetText (), "^[ \t]*")
end

function self:Run (codeEditor, compilerStdOut, compilerStdErr, stdOut, stdErr)
	local document = codeEditor:GetDocument ()
	local code = codeEditor:GetText ()
	
	local sourceFile = document:HasPath () and GCompute.SourceFileCache:CreateSourceFileFromPath (document:GetPath ()) or nil
	sourceFile = sourceFile or GCompute.SourceFileCache:CreateAnonymousSourceFile ()
	sourceFile:SetCode (code)

	local compilationUnit = sourceFile:GetCompilationUnit ()
	compilationUnit:ClearPassDurations ()
	compilationUnit:ClearMessages ()
	
	local compilationGroup = GCompute.CompilationGroup (sourceFile:GetId (), GLib.GetLocalId ())
	compilationGroup:AddSourceFile (sourceFile)
	
	compilationGroup:Compile (
		function (success)
			local passes =
			{
				"Lexer",
				"Preprocessor",
				"ParserJobGenerator",
				"Parser",
				"PostParser",
				"NamespaceBuilder",
				"PostNamespaceBuilder",
				"SimpleNameResolver",
				"TypeInferer"
			}
			for _, passName in ipairs (passes) do
				if compilationUnit:GetPassDuration (passName) > 0.3 then
					compilerStdOut:WriteLine (passName .. " ran in " .. tostring (math.floor ((compilationUnit:GetPassDuration (passName)) * 100000 + 0.5) * 0.01) .. "ms.")
				end
			end
			
			local AST = compilationUnit.AST
			
			compilationUnit:OutputMessages (
				function (message, messageType)
					if messageType == GCompute.MessageType.Error then
						compilerStdErr:WriteLine (message)
					else
						compilerStdOut:WriteLine (message)
					end
				end
			)
			-- compilerStdOut:WriteLine (compilationGroup:ComputeMemoryUsage ():ToString ())
			
			if success then
				compilerStdOut:WriteLine ("Abstract Syntax Tree (serialized):")
				compilerStdOut:WriteLine (AST:ToString ())
				
				compilerStdOut:WriteLine ("Namespace:")
				compilerStdOut:WriteLine (compilationGroup:GetRootNamespace ():ToString ())
				
				local process = GCompute.LocalProcessList:CreateProcess ()
				process:SetName (sourceFile:GetId ())
				process:SetOwnerId (GLib.GetLocalId ())
				process:AddModule (compilationGroup:GetModule ())
				
				stdOut:Chain (process:GetStdOut ())
				stdErr:Chain (process:GetStdErr ())
				
				process:Start ()
			end
		end
	)
end

function self:ShouldOutdent (codeEditor, location)
	return false
end

function self:TokenizeLine (line, tokenSink, inState, outState)
	local GLib_UTF8_Length             = GLib.UTF8.Length
	local GCompute_KeywordType_Unknown = GCompute.KeywordType.Unknown
	local GCompute_TokenType_Keyword   = GCompute.TokenType.Keyword
	local math_max   = math.max
	local string_sub = string.sub
	
	local language  = self.Language
	local tokenizer = self.Language:GetTokenizer ()
	local offset = 1
	
	local currentCharacter = 0
	if inState.Prefix then
		line = inState.Prefix .. line
		currentCharacter = -GLib_UTF8_Length (inState.Prefix)
	end
	
	local token, tokenLength, tokenType
	local lastToken = nil
	local characterCount
	
	while offset <= #line do
		token, tokenLength, tokenType = tokenizer:MatchSymbol (line, offset)
		lastToken = string_sub (line, offset, offset + tokenLength - 1)
		characterCount = GLib_UTF8_Length (lastToken)
		
		if language:GetKeywordType (token) ~= GCompute_KeywordType_Unknown then
			tokenType = GCompute_TokenType_Keyword
		end
		tokenSink:Token (math_max (0, currentCharacter), currentCharacter + characterCount, tokenType)
		
		offset = offset + tokenLength
		currentCharacter = currentCharacter + characterCount
	end
	
	outState.Prefix = nil
	
	if lastToken then
		local _, probedLength, probedTokenType = tokenizer:MatchSymbol (lastToken .. string.rep (string.char (255), 8), 1)
		if probedLength > tokenLength and tokenType == probedTokenType then
			outState.Prefix = GLib.UTF8.Sub (lastToken, 1, 8) .. " "
		end
	end
end