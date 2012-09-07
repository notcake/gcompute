local Parser = Parser
--[[
	Parsing structure
	Based off expression 2

	Root
	 1 : q1

	seQuencing
	 1 : ""
	 2 : "s1 q1", "s1, q2"
	
	Statement
	 1 : ;														[Null statement]
	 2 : if (e1) s1 i1
	 3 : while (e1) s1
	 4 : do s1 while (e1)
	 5 : for (s11|e1, ... ; e1; e1, ...) s1
	 6 : foreach ([type] var in e1) s1
	 7 : break, continue, return e1
	 8 : [mod ...] (namespace|class|struct|enum) s8 [var [= e1] [, ...] ]
	 9 : { q1 }
	10 : [mod ...] t1 var (t1 id, ...) [{ q1 }] [;]				[Function declaration]
	11 : [mod ...] [t1] var [= e1] [, ...] [;]					[Variable declaration]
	12 : e1 [;]
	
	Type
	 1 : t2 -> t1												[Right associative]
	 2 : t1.t2
	 3 : (t1)
	 4 : t4[(num)]
	 5 : t6<t1, ...>
	 6 : type

	If
	 1 : else if (e1) s1 i1
	 2 : else s1
	 3 : [nothing]

	Expression
	 1 : var = e1, var += e1, var -= e1, var *= e1, var /= e1	[Right associative]
	 2 : e3 ? e1 : e1, e3 ?: e1
	 3 : e3 | e4
	 4 : e4 & e5
	 5 : e5 == e6, e5 != e6
	 6 : e6 < e7, e6 > e7, e6 <= e7, e6 >= e7
	 7 : e7 + e8
	 7a: e7 - e8
	 8 : e8 * e9
	 9 : e9 / e10, e9 % e10
	10 : e11 ^ e10												[Right associative]
	12 : (type) e11												[Fix function call and type cast ambiguity in the semantic analysis stage - "(identifier) (param)"]
	11 : +e12, -e12, !e12
	12 : e12++, e12--
	13 : new e15 ([e1, ...])
	14 : e14 ([e1, ...]), e14 [var,type]
	15 : e15.e16
	16 : (e1)
	17 : t1 (t1 [var], ...) { q1 }								[Anonymous function]
	18 : var
	19 : string, num
]]

-- Root
function Parser:Root ()
	local Token = self.TokenNode
	--[[
	while Token do
		Msg ("Token: " .. tostring (Token.Value) .. " | " .. tostring (GCompute.TokenType [Token.TokenType]) .. "\n")
		Token = Token.Next
	end
	]]
	self:Sequence ()
	return self.ParseTreeStack.Top
end

-- Sequence
function Parser:Sequence ()
	while self:Peek () and
			self:Peek () ~= "}" do
		self:Statement ()
	end
end

-- Statement
function Parser:Statement ()
	self.DebugOutput:WriteLine ("Statement:")
	self.DebugOutput:IncreaseIndent ()
	
	self:SavePosition ()
	self:AcceptType (GCompute.TokenType.Newline)
	if self:StatementNull () or
		self:StatementIf () or
		self:StatementWhile () or
		self:StatementDoWhile () or
		self:StatementFor () or
		self:StatementControl () or
		self:StatementTypeDeclaration () or
		self:StatementBlock () or
		self:StatementFunctionDeclaration () or 
		self:StatementVariableDeclaration () or 
		self:StatementExpression () then
		self.DebugOutput:DecreaseIndent ()
		self:Accept (";")
		self:CommitPosition ()
		return true
	end
	self:RestorePosition ()
	self:GetNextToken ()
	self.DebugOutput:DecreaseIndent ()
	return false
end

function Parser:StatementNull ()
	return self:Accept (";")
end

