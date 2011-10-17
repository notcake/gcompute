local Parser = {}
Parser.__index = Parser
GCompute._Parser = Parser

local KeywordTypes = GCompute.KeywordTypes

function GCompute.Parser ()
	local Object = {}
	setmetatable (Object, Parser)
	Object:ctor ()
	return Object
end

function Parser:ctor ()
	self.CompilerContext = nil
	
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

function Parser:Accept (Token)
	if self.CurrentToken == Token then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.CompilerContext:PrintDebugMessage ("Accepted token (" .. self.LastAccepted .. ")")
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
		self.CompilerContext:PrintDebugMessage ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptTokens (Tokens)
	-- debug
	if #Tokens > 0 then
		self.CompilerContext:PrintDebugMessage ("Parser:AcceptTokens : Tokens should be a table of keys, not an array (" .. table.concat (Tokens, ", ") .. ").")
	end
	if Tokens [self.CurrentToken] then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.CompilerContext:PrintDebugMessage ("Accepted token (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptTypes (TokenTypes)
	if TokenTypes [self.CurrentTokenType] then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.CompilerContext:PrintDebugMessage ("Accepted type " .. tostring (GCompute.TokenTypes [self.LastAcceptedType]) .. " (" .. self.LastAccepted .. ")")
		return self.LastAccepted
	end
	return nil
end

function Parser:AcceptType (TokenType)
	if self.CurrentTokenType == TokenType then
		self.LastAccepted = self.CurrentToken
		self.LastAcceptedType = self.CurrentTokenType
		self:GetNextToken ()
		self.CompilerContext:PrintDebugMessage ("Accepted type " .. GCompute.TokenTypes [TokenType] .. " (" .. self.LastAccepted .. ")")
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
	while self.CompilerContext.Language:GetKeywordType (self.CurrentToken) == KeywordTypes.Modifier do
		self.CompilerContext:PrintDebugMessage ("Nommed modifier (" .. self.CurrentToken .. ")")
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
		CAdmin.Debug.PrintStackTrace ()
	end
	self.ParseTreeStack.Top:RemoveLast ()
end

function Parser:ExpectedItem (Item)
	local Current = self.TokenNode
	local CurrentToken = "<eof>"
	local Line = 0
	local Character = 0
	if Current then
		CurrentToken = Current.Value
		Line = Current.Line
		Character = Current.Character
	else
		Line = self.Tokens.Last.Line
		Character = self.Tokens.Last.Character
	end
	self.CompilerContext:PrintErrorMessage ("Expected <" .. Item .. ">, got \"" .. CurrentToken .. "\".", Line, Character)
end

function Parser:ExpectedToken (Token)
	local Current = self.TokenNode
	local CurrentToken = "<eof>"
	local Line = 0
	local Character = 0
	if Current then
		CurrentToken = Current.Value
		Line = Current.Line
		Character = Current.Character
	else
		Line = self.Tokens.Last.Line
		Character = self.Tokens.Last.Character
	end
	self.CompilerContext:PrintErrorMessage ("Expected \"" .. Token .. "\", got \"" .. CurrentToken .. "\".", Line, Character)
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

function Parser:List (SubParseFunction, Delimiter)
	Delimiter = Delimiter or ","
	local List = GCompute.Containers.Tree ("list")
	local Item = SubParseFunction (self)
	if not Item then
		return List
	end
	List:AddNode (Item)
	while self:Accept (Delimiter) do
		local Item = SubParseFunction (self)
		if not Item then
			return List
		end
		List:AddNode (Item)
	end
	return List
end

function Parser:Parse (Tokens)
	self.Tokens = Tokens
	self.TokenNode = Tokens.First
	self.CurrentToken = self.TokenNode.Value
	self.CurrentTokenType = self.TokenNode.TokenType

	self.ParseTree = GCompute.Containers.Tree ()
	self.ParseTree.Value = "root"
	self:PushParseNode (self.ParseTree)
	
	self:Root ();
	return self.ParseTree
end

function Parser:Peek ()
	if not self.TokenNode or
		not self.TokenNode.Next then
		return nil, nil
	end
	return self.TokenNode.Next.Value, self.TokenNode.Next.TokenType
end

function Parser:PeekType ()
	if not self.TokenNode or
		not self.TokenNode.Next then
		return nil
	end
	return self.TokenNode.Next.TokenType
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
	self.CompilerContext:PrintDebugMessage ("Position restored.")
	self.TokenNode = self.TokenStack:Pop ()
	self.CurrentToken = self.TokenNode.Value
	self.CurrentTokenType = self.TokenNode.TokenType
end

function Parser:SavePosition ()
	self.TokenStack:Push (self.TokenNode)
end

function Parser:SyntaxError (Error)
	local Current = self.TokenNode
	local Line = 0
	local Character = 0
	if Current then
		Line = Current.Line
		Character = Current.Character
	else
		Line = self.Tokens.Last.Line
		Character = self.Tokens.Last.Character
	end
	self.CompilerContext:PrintErrorMessage (Error, Line, Character)
end