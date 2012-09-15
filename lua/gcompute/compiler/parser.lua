local self = {}
GCompute.Parser = GCompute.MakeConstructor (self)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.Language = compilationUnit:GetLanguage ()
	self.DebugOutput = GCompute.NullOutputBuffer
	
	self.Tokens = nil
	self.LastAcceptedToken      = nil
	self.LastAcceptedTokenValue = nil
	self.LastAcceptedTokenType  = nil
	self.CurrentToken           = nil
	self.CurrentTokenValue      = nil
	self.CurrentTokenType       = nil
	
	self.TokenStack = GCompute.Containers.Stack ()
	self.Modifiers = {}
end

function self:Accept (token)
	if self.CurrentTokenValue == token and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self:AdvanceToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAcceptedTokenValue .. ")")
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptAndSave (token)
	if self.CurrentTokenValue == token and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self:SavePosition ()
		self:AdvanceToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAcceptedTokenValue .. ")")
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptAST ()
	if self.CurrentToken.AST then
		self.LastAcceptedToken      = self.CurrentToken
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self.CurrentToken           = self.CurrentToken.BlockEnd.Next
		self.CurrentTokenValue      = self.CurrentToken.Value
		self.CurrentTokenType       = self.CurrentToken.TokenType
		
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptNewlines ()
	while self:AcceptType (GCompute.TokenType.Newline) do end
end

function self:AcceptTokens (tokens)
	-- debug
	if #tokens > 0 then
		self.DebugOutput:WriteLine ("Parser:AcceptTokens : Tokens should be a table of keys, not an array (" .. table.concat (tokens, ", ") .. ").")
	end
	if tokens [self.CurrentTokenValue] and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self:AdvanceToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAcceptedTokenValue .. ")")
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptTypes (tokenTypes)
	if tokenTypes [self.CurrentTokenType] then
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self:AdvanceToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. tostring (GCompute.TokenType [self.LastAcceptedTokenType]) .. " (" .. GCompute.String.Escape (self.LastAcceptedTokenValue) .. ")")
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptType (tokenType)
	if self.CurrentTokenType == tokenType then
		self.LastAcceptedTokenValue = self.CurrentTokenValue
		self.LastAcceptedTokenType  = self.CurrentTokenType
		self:AdvanceToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. GCompute.TokenType [tokenType] .. " (" .. GCompute.String.Escape (self.LastAcceptedTokenValue) .. ")")
		return self.LastAcceptedTokenValue
	end
	return nil
end

function self:AcceptWhitespace ()
	while self:AcceptType (GCompute.TokenType.Whitespace) do end
end

function self:AcceptWhitespaceAndNewlines ()
	while self:AcceptType (GCompute.TokenType.Whitespace) or self:AcceptType (GCompute.TokenType.Newline) do end
end

function self:AddParseItem (Value)
	return self.ParseTreeStack.Top:Add (Value)
end

function self:AddParseNode (TreeNode)
	return self.ParseTreeStack.Top:AddNode (TreeNode)
end