function Parser:StatementIf ()
	if not self:Accept ("if") then
		return false
	end
	self:PushParseItem ("if")
	self:Accept ("(")
	local Condition = self:Expression ()
	if not Condition then
		self:ExpectedItem ("expression")
	end
	self:AddParseItem ("cond"):AddNode (Condition)
	self:Accept (")")
	self:Statement ()
	if not self:Accept ("else") then
		self:PopParseItem ()
		return true
	end
	self:PushParseItem ("else")
	local Statement = self:Statement ()
	self:PopParseItem ()
	self:PopParseItem ()
	return Statement
end

function Parser:StatementWhile ()
	if not self:AcceptAndSave ("while") then
		return false
	end
	if not self:Accept ("(") then
		self:RestorePosition ()
		return false
	end
	local Expression = self:Expression ()
	if not Expression or not self:Accept (")") then
		self:RestorePosition ()
		return false
	end
	self:PushParseItem ("while")
	self:AddParseItem ("cond"):AddNode (Expression)
	self:PushParseItem ("loop")
	if not self:Statement () then
		self:PopParseItem ()
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	self:PopParseItem ()
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementDoWhile ()
	if not self:AcceptAndSave ("do") then
		return false
	end
	self:PushParseItem ("do")
	self:PushParseItem ("loop")
	if not self:Statement () then
		self:PopParseItem ()
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	self:PopParseItem ()
	if not self:Accept ("while") or not self:Accept ("(") then
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	local Expression = self:Expression ()
	if not Expression or not self:Accept (")") then
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	self:AddParseItem ("cond"):AddNode (Expression)
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementFor ()
	if not self:AcceptAndSave ("for") then
		return false
	end
	if not self:Accept ("(") then
		self:RestorePosition ()
		return false
	end
	self:PushParseItem ("for")
	self:PushParseItem ("init")
	while not self:Accept (";") do
		if not self:StatementVariableDeclaration () and not self:StatementExpression () then
			self:PopParseItem ()
			self:DiscardParseItem ()
			self:RestorePosition ()
			return false
		end
		self:Accept (",")
	end
	self:PopParseItem ()
	if self:Accept (";") then
		self:AddParseItem ("cond")
	else
		self:PushParseItem ("cond")
		self:StatementExpression ()
		self:PopParseItem ()
		self:Accept (";")
	end
	self:PushParseItem ("post")
	while not self:Accept (")") do
		local Expression = self:Expression ()
		if not Expression then
			self:PopParseItem ()
			self:DiscardParseItem ()
			self:RestorePosition ()
			return false
		end
		self:AddParseNode (Expression)
		self:Accept (",")
	end
	self:PopParseItem ()
	self:PushParseItem ("loop")
	if not self:Statement () then
		self:PopParseItem ()
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	self:PopParseItem ()
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementControl ()
	if self:AcceptTokens ({["break"] = true, ["continue"] = true}) then
		self:AddParseItem (self.LastAccepted)
		return true
	end
	if self:Accept ("return") then
		local Value = nil
		if self.CurrentToken == ";" then
			self:AddParseItem (self.LastAccepted)
		else
			self:AddParseItem (self.LastAccepted):AddNode (self:Expression ())
		end
		return true
	end
	return false
end

