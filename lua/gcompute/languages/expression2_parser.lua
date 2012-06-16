local self = Parser
--[[
	Based off lua/entities/gmod_wire_expression2/base/parser.lua
	
	Root
	 1 : q1

	seQuencing
	 1 : ""
	 2 : "s1 q1", "s1, q2"

	Statement
	 1 : if (e1) { q1 } i1
	 2 : while (e1) { q1 }
	 3 : for (var = e1, e1[, e1]) { q1 }
	 4 : foreach(var, var:type = e1) { q1}
	 5 : break, continue
	 6 : var++, var--
	 7 : var += e1, var -= e1, var *= e1, var /= e1
	 8 : var = s8, var[e1,type] = s8
	 9 : e1

	If
	 1 : elseif (e1) { q1 } i1
	 2 : else { q1 }

	Expression
	 1 : var = e1, var += e1, var -= e1, var *= e1, var /= e1 [ERROR]
	 2 : e3 ? e1 : e1, e3 ?: e1
	 3 : e1 | e2			-- (or)
	 4 : e1 & e2			-- (and)
	 5 : e1 || e2 			-- (bit or)
	 6 : e1 && e1			-- (bit and)
	 7 : e1 ^^ e2			-- (bit xor)
	 6 : e5 == e6, e5 != e6
	 7 : e6 < e7, e6 > e7, e6 <= e7, e6 >= e7
	 8 : e1 << e2, e1 >> e2 -- (bit shift)
	 9 : e7 + e8, e7 - e8
	10 : e8 * e9, e8 / e9, e8 % e9
	11 : e9 ^ e10
	12 : +e11, -e11, !e10
	13 : e11:fun([e1, ...]), e11[var,type]
	14 : (e1), fun([e1, ...])
	15 : string, num, ~var, $var, ->var
	16 : var++, var-- [ERROR]
	17 : var
]]

-- Root
function self:Root ()
	local block = GCompute.AST.Block ()
	block:AddStatements (self:Sequence ())
	return block
end

