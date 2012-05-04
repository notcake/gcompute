local Parser = {}
GCompute.Parser = GCompute.MakeConstructor (Parser)

local KeywordTypes = GCompute.KeywordTypes

function Parser:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.Language = compilationUnit:GetLanguage ()
	self.DebugOutput = GCompute.NullOutputBuffer
	
	self.LastAccepted = nil
	self.LastAcceptedType = nil
	self.Tokens = nil
	self.CurrentToken = nil
	self.CurrentTokenType = nil
	self.TokenNode = nil
	
	self.ParseTree = nil
	self.ParseTreeStack = GCompute.Containers.Stack ()
	self.TokenStack = GCompute.Containers.Stack ()
	self.Modifiers = {}
end

function Parser:Accept (token)
	if self.CurrentToken == token then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptAndSave (Token)
	if self.CurrentToken == Token then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:SavePosition ()
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptTokens (Tokens)
	-- debug
	if #Tokens > 0 then
		self.DebugOutput:WriteLine ("Parser:AcceptTokens : Tokens should be a table of keys, not an array (" .. table.concat (Tokens, ", ") .. ").")
	end
	if Tokens [self.CurrentToken] then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptTypes (TokenTypes)
	if TokenTypes [self.CurrentTokenType] then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. tostring (GCompute.TokenType [self.LastAcceptedType]) .. " (" .. GCompute.String.Escape (self.LastAccepted) .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptType (TokenType)
	if self.CurrentTokenType == TokenType then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.DebugOutput:WriteLine ("Accepted type " .. GCompute.TokenType [TokenType] .. " (" .. GCompute.String.Escape (self.LastAccepted) .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AddParseItem (Value)
	return self.ParseTreeStack.Top:Add (Value)
end

function Parser:AddParseNode (TreeNode)
	return self.ParseTreeStack.Top:AddNode (TreeNode)
end

function Parser:AddModifier (Modifier)
	self.Modifiers [#self.Modifiers + 1] = Modifier
end

function Parser:ChompModifiers ()
	while self.CompilationUnit.Language:GetKeywordType (self.CurrentToken) == KeywordTypes.Modifier do
		self.DebugOutput:WriteLine ("Nommed modifier (" .. self.CurrentToken .. ")")
		self.Modifiers [#self.Modifiers + 1] = self.CurrentToken
		self:GetNextToken ()
	end
end

function Parser:ClearModifiers ()
	if #self.Modifiers > 0 then
		self.Modifiers = {}
	end
end

function Parser:CommitPosition ()
	self.TokenStack:Pop ()
end

function Parser:DiscardParseItem ()
	self.ParseTreeStack:Pop ()
	if not self.ParseTreeStack.Top then
		GCompute.PrintStackTrace ()
	end
	self.ParseTreeStack.Top:RemoveLast ()
end

function Parser:ExpectedItem (item)
	local current = self.TokenNode
	local currentToken = "<eof>"
	local line = 0
	local character = 0
	if current then
		currentToken = "\"" .. current.Value .. "\""
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

function Parser:ExpectedToken (token)
	local current = self.TokenNode
	local currentToken = "<eof>"
	local line = 0
	local character = 0
	if current then
		currentToken = "\"" .. current.Value .. "\""
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

function Parser:GetNextToken ()
	if not self.TokenNode then
		return nil, nil
	end
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

function Parser:IsTokenAvailable ()
	return self.CurrentToken ~= nil
end

function Parser:List (subParseFunction, delimiter)
	delimiter = delimiter or ","
	local list = GCompute.Containers.Tree ("list")
	local item = subParseFunction (self)
	if not item then
		return list
	end
	list:AddNode (item)
	while self:Accept (delimiter) do
		local item = subParseFunction (self)
		if not item then
			return list
		end
		list:AddNode (item)
	end
	return list
end

function Parser:Parse (Tokens)
	self.Tokens = Tokens
	self.TokenNode = Tokens.First
	self.CurrentToken = self.TokenNode.Value
	self.CurrentTokenType = self.TokenNode.TokenType

	self.ParseTree = GCompute.Containers.Tree ()
	self.ParseTree.Value = "root"
	self:PushParseNode (self.ParseTree)
	
	self:Root ()
	return self.ParseTree
end

function Parser:Peek ()
	return self.CurrentToken, self.CurrentTokenType
end

function Parser:PeekType ()
	return self.CurrentTokenType
end

function Parser:PopParseItem ()
	self.ParseTreeStack:Pop ()
end

function Parser:PushParseItem (Value)
	local Node = self.ParseTreeStack.Top:Add (Value)
	self.ParseTreeStack:Push (Node)
	return Node
end

-- Pushes a node without parenting it
function Parser:PushParseNode (TreeNode)
	self.ParseTreeStack:Push (TreeNode)
end

function Parser:RecurseLeft (SubParseFunction, Tokens)
	local LeftExpression = SubParseFunction (self)
	if not LeftExpression then
		return nil
	end
	local GotExpression = true
	
	while GotExpression do
		GotExpression = false
		-- The looping of this bit will ensure (I think) that left associativity is preserved.
		if Tokens [self.CurrentToken] then
			GotExpression = true
			local NextLeftExpression = GCompute.Containers.Tree (self.CurrentToken)
			self:GetNextToken ()
			NextLeftExpression:AddNode (LeftExpression)
			NextLeftExpression:AddNode (SubParseFunction (self))
			LeftExpression = NextLeftExpression
		end
	end
	
	return LeftExpression
end

function Parser:RecurseRight (SubParseFunction, Tokens)
	local LeftExpression = SubParseFunction (self)
	if not LeftExpression then
		return nil
	end
	if Tokens [self.CurrentToken] then
		local Expression = GCompute.Containers.Tree (self.CurrentToken)
		self:GetNextToken ()
		Expression:AddNode (LeftExpression)
		local RightExpression = self:RecurseRight (SubParseFunction, Tokens)
		if not RightExpression then
			return nil
		end
		Expression:AddNode (RightExpression)
		return Expression
	end
	
	return LeftExpression
end

function Parser:RecurseRightUnary (SubParseFunction, Tokens)
	if Tokens [self.CurrentToken] then
		local Expression = GCompute.Containers.Tree (self.CurrentToken)
		self:GetNextToken ()
		Expression:AddNode (self:RecurseRightUnary (SubParseFunction, Tokens))
		return Expression
	end
	return SubParseFunction (self)
end

function Parser:RestorePosition ()
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

function Parser:SavePosition ()
	self.TokenStack:Push (self.TokenNode)
end

function Parser:SyntaxError (syntaxError)
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