function Parser:StatementTypeDeclaration ()
	self.DebugOutput:WriteLine ("Trying type declaration...")
	self:SavePosition ()
	self:ChompModifiers ()
	if self.Language:GetKeywordType (self.CurrentToken) ~= GCompute.KeywordType.DataType then
		self:ClearModifiers ()
		self:RestorePosition ()
		return false
	end
	local DataType = self.CurrentToken
	local Type = self:Type ()
	if not Type then
		self:ClearModifiers ()
		self:RestorePosition ()
		return false
	end
	self:PushParseItem (DataType)
	self:AddParseItem ("mod"):AddRange (self.Modifiers)
	self:ClearModifiers ()
	
	local TypeName = self:AcceptType (GCompute.TokenType.Identifier)
	if TypeName then
		self:AddParseItem ("name"):Add (TypeName)
	end
	if DataType == "enum" then
		self:PushParseItem ("values")
		self:Accept ("{")
		repeat
			local Identifier = self:AcceptType (GCompute.TokenTypes.Identifier)
			if self:Accept ("=") then
				local Value = self:AddParseItem ("val")
				Value:Add (Identifier)
				Value:AddNode (self:Expression ())
			else
				self:AddParseItem ("val"):Add (Identifier)
			end
		until not self:Accept (",")
		self:Accept ("}")
		self:PopParseItem ()
	elseif not self:StatementBlock () then
		self:ClearModifiers ()
		self:PopParseItem ()
		self:RestorePosition ()
		return false
	end
	
	local ExpectingIdentifier = false
	while self:AcceptType (GCompute.TokenType.Identifier) do
		ExpectingIdentifier = false
		self:PushParseItem ("var")
		self:AddParseItem (self.LastAccepted)
		if self:Accept ("=") then
			self.DebugOutput:IncreaseIndent ()
			local Expression = self:Expression ()
			self.DebugOutput:DecreaseIndent ()
			if not Expression then
				self:PopParseItem ()
				break
			end
			self:AddParseNode (Expression)
		end
		self:PopParseItem ()
		if self:Accept (",") then
			ExpectingIdentifier = true
		end
	end
	if ExpectingIdentifier then
		self.CompilerContext:PrintWarningMessage ("Expected identifier after \",\".")
	end
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementBlock ()
	if not self:Accept ("{") then
		return false
	end
	self.DebugOutput:WriteLine ("{")
	self.DebugOutput:IncreaseIndent ()
	self:PushParseItem ("scope")
	self:Sequence ()
	self:PopParseItem ()
	self:Accept ("}")
	self.DebugOutput:DecreaseIndent ()
	self.DebugOutput:WriteLine ("}")
	return true
end

function Parser:StatementFunctionDeclaration ()
	-- Example: public int f (int x) {}
	self:SavePosition ()
	self:ChompModifiers ()
	self:PushParseItem ("fdecl")
	self:AddParseItem ("mod"):AddRange (self.Modifiers)
	self:ClearModifiers ()
	
	-- After the modifiers, it's type
	local Type = self:Type ()
	if not Type then
		self:RestorePosition ()
		self:DiscardParseItem ()
		return false
	end
	
	-- Then the identifier
	local Identifier = self:AcceptType (GCompute.TokenType.Identifier)
	if not Identifier then
		self:RestorePosition ()
		self:DiscardParseItem ()
		return false
	end
	
	self:AddParseItem ("rtype"):AddNode (Type)
	self:AddParseItem (Identifier)
	
	if not self:Accept ("(") then
		self:RestorePosition ()
		self:DiscardParseItem ()
		return false
	end
	self:PushParseItem ("args")
	repeat
		local Type = self:Type ()
		if not Type then
			break
		end
		local Identifier = self:AcceptType (GCompute.TokenType.Identifier)
		local Item = self:AddParseItem ("arg")
		Item:AddNode (Type)
		if Identifier then
			Item:Add (Identifier)
		end
	until not self:Accept (",")
	self:PopParseItem ()
	if not self:Accept (")") then
		self:RestorePosition ()
		self:DiscardParseItem ()
		return false
	end
	self:AcceptType (GCompute.TokenType.Newline)
	local Block = self:StatementBlock ()
	if not Block then
		self:Accept (";")
	end
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementVariableDeclaration ()
	-- Example: auto x = f (x), b, c = 0;
	-- Ambiguity: x = e1;
	self:SavePosition ()
	self:ChompModifiers ()
	self:PushParseItem ("decl")
	self:AddParseItem ("mod"):AddRange (self.Modifiers)
	self:ClearModifiers ()
	
	-- After the modifiers, it's type identifier_list
	local Type = self:Type ()
	if not Type then
		self:DiscardParseItem ()
		self:RestorePosition ()
		return false
	end
	self:AddParseItem ("type"):AddNode (Type)
	
	repeat
		Identifier = self:AcceptType (GCompute.TokenType.Identifier)
		if not Identifier then
			self:DiscardParseItem ()
			self:RestorePosition ()
			return false
		end
		
		-- after that, it's assignment or end of statement
		-- assignment
		local Expression = nil
		if self:Accept ("=") then
			self.DebugOutput:IncreaseIndent ()
			Expression = self:Expression ()
			self.DebugOutput:DecreaseIndent ()
			if not Expression then
				self:PopParseItem ()
				self:DiscardParseItem ()
				self:RestorePosition ()
				return false
			end
		end
		
		-- Commit node
		local Node = self:AddParseItem ("var")
		Node:Add (Identifier)
		if Expression then
			Node:AddNode (Expression)
		end
	until not self:Accept (",")
	
	self:PopParseItem ()
	
	self:CommitPosition ()
	return true