-- Sequence
function self:Sequence ()
	local statements = {}
	while self:Peek () and self:Peek () ~= "}" do
		statements [#statements + 1] = self:Statement ()
		if self:Accept (",") and (not self:Peek () or self:Peek () == "}") then
			self.CompilationUnit:Error ("Expected <statement> after ','.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
	end
	return statements
end

-- Statement
function self:Statement ()
	self.DebugOutput:WriteLine ("Statement:")
	self.DebugOutput:IncreaseIndent ()
	
	self:SavePosition ()
	self:AcceptType (GCompute.TokenType.Newline)
	
	local statement, accepted =
		self:StatementNull () or
		self:StatementIf () or
		self:StatementFor () or
		self:StatementForEach () or
		self:StatementControl () or
		self:StatementTypeDeclaration () or
		self:StatementBlock () or
		self:StatementFunctionDeclaration () or 
		self:StatementVariableDeclaration () or 
		self:StatementExpression ()
	if statement or accepted then
		self.DebugOutput:DecreaseIndent ()
		self:Accept (";")
		self:CommitPosition ()
		return statement
	end
	self:RestorePosition ()
	self:GetNextToken ()
	self.DebugOutput:DecreaseIndent ()
	return nil
end

function self:StatementNull ()
	return nil, self:Accept (";")
end

function self:StatementIf ()
	if not self:AcceptAndSave ("if") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'if'.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	local ifStatement = GCompute.AST.IfStatement ()
	local condition = self:Expression ()
	if not condition then self:ExpectedItem ("expression") end
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after if condition.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	local statement = self:Statement ()
	ifStatement:AddCondition (condition, statement)
	
	while self:Accept ("elseif") do
		if not self:Accept ("(") then
			self.CompilationUnit:Error ("Expected '(' after 'elseif'.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
		local condition = self:Expression ()
		if not condition then self:ExpectedItem ("expression") end
		if not self:Accept (")") then
			self.CompilationUnit:Error ("Expected ')' after elseif condition.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
		local statement = self:Statement ()
		ifStatement:AddCondition (condition, statement)
	end
	if self:Accept ("else") then
		ifStatement:SetElseStatement (self:Statement ())
	end
	self:CommitPosition ()
	return ifStatement
end

function self:StatementFor ()
	if not self:AcceptAndSave ("for") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'for'.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	
	local variable = self:ForVariable ()
	local forStatement = GCompute.AST.RangeForLoop ()
	forStatement:SetVariable (variable)
	if not self:Accept ("=") then
		self.CompilationUnit:Error ("Expected '=' after variable in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	local startValue = self:Expression ()
	if not startValue then
		self.CompilationUnit:Error ("Expected <expression> after '=' in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	if not self:Accept (",") then
		self.CompilationUnit:Error ("Expected ',' after <numeric-literal> in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	local endValue = self:Expression ()
	if not endValue then
		self.CompilationUnit:Error ("Expected expression after ',' in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	if self:Accept (",") then
		local increment = self:Expression ()
		if not increment then
			forStatement:AddRange (startValue, endValue)
			self.CompilationUnit:Error ("Expected expression after ',' in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		else
			forStatement:AddRange (startValue, endValue, increment)
		end
	else
		forStatement:AddRange (startValue, endValue)
	end
	
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after expression in for loop.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	
	local statement = self:Statement ()
	forStatement:SetLoopStatement (statement)
	
	self:CommitPosition ()
	return forStatement
end

function self:StatementForEach ()
	return nil
end

function self:ForVariable ()
	local variable = nil
	if self:Accept ("local") then
		variable = GCompute.AST.VariableDeclaration ()
		variable:SetName (self:AcceptType (GCompute.TokenType.Identifier))
	else
		variable = self:QualifiedIdentifier ()
	end
	return variable
end

function self:StatementControl ()
	if self:AcceptTokens ({["break"] = true, ["continue"] = true}) then
		if self:GetLastToken ().Value == "break" then
			return GCompute.AST.Break ()
		else
			return GCompute.AST.Continue ()
		end
	end
	if self:Accept ("return") then
		local returnStatement = GCompute.AST.Return ()
		if self.CurrentToken ~= ";" then
		else
			returnStatement:SetReturnExpression (self:Expression ())
		end
		return returnStatement
	end
	return nil
end

function Parser:StatementTypeDeclaration ()
	self.DebugOutput:WriteLine ("Trying type declaration...")
	self:SavePosition ()
	self:ChompModifiers ()
	if self.Language:GetKeywordType (self.CurrentToken) ~= GCompute.KeywordTypes.DataType then
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
		self.CompilerContext:PrintWarningMessage ("Expected <identifier> after \",\".")
	end
	self:PopParseItem ()
	self:CommitPosition ()
	return true
end

function Parser:StatementBlock ()
	if not self:Accept ("{") then return nil end
	self:AcceptWhitespace ()
	
	local blockStatement = self.CurrentToken
	self:GetNextToken ()
	
	self:Accept ("}")
	return blockStatement
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
	local expression = self:Expression ()
	if not expression then
		self:RestorePosition ()
		return nil
	end
	self:CommitPosition ()
	return expression
end

-- Expression, may recurse left.
function self:Expression ()
	return self:ExpressionAssignment ()
end

-- Right associative
function self:ExpressionAssignment ()
	return self:RecurseRight (self.ExpressionTernary, {["="] = true, ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true})
end

function self:ExpressionTernary ()
	local leftExpression = self:ExpressionBooleanOr ()
	
	if self:Accept ("?") then
		local trueExpression = self:Expression ()
		
		if not self:Accept (":") then
			self.CompilationUnit:Error ("Expected ':' after <expression> in <ternary-expression>.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
		local falseExpression = self:Expression ()
		local ternaryExpression = GCompute.AST.TernaryExpression ()
		ternaryExpression:SetCondition (leftExpression)
		ternaryExpression:SetTrueExpression (trueExpression)
		ternaryExpression:SetFalseExpression (falseExpression)
		return ternaryExpression
	end
	
	return leftExpression
end

function self:ExpressionBooleanOr ()
	return self:RecurseLeft (self.ExpressionBooleanAnd, {["||"] = true})
end

function self:ExpressionBooleanAnd ()
	return self:RecurseLeft (self.ExpressionEquality, {["&&"] = true})
end

function self:ExpressionEquality ()
	return self:RecurseLeft (self.ExpressionComparison, {["=="] = true, ["!="] = true})
end

function self:ExpressionComparison ()
	return self:RecurseLeft (self.ExpressionAddition, {["<"] = true, [">"] = true, ["<="] = true, [">="] = true})
end

function self:ExpressionAddition ()
	return self:RecurseLeft (self.ExpressionSubtraction, {["+"] = true})
end

function self:ExpressionSubtraction ()
	return self:RecurseLeft (self.ExpressionMultiplication, {["-"] = true})
end

function self:ExpressionMultiplication ()
	return self:RecurseLeft (self.ExpressionDivision, {["*"] = true})
end

function self:ExpressionDivision ()
	return self:RecurseLeft (self.ExpressionExponentiation, {["/"] = true, ["%"] = true})
end

function self:ExpressionExponentiation ()
	return self:RecurseRight (self.ExpressionTypeCast, {["^"] = true})
end

function self:ExpressionTypeCast ()
	if not self:AcceptAndSave ("(") then return self:ExpressionUnary () end
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
	local leftExpression = self:ExpressionNew ()
	local operator = self:AcceptTokens ({["++"] = true, ["--"] = true})
	if operator then
		local unaryExpression = GCompute.AST.UnaryOperator ()
		unaryExpression:SetLeftExpression (leftExpression)
		unaryExpression:SetOperator (operator)
		return unaryExpression
	end
	return leftExpression
end

function Parser:ExpressionNew ()
	if not self:Accept ("new") then return self:ExpressionFunctionCallOrArrayIndex () end
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

function self:ExpressionFunctionCallOrArrayIndex ()
	local leftExpression = self:ExpressionScopedVariable ()
	if not leftExpression then return nil end
	
	local functionCallExpression = nil
	self:AcceptWhitespace ()
	while self:AcceptTokens ({["("] = true, ["["] = true}) do
		functionCallExpression = nil
		local closingToken = ")"
		if self.LastAccepted == "(" then
			functionCallExpression = GCompute.AST.FunctionCall ()
			functionCallExpression:SetFunctionExpression (leftExpression)
		else
			closingToken = "]"
			functionCallExpression = GCompute.AST.ArrayIndex ()
			functionCallExpression:SetLeftExpression (leftExpression)
		end
		if not self:Accept (closingToken) then
			functionCallExpression:AddArguments (self:List (self.Expression))
			self:Accept (closingToken)
		end
		leftExpression = functionCallExpression
	end
	return leftExpression
end

function Parser:ExpressionScopedVariable ()
	return self:RecurseLeft (self.ExpressionParentheses, {["."] = true})
end

function Parser:ExpressionParentheses ()
	if not self:AcceptAndSave ("(") then
		return self:ExpressionAnonymousFunction ()
	end
	
	local leftParenthesisToken = self:GetLastToken ()
	
	local innerExpression = self:Expression ()
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' to close '(' at line " .. leftParenthesisToken.Line .. ", char " .. leftParenthesisToken.Character .. ".", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	self:CommitPosition ()
	return innerExpression
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
	local literalExpression = self:ExpressionLiteral ()
	if literalExpression then return literalExpression end
	
	return self:UnqualifiedIdentifier ()
end

function self:ExpressionLiteral ()
	return self:ExpressionBooleanLiteral () or self:ExpressionNumericLiteral () or self:ExpressionStringLiteral ()
end

function self:ExpressionBooleanLiteral ()
	if self:Accept ("true") or self:Accept ("false") then
		return GCompute.AST.BooleanLiteral (self:GetLastToken ().Value)
	end
	return nil
end

function self:ExpressionNumericLiteral ()
	if self:AcceptType (GCompute.TokenType.Number) then
		return GCompute.AST.NumericLiteral (self:GetLastToken ().Value)
	end
	return nil
end

function self:ExpressionStringLiteral ()
	local stringToken = self:AcceptType (GCompute.TokenType.String)
	if stringToken then
		return GCompute.AST.StringLiteral (stringToken)
	end
	return nil
end

function self:Type ()
	return self:QualifiedIdentifier ()
end

function self:QualifiedIdentifier ()
	return self:UnqualifiedIdentifier ()
end

function self:UnqualifiedIdentifier ()
	if not self:AcceptType (GCompute.TokenType.Identifier) then return nil end
	return GCompute.AST.Identifier (self:GetLastToken ().Value)
end