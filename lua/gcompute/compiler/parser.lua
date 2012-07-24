local self = {}
GCompute.Parser = GCompute.MakeConstructor (self)

local KeywordTypes = GCompute.KeywordTypes

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.Language = compilationUnit:GetLanguage ()
	self.DebugOutput = GCompute.NullOutputBuffer
	
	self.LastAccepted = nil
	self.LastAcceptedType = nil
	self.LastToken = nil
	self.Tokens = nil
	self.CurrentToken = nil
	self.CurrentTokenType = nil
	self.TokenNode = nil
	
	self.TokenStack = GCompute.Containers.Stack ()
	self.Modifiers = {}
end

function self:Accept (token)
	if self.CurrentToken == token and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function self:AcceptAndSave (token)
	if self.CurrentToken == token and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:SavePosition ()
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
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
	if tokens [self.CurrentToken] and self.CurrentTokenType ~= GCompute.TokenType.String then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function self:AcceptTypes (tokenTypes)
	if tokenTypes [self.CurrentTokenType] then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. tostring (GCompute.TokenType [self.LastAcceptedType]) .. " (" .. GCompute.String.Escape (self.LastAccepted) .. ")")
		return self.LastAccepted
	end
	return nil
end

function self:AcceptType (tokenType)
	if self.CurrentTokenType == tokenType then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. GCompute.TokenType [tokenType] .. " (" .. GCompute.String.Escape (self.LastAccepted) .. ")")
		return self.LastAccepted
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

function self:ChompModifiers ()
	while self.CompilationUnit.Language:GetKeywordType (self.CurrentToken) == KeywordTypes.Modifier do
		self.DebugOutput:WriteLine ("Nommed modifier (" .. self.CurrentToken .. ")")
		self.Modifiers [#self.Modifiers + 1] = self.CurrentToken
		self:GetNextToken ()
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
	local current = self.TokenNode
	local currentToken = "<eof>"
	local line = 0
	local character = 0
	if current then
		currentToken = "\"" .. GCompute.String.Escape (current.Value) .. "\""
		line = current.Line
		character = current.Character
	else
		line = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error ("Expected <" .. item .. ">, got " .. currentToken .. ".", line, character)
	else
		GCompute.Error ("Expected <" .. item .. ">, got " .. currentToken .. " at line " .. tostring (line) .. ", char " .. tostring (character) .. ".")
	end
end

function self:ExpectedToken (token)
	local current = self.TokenNode
	local currentToken = "<eof>"
	local line = 0
	local character = 0
	if current then
		currentToken = "\"" .. GCompute.String.Escape (current.Value) .. "\""
		line = current.Line
		character = current.Character
	else
		line = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error ("Expected \"" .. token .. "\", got " .. currentToken .. ".", line, character)
	else
		GCompute.Error ("Expected \"" .. token .. "\", got " .. currentToken .. " at line " .. tostring (line) .. ", char " .. tostring (character) .. ".")
	end
end

function self:GetLastToken ()
	return self.LastToken
end

function self:GetNextToken ()
	if not self.TokenNode then return nil, nil end
	
	self.LastToken = self.TokenNode
	self.TokenNode = self.TokenNode.Next
	if not self.TokenNode then
		self.CurrentToken = nil
		self.CurrentTokenType = nil
		return nil, nil
	end
	self.CurrentToken = self.TokenNode.Value
	self.CurrentTokenType = self.TokenNode.TokenType
	return self.CurrentToken, self.CurrentTokenType
end

function self:Initialize (tokens, startToken, endToken)
	self.Tokens = tokens
	self.TokenNode = startToken or tokens.First
	self.CurrentToken = self.TokenNode.Value
	self.CurrentTokenType = self.TokenNode.TokenType
end

function self:IsTokenAvailable ()
	return self.CurrentToken ~= nil
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
	return self.CurrentToken, self.CurrentTokenType
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
		if tokens [self.CurrentToken] and self.CurrentTokenType ~= GCompute.TokenType.String then
			gotExpression = true
			local nextLeftExpression = GCompute.AST.BinaryOperator ()
			nextLeftExpression:SetOperator (self.CurrentToken)
			self:GetNextToken ()
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
	if tokens [self.CurrentToken] and self.CurrentTokenType ~= GCompute.TokenType.String then
		local binaryOperatorExpression = GCompute.AST.BinaryOperator ()
		binaryOperatorExpression:SetOperator (self.CurrentToken)
		self:GetNextToken ()
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
	if tokens [self.CurrentToken] and self.CurrentTokenType ~= GCompute.TokenType.String then
		local unaryExpression = GCompute.AST.LeftUnaryOperator ()
		unaryExpression:SetOperator (self.CurrentToken)
		self:GetNextToken ()
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
	self.TokenNode = self.TokenStack:Pop ()
	if self.TokenNode then
		self.CurrentToken = self.TokenNode.Value
		self.CurrentTokenType = self.TokenNode.TokenType
	else
		self.CurrentToken = nil
		self.CurrentTokenType = nil
	end
end

function self:SavePosition ()
	self.TokenStack:Push (self.TokenNode)
end

function self:SyntaxError (syntaxError)
	local current = self.TokenNode
	local line = 0
	local character = 0
	if current then
		line = current.Line
		character = current.Character
	else
		line = self.Tokens.Last.Line
		character = self.Tokens.Last.Character
	end
	if self.CompilationUnit then
		self.CompilationUnit:Error (syntaxError, line, character)
	else
		GCompute.Error (syntaxError)
	end
end