end

function Parser:StatementExpression ()
	self:SavePosition ()
	local Expression = self:Expression ()
	if not Expression then
		self:RestorePosition ()
		return false
	end
	if self:IsTokenAvailable () and
		not self:AcceptType (GCompute.TokenType.Newline) and
		self.CurrentToken ~= ";" and
		self.CurrentToken ~= "}" then
		self:RestorePosition ()
		return false
	end
	self:CommitPosition ()
	self:AddParseItem ("expr"):AddNode (Expression)
	return true
end

-- Expression, may recurse left.
function Parser:Expression ()
	local Expression = self:ExpressionAssignment ()
	if Expression then
		return Expression
	end
	self.DebugOutput:WriteLine ("Failed to parse expression.")
	return nil
end

-- Right associative
function Parser:ExpressionAssignment ()
	return self:RecurseRight (self.ExpressionTernary, {["="] = true, ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true})
end

function Parser:ExpressionTernary ()
	local Left = self:ExpressionBooleanOr ()
	
	if self:Accept ("?") then
		local TrueExpression = self:Expression ()
		
		if not self:Accept (":") then
			self.DebugOutput:WriteLine ("Failed to find \":\" of ternary operator.")
			return Left
		end
		local FalseExpression = self:Expression ()
		local Expression = GCompute.Containers.Tree ("?:")
		Expression:AddNode (Left)
		Expression:AddNode (TrueExpression)
		Expression:AddNode (FalseExpression)
		return Expression
	end
	
	return Left
end

function Parser:ExpressionBooleanOr ()
	return self:RecurseLeft (self.ExpressionBooleanAnd, {["||"] = true})
end

function Parser:ExpressionBooleanAnd ()
	return self:RecurseLeft (self.ExpressionEquality, {["&&"] = true})
end

function Parser:ExpressionEquality ()
	return self:RecurseLeft (self.ExpressionComparison, {["=="] = true, ["!="] = true})
end

function Parser:ExpressionComparison ()
	return self:RecurseLeft (self.ExpressionAddition, {["<"] = true, [">"] = true, ["<="] = true, [">="] = true})
end

function Parser:ExpressionAddition ()
	return self:RecurseLeft (self.ExpressionSubtraction, {["+"] = true})
end

function Parser:ExpressionSubtraction ()
	return self:RecurseLeft (self.ExpressionMultiplication, {["-"] = true})
end

function Parser:ExpressionMultiplication ()
	return self:RecurseLeft (self.ExpressionDivision, {["*"] = true})
end

function Parser:ExpressionDivision ()
	return self:RecurseLeft (self.ExpressionExponentiation, {["/"] = true, ["%"] = true})
end

function Parser:ExpressionExponentiation ()
	return self:RecurseRight (self.ExpressionTypeCast, {["^"] = true})
end

