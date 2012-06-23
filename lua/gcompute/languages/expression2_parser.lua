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

function self:ctor ()
	self.InCaseLabel = false
end

-- Root
function self:Root ()
	local block = GCompute.AST.Block ()
	block:AddStatements (self:Sequence ())
	return block
end

-- Sequence
function self:Sequence ()
	local statements = {}
	while self:PeekType () ~= GCompute.TokenType.EndOfFile and self:Peek () ~= "}" do
		local statement, accepted = self:Statement ()
		statements [#statements + 1] = statement
		if not statement and not accepted then
			self:ExpectedItem ("statement")
			self:GetNextToken ()
		end
		if self:Accept (",") and (self:PeekType () == GCompute.TokenType.EndOfFile or self:Peek () == "}") then
			self.CompilationUnit:Error ("Expected <statement> after ','.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
		
		self:AcceptWhitespace ()
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
		self:StatementWhile () or
		self:StatementSwitch () or
		self:StatementControl () or
		self:StatementTypeDeclaration () or
		self:StatementBlock () or
		self:StatementFunctionDeclaration () or
		self:StatementVariableDeclaration () or
		self:StatementLabel () or
		self:StatementExpression ()
	if statement or accepted then
		self.DebugOutput:DecreaseIndent ()
		self:Accept (";")
		self:CommitPosition ()
		return statement, accepted
	end
	self:RestorePosition ()
	
	self.DebugOutput:DecreaseIndent ()
	return nil
end

function self:StatementNull ()
	return nil, self:Accept (";")
end

function self:StatementIf ()
	if not self:Accept ("if") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'if'.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local ifStatement = GCompute.AST.IfStatement ()
	local condition = self:Expression ()
	if not condition then self:ExpectedItem ("expression") end
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after expression in if condition.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local statement = self:Statement ()
	ifStatement:AddCondition (condition, statement)
	
	self:AcceptWhitespace ()
	while self:Accept ("elseif") do
		if not self:Accept ("(") then
			self.CompilationUnit:Error ("Expected '(' after 'elseif'.", self.TokenNode.Line, self.TokenNode.Character)
		end
		local condition = self:Expression ()
		if not condition then self:ExpectedItem ("expression") end
		if not self:Accept (")") then
			self.CompilationUnit:Error ("Expected ')' after elseif condition.", self.TokenNode.Line, self.TokenNode.Character)
		end
		local statement = self:Statement ()
		ifStatement:AddCondition (condition, statement)
		
		self:AcceptWhitespace ()
	end
	self:AcceptWhitespace ()
	if self:Accept ("else") then
		ifStatement:SetElseStatement (self:Statement ())
	end
	return ifStatement
end

function self:StatementFor ()
	if not self:Accept ("for") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'for'.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	local loopVariable = self:ForVariable ()
	local forStatement = GCompute.AST.RangeForLoop ()
	forStatement:SetLoopVariable (loopVariable)
	if not self:Accept ("=") then
		self.CompilationUnit:Error ("Expected '=' after variable in for loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local startValue = self:Expression ()
	if not startValue then
		self.CompilationUnit:Error ("Expected <expression> after '=' in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
	end
	if not self:Accept (",") then
		self.CompilationUnit:Error ("Expected ',' after <numeric-literal> in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local endValue = self:Expression ()
	if not endValue then
		self.CompilationUnit:Error ("Expected <expression> after ',' in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
	end
	if self:Accept (",") then
		local increment = self:Expression ()
		if not increment then
			forStatement:AddRange (startValue, endValue)
			self.CompilationUnit:Error ("Expected <expression> after ',' in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
		else
			forStatement:AddRange (startValue, endValue, increment)
		end
	else
		forStatement:AddRange (startValue, endValue)
	end
	
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after expression in for loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	self:AcceptWhitespace ()
	local statement = self:Statement ()
	forStatement:SetBody (statement)
	
	return forStatement
end

function self:StatementForEach ()
	if not self:Accept ("foreach") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'foreach'.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	local forEachStatement = GCompute.AST.IteratorForLoop ()
	forEachStatement:AddVariables (self:ForEachVariables ())
	if not self:Accept ("=") then
		self.CompilationUnit:Error ("Expected '=' after variable in foreach loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local iteratorExpression = self:Expression ()
	if not iteratorExpression then
		self.CompilationUnit:Error ("Expected <expression> after '=' in foreach loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	forEachStatement:SetIteratorExpression (iteratorExpression)
	
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after <expression> in foreach loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	self:AcceptWhitespace ()
	local statement = self:Statement ()
	forEachStatement:SetBody (statement)
	
	return forEachStatement
end

function self:ForVariable ()
	local variable = nil
	if self:Accept ("local") then
		variable = GCompute.AST.VariableDeclaration ()
		local identifier = self:AcceptType (GCompute.TokenType.Identifier) 
		variable:SetName (identifier)
		if not identifier then
			self.CompilationUnit:Error ("Expected <identifier> after 'local' in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
		end
		if self:Accept (":") then
			local variableType = self:Type ()
			if not variableType then
				self.CompilationUnit:Error ("Expected <type> after ':' in variable declaration in for loop expression.", self.TokenNode.Line, self.TokenNode.Character)
			end
			variable:SetVariableType (variableType)
		end
	else
		variable = self:QualifiedIdentifier ()
	end
	return variable
end

function self:ForEachVariables ()
	local variables = {}
	local isLocal = false
	if self:Accept ("local") then
		isLocal = true
	end
	
	repeat
		local identifier = nil
		if isLocal then
			local variable = GCompute.AST.VariableDeclaration ()
			identifier = self:AcceptType (GCompute.TokenType.Identifier)
			variable:SetName (identifier)
			
			if self:Accept (":") then
				local variableType = self:Type ()
				if not variableType then
					self.CompilationUnit:Error ("Expected <type> after ':' in variable declaration in foreach loop.", self.TokenNode.Line, self.TokenNode.Character)
				end
				variable:SetVariableType (variableType)
			end
			
			variables [#variables + 1] = variable
		else
			identifier = self:QualifiedIdentifier ()
			
			if self:Accept (":") then
				local variableType = self:Type ()
				if not variableType then
					self.CompilationUnit:Error ("Expected <type> after ':' in variable declaration in foreach loop.", self.TokenNode.Line, self.TokenNode.Character)
				end
				identifier:AddTargetType (variableType)
			end
			
			variables [#variables + 1] = identifier
		end
		if not identifier then
			self.CompilationUnit:Error ("Expected <identifier> in foreach expression.", self.TokenNode.Line, self.TokenNode.Character)
		end
	until not self:Accept (",")
	
	return variables
end

function self:StatementWhile ()
	if not self:Accept ("while") then return nil end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'while'.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	local condition = self:StatementVariableDeclaration () or self:Expression ()
	if not condition then
		self.CompilationUnit:Error ("Expected <variable-declaration> or <expression> after '(' in while loop.", self.TokenNode.Line, self.TokenNode.Character)
	elseif condition:Is ("VariableDeclaration") then
		if not condition:GetRightExpression () then
			self.CompilationUnit:Error ("<variable-declaration> in while loop must assign a value to the variable.", self.TokenNode.Line, self.TokenNode.Character)
		end
	end
	
	local whileStatement = GCompute.AST.WhileLoop ()
	whileStatement:SetCondition (condition)
	
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after <expression> in while loop.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	self:AcceptWhitespace ()
	local statement = self:Statement ()
	whileStatement:SetBody (statement)
	
	return whileStatement
end

function self:StatementSwitch ()
	if not self:Accept ("switch") then return end
	if not self:Accept ("(") then
		self.CompilationUnit:Error ("Expected '(' after 'switch'.", self.TokenNode.Line, self.TokenNode.Character)
	end

	local switchExpression = self:Expression ()
	if not switchExpression then
		self.CompilationUnit:Error ("Expected <expression> after '(' in switch statement.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	local switchStatement = GCompute.AST.SwitchStatement ()
	switchStatement:SetSwitchExpression (switchExpression)
	
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' after <expression> in switch statement.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	if not self:Accept ("{") then
		self.CompilationUnit:Error ("Expected '{' after expression in switch statement.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	if not self:AcceptType (GCompute.TokenType.AST) then
		self.CompilationUnit:Error ("Expected <pre-parsed ast> after '{' in switch statement.", self.TokenNode.Line, self.TokenNode.Character)
	end
	local switchBody = self:GetLastToken ().AST
	
	local caseExpression = nil
	local body = nil
	for statement in switchBody:GetEnumerator () do
		if statement:Is ("CaseLabel") then
			if caseExpression or body then
				switchStatement:AddCase (caseExpression, body)
			end
			caseExpression = statement:GetCaseExpression ()
			body = GCompute.AST.Block ()
		elseif statement:Is ("Label") and statement:GetName () == "default" then
			if caseExpression or body then
				switchStatement:AddCase (caseExpression, body)
			end
			caseExpression = nil
			body = GCompute.AST.Block ()
		elseif body then
			body:AddStatement (statement)
		else
			self.CompilationUnit:Error ("Statements (" .. GCompute.String.EscapeWhitespace (statement:ToString ()) .. ") must be part of a case body in switch statements.", self.TokenNode.Line, self.TokenNode.Character)
		end
	end
	if caseExpression or body then
		switchStatement:AddCase (caseExpression, body)
	end
	
	if not self:Accept ("}") then
		self.CompilationUnit:Error ("Expected '}' to close switch statement body.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	return switchStatement
end

function self:StatementControl ()
	if self:Accept ("break") then
		return GCompute.AST.Break ()
	elseif self:Accept ("continue") then
		return GCompute.AST.Continue ()
	elseif self:Accept ("return") then
		local returnStatement = GCompute.AST.Return ()
		self:AcceptWhitespace ()
		if self:Peek () ~= ";" and self:Peek () ~= "}" then
			returnStatement:SetReturnExpression (self:Expression ())
		end
		return returnStatement
	end
	return nil
end

function Parser:StatementTypeDeclaration ()
	if true then return nil end

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

function self:StatementBlock ()
	if not self:Accept ("{") then return nil end
	self:AcceptWhitespace ()
	
	local blockStatement = nil
	if self:AcceptType (GCompute.TokenType.AST) then
		blockStatement = self:GetLastToken ().AST
	else
		self.CompilationUnit:Error ("Parser bug: Expected <pre-parsed block> after '{'.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	
	self:Accept ("}")
	return blockStatement
end

function self:StatementFunctionDeclaration ()
	-- Example: function (type) (type:)functionName (arguments) {}
	-- type
	--     type:functionName (
	--     :functionName (
	--     functionName (
	-- functionName (
	if not self:Accept ("function") then return nil end
	
	self.DebugOutput:WriteLine ("Function declaration:")
	self.DebugOutput:IncreaseIndent ()
	
	self:SavePosition ()
	local functionDeclaration = GCompute.AST.FunctionDeclaration ()
	local returnType = nil
	local typeExpression = nil
	local functionName = self:AcceptType (GCompute.TokenType.Identifier)
	if not self:Accept ("(") then
		-- either:
		--    type:functionName (
		--    type type:functionName (
		--    type functionName (
		self:RestorePosition ()
		returnType = self:Type ()
		if self:Accept (":") then
			-- type
			--     :functionName (
			self.DebugOutput:WriteLine ("type:functionName")
			
			typeExpression = returnType
			returnType = nil
			functionName = self:AcceptType (GCompute.TokenType.Identifier)
			self:Accept ("(")
		else
			-- type
			--     type:functionName (
			--     functionName (
			self:SavePosition ()
			functionName = self:AcceptType (GCompute.TokenType.Identifier)
			if self:Accept ("(") then
				-- type functionName (
				self.DebugOutput:WriteLine ("type functionName")
				self:CommitPosition ()
			else
				-- type type:functionName (
				self.DebugOutput:WriteLine ("type type:functionName")
				self:RestorePosition ()
				typeExpression = self:Type ()
				self:Accept (":")
				functionName = self:AcceptType (GCompute.TokenType.Identifier)
				self:Accept ("(")
			end
		end
	else
		-- functionName (
		self:CommitPosition ()
	end
	
	functionDeclaration:SetReturnType (returnType)
	functionDeclaration:SetName (functionName)
	if typeExpression then
		functionDeclaration:SetTypeExpression (typeExpression)
		functionDeclaration:SetMemberFunction (true)
	end
	
	if self:Peek () ~= ")" then
		repeat
			local parameterName = self:AcceptType (GCompute.TokenType.Identifier)
			local parameterType = nil
			if self:Accept (":") then
				parameterType = self:Type ()
				if not parameterType then
					self.CompilationUnit:Error ("Expected <type> after ':' in argument list of function declaration.", self:GetLastToken ().Line, self:GetLastToken ().Character)
				end
			else
				parameterType = GCompute.AST.Identifier ("number")
			end
			
			functionDeclaration:AddParameter (parameterType, parameterName)
		until not self:Accept (",")
	end
	if not self:Accept (")") then
		self.CompilationUnit:Error ("Expected ')' to close argument list in function declaration.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	
	self:AcceptWhitespace ()	
	local blockStatement = self:StatementBlock ()
	if not blockStatement then
		self:Accept (";")
	end
	functionDeclaration:SetBody (blockStatement)

	self.DebugOutput:DecreaseIndent ()
	return functionDeclaration
end

function self:StatementVariableDeclaration ()
	-- local variableName
	-- local variableName = expression
	-- local variableName:typeName
	-- local variableName:typeName = expression	
	if not self:Accept ("local") then return end
	local variableName = self:AcceptType (GCompute.TokenType.Identifier)
	if not variableName then
		self.CompilationUnit:Error ("Expected <identifier> after 'local' in variable declaration.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	local typeExpression = nil
	local rightExpression = nil
	
	if self:Accept (":") then
		typeExpression = self:Type ()
		if not typeExpression then
			self.CompilationUnit:Error ("Expected <type> after ':' in variable declaration.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
	end
	
	if self:Accept ("=") then
		rightExpression = self:Expression ()
		if not rightExpression then
			self.CompilationUnit:Error ("Expected <expression> after '=' in variable declaration.", self:GetLastToken ().Line, self:GetLastToken ().Character)
		end
	end
	
	local variableDeclaration = GCompute.AST.VariableDeclaration ()
	variableDeclaration:SetVariableType (typeExpression)
	variableDeclaration:SetName (variableName)
	variableDeclaration:SetRightExpression (rightExpression)
	
	return variableDeclaration
end

function self:StatementLabel ()
	if self:AcceptAndSave ("default") then
		if self:Accept (":") or self:Accept (",") then
			self:CommitPosition ()
			return GCompute.AST.CaseLabel ()
		else
			self:RestorePosition ()
		end
	end
	
	if not self:AcceptAndSave ("case") then return nil end
	self.InCaseLabel = true
	local caseExpression = self:Expression ()
	self.InCaseLabel = false
	if not caseExpression then
		self:RestorePosition ()
		return nil
	end
	
	if not self:Accept (":") and not self:Accept (",") then
		self:RestorePosition ()
		return nil
	end
	
	local caseLabel = GCompute.AST.CaseLabel ()
	caseLabel:SetCaseExpression (caseExpression)
	self:CommitPosition ()
	return caseLabel
end

function self:StatementExpression ()
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
local assignment = { ["="] = true, ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true }
function self:ExpressionAssignment ()
	return self:RecurseRight (self.ExpressionTernary, assignment)
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

local booleanOr = { ["|"] = true }
function self:ExpressionBooleanOr ()
	return self:RecurseLeft (self.ExpressionBooleanAnd, booleanOr)
end

local booleanAnd = { ["&"] = true }
function self:ExpressionBooleanAnd ()
	return self:RecurseLeft (self.ExpressionBinaryOr, booleanAnd)
end

local binaryOr = { ["||"] = true }
function self:ExpressionBinaryOr ()
	return self:RecurseLeft (self.ExpressionBinaryAnd, binaryOr)
end

local binaryAnd = { ["&&"] = true }
function self:ExpressionBinaryAnd ()
	return self:RecurseLeft (self.ExpressionBinaryXor, binaryAnd)
end

local binaryXor = { ["^^"] = true }
function self:ExpressionBinaryXor ()
	return self:RecurseLeft (self.ExpressionEquality, binaryXor)
end

local equality = { ["=="] = true, ["!="] = true }
function self:ExpressionEquality ()
	return self:RecurseLeft (self.ExpressionComparison, equality)
end

local comparison = { ["<"] = true, [">"] = true, ["<="] = true, [">="] = true }
function self:ExpressionComparison ()
	return self:RecurseLeft (self.ExpressionBitShift, comparison)
end

local bitShift = { ["<<"] = true, [">>"] = true }
function self:ExpressionBitShift ()
	return self:RecurseLeft (self.ExpressionAddition, bitShift)
end

local addition = { ["+"] = true }
function self:ExpressionAddition ()
	return self:RecurseLeft (self.ExpressionSubtraction, addition)
end

local subtraction = { ["-"] = true }
function self:ExpressionSubtraction ()
	return self:RecurseLeft (self.ExpressionMultiplication, subtraction)
end

local multiplication = { ["*"] = true }
function self:ExpressionMultiplication ()
	return self:RecurseLeft (self.ExpressionDivision, multiplication)
end

local division = { ["/"] = true, ["%"] = true }
function self:ExpressionDivision ()
	return self:RecurseLeft (self.ExpressionExponentiation, division)
end

local exponentiation = { ["^"] = true }
function self:ExpressionExponentiation ()
	return self:RecurseRight (self.ExpressionTypeCast, exponentiation)
end

function self:ExpressionTypeCast ()
	if not self:AcceptAndSave ("(") then return self:ExpressionUnary () end
	self.DebugOutput:WriteLine ("Matching type cast:")
	self.DebugOutput:IncreaseIndent ()
	local typeExpression = self:Type ()
	if not typeExpression then
		self:RestorePosition ()
		self.DebugOutput:DecreaseIndent ()
		return self:ExpressionUnary ()
	end
	if not self:Accept (")") then
		self:RestorePosition ()
		self.DebugOutput:DecreaseIndent ()
		return self:ExpressionUnary ()
	end
	
	local typeCastExpression = GCompute.AST.TypeCast ()
	typeCastExpression:SetTypeExpression (typeExpression)
	
	local rightExpression = self:ExpressionTypeCast ()
	if not rightExpression then
		self.DebugOutput:WriteLine ("Type cast invalid: No right expression.")
		self.DebugOutput:DecreaseIndent ()
		self:RestorePosition ()
		return self:ExpressionUnary ()
	end
	
	-- If the right expression is an argument list with 0 or > 1 arguments, then it should be rejected.
	-- Otherwise if we find that the contents are indeed not a type, fix it in the semantic analysis stage.
	typeCastExpression:SetRightExpression (rightExpression)
	self:CommitPosition ()
	return typeCastExpression
end

local unary = { ["+"] = true, ["-"] = true, ["!"] = true, ["~"] = true }
function self:ExpressionUnary ()
	return self:RecurseRightUnary (self.ExpressionIncrement, unary, "expression")
end

local increment = { ["++"] = true, ["--"] = true }
function self:ExpressionIncrement ()
	local leftExpression = self:ExpressionNew ()
	local operator = self:AcceptTokens (increment)
	if operator then
		local unaryExpression = GCompute.AST.RightUnaryOperator ()
		unaryExpression:SetLeftExpression (leftExpression)
		unaryExpression:SetOperator (operator)
		return unaryExpression
	end
	return leftExpression
end

function self:ExpressionNew ()
	if not self:Accept ("new") then
		return self:ExpressionFunctionCallOrArrayIndexOrIndex ()
	end
	
	local newExpression = GCompute.AST.New ()
	local typeExpression = self:Type ()
	if not typeExpression then
		self.CompilationUnit:Error ("Expected <type> after 'new'.", self:GetLastToken ().Line, self:GetLastToken ().Character)
	end
	newExpression:SetTypeExpression (typeExpression)
	
	if not self:Accept ("(") then
		self:ExpectedToken ("(")
	end
	
	local arguments = self:List (self.Expression)
	newExpression:AddArguments (arguments)
	if not self:Accept (")") then
		self:ExpectedToken (")")
	end
	return newExpression
end

function self:ExpressionFunctionCallOrArrayIndexOrIndex ()
	local leftExpression = self:ExpressionParentheses ()
	if not leftExpression then return nil end
	
	-- derp ():herp () [aaa, herp ()]:derp () ()
	local nextCharacter = nil
	local matched = true
	repeat
		self:AcceptWhitespace ()
		nextCharacter = self:Peek ()
		matched = true
		local newLeftExpression = nil
		if nextCharacter == "(" then
			newLeftExpression = self:ExpressionFunctionCall (leftExpression)
		elseif nextCharacter == ":" then
			newLeftExpression = self:ExpressionMemberFunctionCall (leftExpression)
		elseif nextCharacter == "[" then
			newLeftExpression = self:ExpressionArrayIndex (leftExpression)
		elseif nextCharacter == "." then
			newLeftExpression = self:ExpressionIndex (leftExpression)
		else
			matched = false
		end
		if matched then
			if newLeftExpression == leftExpression then
				matched = false
			else
				leftExpression = newLeftExpression
			end
		end
	until not matched
	
	return leftExpression
end

function self:ExpressionFunctionCall (leftExpression)
	if not self:Accept ("(") then return leftExpression end
	
	local functionCallExpression = GCompute.AST.FunctionCall ()
	functionCallExpression:SetLeftExpression (leftExpression)
	if not self:Accept (")") then
		functionCallExpression:AddArguments (self:List (self.Expression))
		if not self:Accept (")") then
			self.CompilationUnit:Error ("Expected ')' to close function call argument list.", self.TokenNode.Line, self.TokenNode.Character)
		end
	end
	return functionCallExpression
end

function self:ExpressionMemberFunctionCall (leftExpression)
	if not self:AcceptAndSave (":") then return leftExpression end
	local identifier = self:AcceptType (GCompute.TokenType.Identifier)
	local identifierLine = self.TokenNode.Line
	local identifierCharacter = self.TokenNode.Character
	
	local memberFunctionCallExpression = GCompute.AST.MemberFunctionCall ()
	memberFunctionCallExpression:SetLeftExpression (leftExpression)
	memberFunctionCallExpression:SetMemberName (identifier)
	
	local noLeftParenthesis = not self:Accept ("(")
	local leftParenthesisLine = self.TokenNode.Line
	local leftParenthesisCharacter = self.TokenNode.Character
	
	local noRightParenthesis = false
	if not self:Accept (")") then
		memberFunctionCallExpression:AddArguments (self:List (self.Expression))
		noRightParenthesis = not self:Accept (")")
	end
	
	-- Need to leave a ":" for the case labels.
	if self.InCaseLabel and self:Peek () ~= ":" and self:Peek () ~= "," then
		self:RestorePosition ()
		return leftExpression
	end
	
	if self.InCaseLabel and noLeftParenthesis and noRightParenthesis then
		self:RestorePosition ()
		return leftExpression
	end
	
	if not identifier then
		self.CompilationUnit:Error ("Expected <identifier> after ':' in member function call.", identifierLine, identifierCharacter)
	end
	if noLeftParenthesis then
		self.CompilationUnit:Error ("Expected '(' to start member function call argument list.", leftParenthesisLine, leftParenthesisCharacter)
	end
	if noRightParenthesis then
		self.CompilationUnit:Error ("Expected ')' to close member function call argument list.", self.TokenNode.Line, self.TokenNode.Character)
	end
	
	self:CommitPosition ()
	return memberFunctionCallExpression
end

function self:ExpressionArrayIndex (leftExpression)
	if not self:Accept ("[") then return leftExpression end
	
	local arrayIndexExpression = GCompute.AST.ArrayIndex ()
	arrayIndexExpression:SetLeftExpression (leftExpression)
	if not self:Accept ("]") then
		arrayIndexExpression:AddArguments (self:List (self.Expression))
		if not self:Accept ("]") then
			self.CompilationUnit:Error ("Expected ']' to close index argument list.", self.TokenNode.Line, self.TokenNode.Character)
		end
	end
	return arrayIndexExpression
end

function self:ExpressionIndex (leftExpression)
	if not self:Accept (".") then return leftExpression end
	
	local nameIndexExpression = GCompute.AST.NameIndex ()
	nameIndexExpression:SetLeftExpression (leftExpression)
	local identifier = self:UnqualifiedIdentifier ()
	if not identifier then
		self.CompilationUnit:Error ("Expected <identifier> after '.' in name index expression.", self.TokenNode.Line, self.TokenNode.Character)
	end
	return nameIndexExpression
end

function self:ExpressionParentheses ()
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

function self:ExpressionAnonymousFunction ()
	self:SavePosition ()
	local returnType = self:Type ()
	if not returnType then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	
	if not self:Accept ("(") then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	
	local anonymousFunctionExpression = GCompute.AST.AnonymousFunction ()
	anonymousFunctionExpression:SetReturnType (returnType)
	
	if self:Peek () ~= ")" then
		repeat
			local parameterName = self:AcceptType (GCompute.TokenType.Identifier)
			local parameterType = nil
			if self:Accept (":") then
				parameterType = self:Type ()
				if not parameterType then
					self.CompilationUnit:Error ("Expected <type> after ':' in argument list of anonymous function.", self:GetLastToken ().Line, self:GetLastToken ().Character)
				end
			else
				parameterType = GCompute.AST.Identifier ("number")
			end
			
			anonymousFunctionExpression:AddParameter (parameterType, parameterName)
		until not self:Accept (",")
	end
	if not self:Accept (")") then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	if self.CurrentToken ~= "{" then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	local blockStatement = self:StatementBlock ()
	if not blockStatement then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	
	self:CommitPosition ()
	anonymousFunctionExpression:SetStatement (blockStatement)
	return anonymousFunctionExpression
end

function self:ExpressionVariable ()
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