function self:AddModifier (Modifier)
	self.Modifiers [#self.Modifiers + 1] = Modifier
end

function self:AdvanceToken ()
	if not self.CurrentToken then return nil, nil end
	
	self.LastAcceptedToken = self.CurrentToken
	self.CurrentToken = self.CurrentToken.Next
	if not self.CurrentToken then
		self.CurrentTokenValue = nil
		self.CurrentTokenType  = nil
		return nil, nil
	end
	self.CurrentTokenValue = self.CurrentToken.Value
	self.CurrentTokenType  = self.CurrentToken.TokenType
	return self.CurrentTokenValue, self.CurrentTokenType
end

function self:ChompModifiers ()
	while self.CompilationUnit.Language:GetKeywordType (self.CurrentTokenValue) == GCompute.KeywordType.Modifier do
		self.DebugOutput:WriteLine ("Nommed modifier (" .. self.CurrentTokenValue .. ")")
		self.Modifiers [#self.Modifiers + 1] = self.CurrentTokenValue
		self:AdvanceToken ()
	end
end

function self:ClearModifiers ()
	if #self.Modifiers > 0 then
		self.Modifiers = {}
	end
end

function self:CommitPosition ()
	self.TokenStack:Pop ()
end

function self:DiscardParseItem ()
	self.ParseTreeStack:Pop ()
	if not self.ParseTreeStack.Top then
		GCompute.PrintStackTrace ()
	end
	self.ParseTreeStack.Top:RemoveLast ()
end

function self:ExpectedItem (item)
	local currentToken      = self.CurrentToken
	local currentTokenValue = "<eof>"
	local line      = 0
	local character = 0
	if currentToken then
		currentTokenValue = "\"" .. GCompute.String.Escape (currentToken.Value) .. "\""
		line      = currentToken.Line
		character = currentToken.Character
	else
		line      = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error ("Expected <" .. item .. ">, got " .. currentTokenValue .. ".", line, character)
	else
		GCompute.Error ("Expected <" .. item .. ">, got " .. currentTokenValue .. " at line " .. tostring (line) .. ", char " .. tostring (character) .. ".")
	end
end

function self:ExpectedToken (token)
	local currentToken      = self.CurrentToken
	local currentTokenValue = "<eof>"
	local line      = 0
	local character = 0
	if currentToken then
		currentTokenValue = "\"" .. GCompute.String.Escape (currentToken.Value) .. "\""
		line      = currentToken.Line
		character = currentToken.Character
	else
		line      = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error ("Expected \"" .. token .. "\", got " .. currentTokenValue .. ".", line, character)
	else
		GCompute.Error ("Expected \"" .. token .. "\", got " .. currentTokenValue .. " at line " .. tostring (line) .. ", char " .. tostring (character) .. ".")
	end
end

function self:GetLastToken ()
	return self.LastAcceptedToken
end

function self:Initialize (tokens, startToken, endToken)
	self.Tokens = tokens
	self.CurrentToken      = startToken or tokens.First
	self.CurrentTokenValue = self.CurrentToken.Value
	self.CurrentTokenType  = self.CurrentToken.TokenType
end

function self:IsTokenAvailable ()
	return self.CurrentTokenValue ~= nil
end

function self:List (subParseFunction, delimiter)
	delimiter = delimiter or ","
	local list = {}
	local item = subParseFunction (self)
	if not item then
		return list
	end
	list [#list + 1] = item
	while self:Accept (delimiter) do
		local item = subParseFunction (self)
		if not item then return list end
		list [#list + 1] = item
	end
	return list
end

function self:Process (tokens, startToken, endToken)
	self:Initialize (tokens, startToken, endToken)
	
	self.CompilationUnit:Debug ("Parsing from line " .. startToken.Line .. ", char " .. startToken.Character .. " to line " .. endToken.Line .. ", char " .. endToken.Character .. ".")
	
	return self:Root ()
end

function self:Peek ()
	return self.CurrentTokenValue, self.CurrentTokenType
end

function self:PeekType ()
	return self.CurrentTokenType
end

function self:RecurseLeft (subParseFunction, tokens)
	local leftExpression = subParseFunction (self)
	if not leftExpression then return nil end
	local gotExpression = true
	
	while gotExpression do
		gotExpression = false
		-- The looping of this bit will ensure (I think) that left associativity is preserved.
		self:AcceptWhitespaceAndNewlines ()
		if tokens [self.CurrentTokenValue] and self.CurrentTokenType ~= GCompute.TokenType.String then
			gotExpression = true
			local nextLeftExpression = GCompute.AST.BinaryOperator ()
			nextLeftExpression:SetOperator (self.CurrentTokenValue)
			self:AdvanceToken ()
			self:AcceptWhitespaceAndNewlines ()
			nextLeftExpression:SetLeftExpression (leftExpression)
			nextLeftExpression:SetRightExpression (subParseFunction (self))
			leftExpression = nextLeftExpression
		end
	end
	
	return leftExpression
end

function self:RecurseRight (subParseFunction, tokens)
	local leftExpression = subParseFunction (self)
	if not leftExpression then return nil end
	
	self:AcceptWhitespaceAndNewlines ()
	if tokens [self.CurrentTokenValue] and self.CurrentTokenType ~= GCompute.TokenType.String then
		local binaryOperatorExpression = GCompute.AST.BinaryOperator ()
		binaryOperatorExpression:SetOperator (self.CurrentTokenValue)
		self:AdvanceToken ()
		self:AcceptWhitespaceAndNewlines ()
		binaryOperatorExpression:SetLeftExpression (leftExpression)
		local rightExpression = self:RecurseRight (subParseFunction, tokens)
		if not rightExpression then return nil end
		binaryOperatorExpression:SetRightExpression (rightExpression)
		return binaryOperatorExpression
	end
	
	return leftExpression
end

function self:RecurseRightUnary (subParseFunction, tokens, subItemName)
	if tokens [self.CurrentTokenValue] and self.CurrentTokenType ~= GCompute.TokenType.String then
		local unaryExpression = GCompute.AST.LeftUnaryOperator ()
		unaryExpression:SetOperator (self.CurrentTokenValue)
		self:AdvanceToken ()
		unaryExpression:SetRightExpression (self:RecurseRightUnary (subParseFunction, tokens))
		if not unaryExpression:GetRightExpression () then
			self:ExpectedItem (subItemName)
		end
		return unaryExpression
	end
	return subParseFunction (self)
end

function self:RestorePosition ()
	self.DebugOutput:WriteLine ("Position restored.")
	self.CurrentToken = self.TokenStack:Pop ()
	if self.CurrentToken then
		self.CurrentTokenValue = self.CurrentToken.Value
		self.CurrentTokenType  = self.CurrentToken.TokenType
	else
		self.CurrentTokenValue = nil
		self.CurrentTokenType  = nil
	end
end

function self:SavePosition ()
	self.TokenStack:Push (self.CurrentToken)
end

function self:SyntaxError (syntaxError)
	local currentToken = self.CurrentToken
	local line      = 0
	local character = 0
	if currentToken then
		line      = currentToken.Line
		character = currentToken.Character
	else
		line      = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error (syntaxError, line, character)
	else
		GCompute.Error (syntaxError)
	end
end