function Parser:ExpressionTypeCast ()
	if not self:AcceptAndSave ("(") then
		return self:ExpressionUnary ()
	end
	self.DebugOutput:WriteLine ("Matching type cast:")
	self.DebugOutput:IncreaseIndent ()
	local Expression = GCompute.Containers.Tree ("cast")
	local Type = self:Type ()
	if not Type then
		self:RestorePosition ()
		self.DebugOutput:DecreaseIndent ()
		return self:ExpressionUnary ()
	end
	Expression:AddNode (Type)
	if not self:Accept (")") then
		self:RestorePosition ()
		self.DebugOutput:DecreaseIndent ()
		return self:ExpressionUnary ()
	end
	
	local RightExpression = self:ExpressionTypeCast ()
	if not RightExpression then
		self.DebugOutput:WriteLine ("Type cast invalid: No right expression.")
		self.DebugOutput:DecreaseIndent ()
		self:RestorePosition ()
		return self:ExpressionUnary ()
	end
	-- If the right expression is an argument list with 0 or > 1 arguments, then it should be rejected.
	-- Otherwise if we find that the contents are indeed not a type, fix it in the semantic analysis stage.
	Expression:AddNode (RightExpression)
	self:CommitPosition ()
	return Expression
end

function Parser:ExpressionUnary ()
	return self:RecurseRightUnary (self.ExpressionIncrement, {["+"] = true, ["-"] = true, ["!"] = true, ["~"] = true})
end

function Parser:ExpressionIncrement ()
	local Expression = self:ExpressionNew ()
	local Operator = self:AcceptTokens ({["++"] = true, ["--"] = true})
	if Operator then
		local Increment = GCompute.Containers.Tree (Operator)
		Increment:AddNode (Expression)
		return Increment
	end
	return Expression
end

function Parser:ExpressionNew ()
	if not self:Accept ("new") then
		return self:ExpressionFunctionCall ()
	end
	local New = GCompute.Containers.Tree ("new")
	New:AddNode (self:Type ())
	if not self:Accept ("(") then
		self:ExpectedToken ("(")
	end
	local Arguments = self:List (self.Expression)
	Arguments.Value = "args"
	New:AddNode (Arguments)
	if not self:Accept (")") then
		self:ExpectedToken (")")
	end
	return New
end

function Parser:ExpressionFunctionCall ()
	local LeftExpression = self:ExpressionScopedVariable ()
	if not LeftExpression then
		return nil
	end
	local Call = nil
	while self:AcceptTokens ({["("] = true, ["["] = true}) do
		Call = nil
		local ClosingToken = ")"
		if self.LastAccepted == "(" then
			Call = GCompute.Containers.Tree ("call")
		else
			ClosingToken = "]"
			Call = GCompute.Containers.Tree ("index")
		end
		Call:AddNode (LeftExpression)
		if self:Accept (ClosingToken) then
			LeftExpression = Call
		else
			local Arguments = self:List (self.Expression)
			Arguments.Value = "args"
			Call:AddNode (Arguments)
			self:Accept (ClosingToken)
			LeftExpression = Call
		end
	end
	return LeftExpression
end

function Parser:ExpressionScopedVariable ()
	return self:RecurseLeft (self.ExpressionParentheses, {["."] = true})
end

function Parser:ExpressionParentheses ()
	if not self:AcceptAndSave ("(") then
		return self:ExpressionAnonymousFunction ()
	end
	local Expression = self:Expression ()
	if not self:Accept (")") then
		self:RestorePosition ()
		return nil
	end
	self:CommitPosition ()
	return Expression
end

function Parser:ExpressionAnonymousFunction ()
	self:SavePosition ()
	local Expression = GCompute.Containers.Tree ("afdecl")
	local Type = self:Type ()
	if not Type then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	Expression:AddNode (Type)
	if not self:Accept ("(") then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	local Arguments = Expression:Add ("args")
	repeat
		local Type = self:Type ()
		if not Type then
			break
		end
		local Argument = Arguments:Add ("arg")
		Argument:AddNode (Type)
		
		-- Arguments may be anonymous
		if self:AcceptType (GCompute.TokenType.Identifier) then
			Argument:Add (self.LastAccepted)
		end
	until not self:Accept (",")
	if not self:Accept (")") then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	if self.CurrentToken ~= "{" then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	self:PushParseNode (Expression)
	local Block = self:StatementBlock ()
	self:PopParseItem ()
	if not Block then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	return Expression
end

function Parser:ExpressionVariable ()
	local token = self:AcceptType (GCompute.TokenType.Identifier)
	if token then
		if token == "true" then
			return GCompute.Containers.Tree ("true")
		elseif token == "false" then
			return GCompute.Containers.Tree ("false")
		elseif token == "null" then
			return GCompute.Containers.Tree ("null")
		end
	
		local tree = GCompute.Containers.Tree ("name")
		tree:Add (token)
		return tree
	end
	return self:ExpressionValue ()
end

function Parser:ExpressionValue ()
	local Token = self:AcceptType (GCompute.TokenType.String)
	if Token then
		local Tree = GCompute.Containers.Tree ("str")
		Tree:Add (Token)
		return Tree
	end
	Token = self:AcceptType (GCompute.TokenType.Number)
	if Token then
		local Tree = GCompute.Containers.Tree ("num")
		Tree:Add (Token)
		return Tree
	end
	self.DebugOutput:WriteLine ("Failed to parse expression (" .. tostring (self.CurrentToken) .. ", " .. tostring (GCompute.TokenType [self.CurrentTokenType]) .. ").")
end

-- Type
function Parser:Type ()
	return self:TypeFunction ()
end

function Parser:TypeFunction ()
	return self:RecurseRight (self.TypeScoped, {["->"] = true})
end

function Parser:TypeScoped ()
	return self:RecurseLeft (self.TypeArray, {["."] = true})
end

function Parser:TypeArray ()
	local elementType = self:TypeTuple ()
	
	while self:Accept ("[") do
		local array = GCompute.Containers.Tree ("array")
		array:AddNode (elementType)
		
		local arguments = self:List (self.TypeArrayRank)
		arguments.Value = "args"
		array:AddNode (arguments)
		
		if not self:Accept ("]") then
			self:ExpectedToken ("]")
			return array
		end
		
		elementType = array
	end
	
	return elementType
end

function Parser:TypeArrayRank ()
	if self:Peek () == "," or
		self:Peek () == "]" then
		return GCompute.Containers.Tree ("any")
	end
	
	local number = self:AcceptType (GCompute.TokenType.Number)
	if number then
		return GCompute.Containers.Tree (number)
	end
end

function Parser:TypeTuple ()
	if self:Accept ("(") then
		local tuple = GCompute.Containers.Tree ("tuple")
		
		local arguments = self:List (self.Type)
		arguments.Value = "args"
		tuple:AddNode (arguments)
		if not self:Accept (")") then
			self:ExpectedToken (")")
		end
		
		return tuple
	end
	return self:TypeTemplate ()
end

function Parser:TypeTemplate ()
	local typeName = self:TypeName ()
	if not self:Accept ("<") then
		return typeName
	end
	local parametricType = GCompute.Containers.Tree ("parametric_type")
	parametricType:AddNode (typeName)
	if self:Accept (">") then
		self:SyntaxError ("Empty parametric type argument lists are not allowed.")
		return parametricType
	else
		local arguments = self:List (self.Type)
		arguments.Value = "args"
		parametricType:AddNode (arguments)
		if not self:Accept (">") then
			self:ExpectedToken (">")
		end
	end
	return parametricType
end

function Parser:TypeName ()
	local typeName = self:AcceptType (GCompute.TokenType.Identifier)
	if not typeName then
		return nil
	end
	
	local tree = GCompute.Containers.Tree ("name")
	tree:Add (typeName)
	
	return tree
end