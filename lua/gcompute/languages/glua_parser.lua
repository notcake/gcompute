local self = Parser

function self:ctor ()
end

-- Root
function self:Root ()
	local block = GCompute.AST.Block ()
	block:AddStatements (self:Sequence ())
	return block
end

-- Sequence
function self:Sequence ()
	self:AcceptWhitespaceAndNewlines ()
		
	local statements = {}
	while self:PeekType () ~= GCompute.Lexing.TokenType.EndOfFile and self:Peek () ~= "}" do
		local statement, accepted = self:Statement ()
		statements [#statements + 1] = statement
		if not statement and not accepted then
			statements [#statements + 1] = self:ExpectedItem ("statement")
			self:AdvanceToken ()
		end
		if self:Accept (",") and (self:PeekType () == GCompute.Lexing.TokenType.EndOfFile or self:Peek () == "}") then
			statements [#statements + 1] = GCompute.AST.Error ("Expected <statement> after ','.")
				:SetStartToken (self:GetLastToken ())
				:SetEndToken   (self:GetCurrentToken ())
		end
		
		self:AcceptWhitespaceAndNewlines ()
	end
	return statements
end

-- Statement
function self:Statement ()
	self:SavePosition ()
	self:AcceptType (GCompute.Lexing.TokenType.Newline)
	
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
		self:Accept (";")
		self:CommitPosition ()
		return statement, accepted
	end
	self:RestorePosition ()
	
	return nil
end

function self:StatementNull ()
	return nil, self:Accept (";")
end

function self:StatementIf ()
	if not self:Accept ("if") then return nil end
	
	local ifStatement = GCompute.AST.IfStatement ()
	ifStatement:SetStartToken (self:GetLastToken ())
	
	if not self:Accept ("(") then
		ifStatement:AddErrorMessage ("Expected '(' after 'if'.", self:GetCurrentToken ())
	end
	
	local condition = self:Expression () or self:ExpectedItem ("expression")
	if not self:Accept (")") then
		ifStatement:AddErrorMessage ("Expected ')' after condition <expression> in if statement.", self:GetCurrentToken ())
	end
	local statement = self:Statement ()
	ifStatement:AddCondition (condition, statement)
	
	self:AcceptWhitespaceAndNewlines ()
	while self:Accept ("elseif") do
		if not self:Accept ("(") then
			ifStatement:AddErrorMessage ("Expected '(' after 'elseif'.", self:GetCurrentToken ())
		end
		local condition = self:Expression () or self:ExpectedItem ("expression")
		if not self:Accept (")") then
			ifStatement:AddErrorMessage ("Expected ')' after elseif condition.", self:GetCurrentToken ())
		end
		local statement = self:Statement ()
		ifStatement:AddCondition (condition, statement)
		
		self:AcceptWhitespaceAndNewlines ()
	end
	self:AcceptWhitespaceAndNewlines ()
	if self:Accept ("else") then
		ifStatement:SetElseStatement (self:Statement ())
	end
	
	ifStatement:SetEndToken (self:GetLastToken ())
	return ifStatement
end

function self:StatementFor ()
	if not self:Accept ("for") then return nil end
	
	local forStatement = GCompute.AST.RangeForLoop ()
	forStatement:SetStartToken (self:GetLastToken ())
	
	if not self:Accept ("(") then
		forStatement:AddErrorMessage ("Expected '(' after 'for'.", self:GetCurrentToken ())
	end
	
	local loopVariable = self:ForVariable ()
	forStatement:SetLoopVariable (loopVariable)
	if not self:Accept ("=") then
		forStatement:AddErrorMessage ("Expected '=' after <identifier> in for loop.", self:GetCurrentToken ())
	end
	local startValue = self:Expression () or GCompute.AST.Error ("Expected <expression> after '=' in for loop expression.", self:GetCurrentToken ())
	if not self:Accept (",") then
		startValue:AddErrorMessage ("Expected ',' after <numeric-literal> in for loop expression.", self:GetCurrentToken ())
	end
	local endValue = self:Expression () or GCompute.AST.Error ("Expected <expression> after ',' in for loop expression.", self:GetCurrentToken ())
	if self:Accept (",") then
		local increment = self:Expression ()
		if not increment then
			forStatement:AddRange (startValue, endValue)
			forStatement:AddErrorMessage ("Expected <expression> after ',' in for loop expression.", self:GetCurrentToken ())
		else
			forStatement:AddRange (startValue, endValue, increment)
		end
	else
		forStatement:AddRange (startValue, endValue)
	end
	
	if not self:Accept (")") then
		forStatement:AddErrorMessage ("Expected ')' after expression in for loop.", self:GetCurrentToken ())
	end
	
	self:AcceptWhitespaceAndNewlines ()
	local statement = self:Statement ()
	forStatement:SetBody (statement)
	
	forStatement:SetEndToken (self:GetLastToken ())
	return forStatement
end

function self:StatementForEach ()
	if not self:Accept ("foreach") then return nil end
	
	local forEachStatement = GCompute.AST.IteratorForLoop ()
	forEachStatement:SetStartToken (self:GetLastToken ())
	
	if not self:Accept ("(") then
		forEachStatement:AddErrorMessage ("Expected '(' after 'foreach'.", self:GetCurrentToken ())
	end
	
	forEachStatement:AddVariables (self:ForEachVariables ())
	if not self:Accept ("=") then
		forEachStatement:AddErrorMessage ("Expected '=' after variable in foreach loop.", self:GetCurrentToken ())
	end
	local iteratorExpression = self:Expression () or GCompute.AST.Error ("Expected <expression> after '=' in foreach loop.", self:GetCurrentToken ())
	forEachStatement:SetIteratorExpression (iteratorExpression)
	
	if not self:Accept (")") then
		forEachStatement:AddErrorMessage ("Expected ')' after <expression> in foreach loop.", self:GetCurrentToken ())
	end
	
	self:AcceptWhitespaceAndNewlines ()
	local statement = self:Statement ()
	forEachStatement:SetBody (statement)
	
	forEachStatement:SetEndToken (self:GetLastToken ())
	return forEachStatement
end

function self:ForVariable ()
	local variable = nil
	if self:Accept ("local") then
		variable = GCompute.AST.VariableDeclaration ()
		variable:SetStartToken (self:GetLastToken ())
		variable:SetLocal (true)
		
		local identifier = self:AcceptType (GCompute.Lexing.TokenType.Identifier) 
		variable:SetName (identifier)
		if not identifier then
			variable:AddErrorMessage ("Expected <identifier> after 'local' in for loop expression.", self:GetCurrentToken ())
		end
		if self:Accept (":") then
			local typeExpression = self:Type () or GCompute.AST.Error ("Expected <type> after ':' in variable declaration in for loop expression.", self:GetCurrentToken ())
			variable:SetTypeExpression (typeExpression)
		else
			variable:SetAuto (true)
		end
	else
		variable = self:QualifiedIdentifier ()
	end
	
	variable:SetEndToken (self:GetLastToken ())
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
			variable:SetStartToken (self:GetCurrentToken ())
			variable:SetLocal (isLocal)
			identifier = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
			variable:SetName (identifier)
			
			if self:Accept (":") then
				local typeExpression = self:Type () or GCompute.AST.Error ("Expected <type> after ':' in variable declaration in foreach loop.", self:GetCurrentToken ())
				variable:SetTypeExpression (typeExpression)
			end
			
			variable:SetEndToken (self:GetLastToken ())
			variables [#variables + 1] = variable
		else
			identifier = self:QualifiedIdentifier ()
			
			if self:Accept (":") then
				local variableType = self:Type () or GCompute.AST.Error ("Expected <type> after ':' in variable declaration in foreach loop.", self:GetCurrentToken ())
				identifier:AddTargetType (variableType)
			end
			
			variables [#variables + 1] = identifier
		end
		if not identifier then
			variables [#variables + 1] = GCompute.AST.Error ("Expected <identifier> in foreach expression.", self:GetCurrentToken ())
		end
	until not self:Accept (",")
	
	return variables
end

function self:StatementWhile ()
	if not self:Accept ("while") then return nil end
	
	local whileStatement = GCompute.AST.WhileLoop ()
	whileStatement:SetStartToken (self:GetLastToken ())
	
	if not self:Accept ("(") then
		whileStatement:AddErrorMessage ("Expected '(' after 'while'.", self:GetCurrentToken ())
	end
	
	local condition = self:StatementVariableDeclaration () or self:Expression ()
	if not condition then
		condition = GCompute.AST.Error ("Expected <variable-declaration> or <expression> after '(' in while loop.", self:GetCurrentToken ())
	elseif condition:Is ("VariableDeclaration") then
		if not condition:GetRightExpression () then
			condition:AddErrorMessage ("<variable-declaration> in while loop must assign a value to the variable.", self:GetCurrentToken ())
		end
	end
	
	whileStatement:SetCondition (condition)
	
	if not self:Accept (")") then
		whileStatement:AddErrorMessage ("Expected ')' after <expression> in while loop.", self:GetCurrentToken ())
	end
	
	self:AcceptWhitespaceAndNewlines ()
	local statement = self:Statement ()
	whileStatement:SetBody (statement)
	
	whileStatement:SetEndToken (self:GetLastToken ())
	return whileStatement
end

function self:StatementSwitch ()
	if not self:Accept ("switch") then return end
	
	local switchStatement = GCompute.AST.SwitchStatement ()
	switchStatement:SetStartToken (self:GetLastToken ())
	
	if not self:Accept ("(") then
		switchStatement:AddErrorMessage ("Expected '(' after 'switch'.", self:GetCurrentToken ())
	end

	local switchExpression = self:Expression () or GCompute.AST.Error ("Expected <expression> after '(' in switch statement.", self:GetCurrentToken ())
	switchStatement:SetSwitchExpression (switchExpression)
	
	if not self:Accept (")") then
		switchStatement:AddErrorMessage ("Expected ')' after <expression> in switch statement.", self:GetCurrentToken ())
	end
	
	if not self:Accept ("{") then
		switchStatement:AddErrorMessage ("Expected '{' after expression in switch statement.", self:GetCurrentToken ())
	end
	
	if not self:AcceptAST () then
		switchStatement:AddErrorMessage ("Expected <pre-parsed ast> after '{' in switch statement.", self:GetCurrentToken ())
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
			switchStatement:AddErrorMessage ("Statement is not part of a case body in switch statement. (" .. GCompute.String.EscapeWhitespace (statement:ToString ()) .. ").", statement:GetStartToken (), statement:GetEndToken ())
		end
	end
	if caseExpression or body then
		switchStatement:AddCase (caseExpression, body)
	end
	
	if not self:Accept ("}") then
		switchStatement:AddErrorMessage ("Expected '}' to close switch statement body.", self:GetCurrentToken ())
	end
	
	switchStatement:SetEndToken (self:GetLastToken ())
	return switchStatement
end

function self:StatementControl ()
	if self:Accept ("break") then
		return GCompute.AST.Break ()
			:SetStartToken (self:GetLastToken ())
			:SetEndToken (self:GetLastToken ())
	elseif self:Accept ("continue") then
		return GCompute.AST.Continue ()
			:SetStartToken (self:GetLastToken ())
			:SetEndToken (self:GetLastToken ())
	elseif self:Accept ("return") then
		local returnStatement = GCompute.AST.Return ()
		returnStatement:SetStartToken (self:GetLastToken ())
		
		self:AcceptWhitespaceAndNewlines ()
		if self:Peek () ~= ";" and self:Peek () ~= "}" then
			returnStatement:SetReturnExpression (self:Expression ())
		end
		
		returnStatement:SetEndToken (self:GetLastToken ())
		return returnStatement
	end
	return nil
end

function Parser:StatementTypeDeclaration ()
	if true then return nil end
	
	self:SavePosition ()
	self:ChompModifiers ()
	if self.KeywordClassifier:GetKeywordType (self:Peek ()) ~= GCompute.Lexing.KeywordType.DataType then
		self:ClearModifiers ()
		self:RestorePosition ()
		return false
	end
	local DataType = self:Peek ()
	local Type = self:Type ()
	if not Type then
		self:ClearModifiers ()
		self:RestorePosition ()
		return false
	end
	self:PushParseItem (DataType)
	self:AddParseItem ("mod"):AddRange (self.Modifiers)
	self:ClearModifiers ()
	
	local TypeName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
	if TypeName then
		self:AddParseItem ("name"):Add (TypeName)
	end
	if DataType == "enum" then
		self:PushParseItem ("values")
		self:Accept ("{")
		repeat
			local Identifier = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
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
	while self:AcceptType (GCompute.Lexing.TokenType.Identifier) do
		ExpectingIdentifier = false
		self:PushParseItem ("var")
		self:AddParseItem (self.LastAccepted)
		if self:Accept ("=") then
			local Expression = self:Expression ()
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
	
	local blockStatement = nil
	if self:AcceptAST () then
		blockStatement = self:GetLastToken ().AST
		blockStatement:SetStartToken (self:GetLastToken ())
	else
		blockStatement = GCompute.AST.Error ("Parser bug: Expected <pre-parsed block> after '{'.", self:GetCurrentToken ())
	end
	
	self:Accept ("}")
	
	blockStatement:SetEndToken (self:GetLastToken ())
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
	
	self:SavePosition ()
	local functionDeclaration = GCompute.AST.FunctionDeclaration ()
	functionDeclaration:SetStartToken (self:GetLastToken ())
	
	local returnType = nil
	local typeExpression = nil
	local functionName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
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
			
			typeExpression = returnType
			returnType = nil
			functionName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
			self:Accept ("(")
		else
			-- type
			--     type:functionName (
			--     functionName (
			self:SavePosition ()
			functionName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
			if self:Accept ("(") then
				-- type functionName (
				self:CommitPosition ()
			else
				-- type type:functionName (
				self:RestorePosition ()
				typeExpression = self:Type ()
				self:Accept (":")
				functionName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
				self:Accept ("(")
			end
		end
	else
		-- functionName (
		self:CommitPosition ()
	end
	
	functionDeclaration:SetReturnTypeExpression (returnType or GCompute.AST.Identifier ("void"))
	functionDeclaration:SetName (functionName)
	if typeExpression then
		functionDeclaration:SetTypeExpression (typeExpression)
		functionDeclaration:SetMemberFunction (true)
	end
	
	functionDeclaration:GetParameterList ():SetStartToken (self:GetLastToken ())
	
	if self:Peek () ~= ")" then
		repeat
			local parameterName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
			local parameterType = nil
			if self:Accept (":") then
				parameterType = self:Type () or GCompute.AST.Error ("Expected <type> after ':' in argument list of function declaration.", self:GetCurrentToken ())
			else
				parameterType = GCompute.TypeParser ("Expression2.number"):Root ()
			end
			
			functionDeclaration:GetParameterList ():AddParameter (parameterType, parameterName)
		until not self:Accept (",")
	end
	if not self:Accept (")") then
		functionDeclaration:AddErrorMessage ("Expected ')' to close argument list in function declaration.", self:GetCurrentToken ())
	end
	functionDeclaration:GetParameterList ():SetEndToken (self:GetLastToken ())
	
	self:AcceptWhitespaceAndNewlines ()
	local blockStatement = self:StatementBlock ()
	if not blockStatement then
		self:Accept (";")
	end
	functionDeclaration:SetBody (blockStatement)
	
	functionDeclaration:SetEndToken (self:GetLastToken ())
	return functionDeclaration
end

function self:StatementVariableDeclaration ()
	-- local variableName
	-- local variableName = expression
	-- local variableName:typeName
	-- local variableName:typeName = expression	
	if not self:Accept ("local") then return end
	
	local variableDeclaration = GCompute.AST.VariableDeclaration ()
	variableDeclaration:SetStartToken (self:GetLastToken ())
	
	local variableName = self:AcceptType (GCompute.Lexing.TokenType.Identifier)
	if not variableName then
		variableDeclaration:AddErrorMessage ("Expected <identifier> after 'local' in variable declaration.", self:GetCurrentToken ())
	end
	
	variableDeclaration:SetLocal (true)
	
	local typeExpression = nil
	local rightExpression = nil
	
	if self:Accept (":") then
		typeExpression = self:Type () or GCompute.AST.Error ("Expected <type> after ':' in variable declaration.", self:GetCurrentToken ())
	else
		variableDeclaration:SetAuto (true)
	end
	
	if self:Accept ("=") then
		rightExpression = self:Expression () or GCompute.AST.Error ("Expected <expression> after '=' in variable declaration.", self:GetCurrentToken ())
	end
	
	variableDeclaration:SetTypeExpression (typeExpression)
	variableDeclaration:SetName (variableName)
	variableDeclaration:SetRightExpression (rightExpression)
	
	variableDeclaration:SetEndToken (self:GetLastToken ())
	return variableDeclaration
end

function self:StatementLabel ()
	local startToken = self:GetCurrentToken ()
	
	if self:AcceptAndSave ("default") then
		if self:Accept (":") or self:Accept (",") then
			self:CommitPosition ()
			return GCompute.AST.CaseLabel ()
				:SetStartToken (startToken)
				:SetEndToken (self:GetLastToken ())
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
	caseLabel:SetStartToken (startToken)
	caseLabel:SetEndToken (self:GetLastToken ())
	
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
		local ternaryExpression = GCompute.AST.TernaryExpression ()
		ternaryExpression:SetStartToken (leftExpression:GetStartToken ())
		
		local trueExpression = self:Expression ()
		
		if not self:Accept (":") then
			ternaryExpression:AddErrorMessage ("Expected ':' after <expression> in <ternary-expression>.", self:GetCurrentToken ())
		end
		local falseExpression = self:Expression ()
		ternaryExpression:SetCondition (leftExpression)
		ternaryExpression:SetTrueExpression (trueExpression)
		ternaryExpression:SetFalseExpression (falseExpression)
		
		ternaryExpression:SetEndToken (self:GetLastToken ())
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
	return self:RecurseLeft (self.ExpressionEquality, booleanAnd)
end

local equality = { ["=="] = true, ["!="] = true }
function self:ExpressionEquality ()
	return self:RecurseLeft (self.ExpressionComparison, equality)
end

local comparison = { ["<"] = true, [">"] = true, ["<="] = true, [">="] = true }
function self:ExpressionComparison ()
	return self:RecurseLeft (self.ExpressionBinaryOr, comparison)
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
	return self:RecurseLeft (self.ExpressionBitShift, binaryXor)
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
	local startToken = self:GetLastToken ()
	
	local typeExpression = self:Type ()
	if not typeExpression then
		self:RestorePosition ()
		return self:ExpressionUnary ()
	end
	if not self:Accept (")") then
		self:RestorePosition ()
		return self:ExpressionUnary ()
	end
	
	local typeCastExpression = GCompute.AST.TypeCast ()
	typeCastExpression:SetStartToken (startToken)
	
	typeCastExpression:SetTypeExpression (typeExpression)
	
	local rightExpression = self:ExpressionTypeCast ()
	if not rightExpression then
		self:RestorePosition ()
		return self:ExpressionUnary ()
	end
	
	-- If the right expression is an argument list with 0 or > 1 arguments, then it should be rejected.
	-- Otherwise if we find that the contents are indeed not a type, fix it in the semantic analysis stage.
	typeCastExpression:SetRightExpression (rightExpression)
	self:CommitPosition ()
	
	typeCastExpression:SetEndToken (self:GetLastToken ())
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
		unaryExpression:SetStartToken (leftExpression and leftExpression:GetStartToken ())
		unaryExpression:SetEndToken (self:GetLastToken ())
		
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
	newExpression:SetStartToken (self:GetLastToken ())
	
	local typeExpression = self:Type () or GCompute.AST.Error ("Expected <type> after 'new'.", self:GetCurrentToken ())
	
	if typeExpression:Is ("FunctionType") then
		newExpression:SetLeftExpression (typeExpression:GetReturnTypeExpression ())
		self:SetCurrentToken (typeExpression:GetParameterList ():GetStartToken ())
	else
		newExpression:SetLeftExpression (typeExpression)
		newExpression:AddErrorMessage ("<new-expression> is missing parentheses or is too complicated to parse (try adding parentheses).", typeExpression:GetStartToken ())
		return newExpression
	end
	
	if not self:Accept ("(") then
		newExpression:AddErrorMessage ("Expected '(' after " .. self:GetLastPretty () .. ", got " .. self:GetCurrentPretty () .. " in <new-expression>.", self:GetCurrentToken ())
	end
	
	local arguments = self:List (self.Expression)
	newExpression:GetArgumentList ():AddArguments (arguments)
	if not self:Accept (")") then
		newExpression:AddErrorMessage ("Expected ')' after " .. self:GetLastPretty () .. ", got " .. self:GetCurrentPretty () .. " in <new-expression>.", self:GetCurrentToken ())
	end
	
	newExpression:SetEndToken (self:GetLastToken ())
	return newExpression
end

function self:ExpressionFunctionCallOrArrayIndexOrIndex ()
	local leftExpression = self:ExpressionParentheses ()
	if not leftExpression then return nil end
	
	-- derp ():herp () [aaa, herp ()]:derp () ()
	local nextCharacter = nil
	local matched = true
	repeat
		self:AcceptWhitespaceAndNewlines ()
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
	functionCallExpression:SetStartToken (leftExpression:GetStartToken ())
	
	self:AcceptWhitespaceAndNewlines ()
	
	functionCallExpression:SetLeftExpression (leftExpression)
	if not self:Accept (")") then
		functionCallExpression:GetArgumentList ():AddArguments (self:List (self.Expression))
		
		self:AcceptWhitespaceAndNewlines ()
		
		if not self:Accept (")") then
			functionCallExpression:AddErrorMessage ("Expected ')' to close function call argument list, got " .. self:GetCurrentPretty () .. ".", self:GetCurrentToken ())
		end
	end
	
	functionCallExpression:SetEndToken (self:GetLastToken ())
	return functionCallExpression
end

function self:ExpressionMemberFunctionCall (leftExpression)
	if not self:AcceptAndSave (":") then return leftExpression end
	local unqualifiedIdentifier = self:UnqualifiedIdentifier ()
	local identifierToken = self:GetCurrentToken ()
	
	local memberFunctionCallExpression = GCompute.AST.MemberFunctionCall ()
	memberFunctionCallExpression:SetStartToken (leftExpression:GetStartToken ())
	memberFunctionCallExpression:SetLeftExpression (leftExpression)
	memberFunctionCallExpression:SetIdentifier (unqualifiedIdentifier)
	
	local noLeftParenthesis = not self:Accept ("(")
	local leftParenthesisToken = self:GetCurrentToken ()
	
	local noRightParenthesis = false
	if not self:Accept (")") then
		memberFunctionCallExpression:GetArgumentList ():AddArguments (self:List (self.Expression))
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
	
	if not unqualifiedIdentifier then
		memberFunctionCallExpression:AddErrorMessage ("Expected <identifier> after ':' in member function call.", identifierToken)
	end
	if noLeftParenthesis then
		memberFunctionCallExpression:AddErrorMessage ("Expected '(' to start member function call argument list.", leftParenthesisToken)
	end
	if noRightParenthesis then
		memberFunctionCallExpression:AddErrorMessage ("Expected ')' to close member function call argument list.", self:GetCurrentToken ())
	end
	
	self:CommitPosition ()
	
	memberFunctionCallExpression:SetEndToken (self:GetLastToken ())
	return memberFunctionCallExpression
end

function self:ExpressionArrayIndex (leftExpression)
	if not self:Accept ("[") then return leftExpression end
	
	local arrayIndexExpression = GCompute.AST.ArrayIndex ()
	arrayIndexExpression:SetStartToken (leftExpression:GetStartToken ())
	
	arrayIndexExpression:SetLeftExpression (leftExpression)
	if not self:Accept ("]") then
		arrayIndexExpression:GetArgumentList ():AddArguments (self:List (self.Expression))
		if not self:Accept ("]") then
			arrayIndexExpression:AddErrorMessage ("Expected ']' to close index argument list.", self:GetCurrentToken ())
		end
	end
	
	arrayIndexExpression:SetEndToken (self:GetLastToken ())
	return arrayIndexExpression
end

function self:ExpressionIndex (leftExpression)
	if not self:Accept (".") then return leftExpression end
	
	local nameIndexExpression = GCompute.AST.NameIndex ()
	nameIndexExpression:SetStartToken (leftExpression:GetStartToken ())
	
	nameIndexExpression:SetLeftExpression (leftExpression)
	local identifier = self:UnqualifiedIdentifier () or GCompute.AST.Error ("Expected <identifier> after '.' in name index expression.", self:GetCurrentToken ())
	nameIndexExpression:SetIdentifier (identifier)
	
	nameIndexExpression:SetEndToken (self:GetLastToken ())
	return nameIndexExpression
end

function self:ExpressionParentheses ()
	if not self:AcceptAndSave ("(") then
		return self:ExpressionAnonymousFunction ()
	end
	
	local leftParenthesisToken = self:GetLastToken ()
	
	local innerExpression = self:Expression () or self:ExpectedItem ("expression")
	if not self:Accept (")") then
		innerExpression:AddErrorMessage ("Expected ')' to close '(' at line " .. (leftParenthesisToken.Line + 1) .. ", char " .. (leftParenthesisToken.Character + 1) .. ".", self:GetCurrentToken ())
	end
	self:CommitPosition ()
	return innerExpression
end

function self:ExpressionAnonymousFunction ()
	self:SavePosition ()
	local returnType = self:Type ()
	if not returnType or not returnType:Is ("FunctionType") then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	
	local anonymousFunctionExpression = GCompute.AST.AnonymousFunction ()
	anonymousFunctionExpression:SetStartToken (returnType:GetStartToken ())
	
	anonymousFunctionExpression:SetReturnTypeExpression (returnType:GetReturnTypeExpression ())
	anonymousFunctionExpression:SetParameterList (returnType:GetParameterList ())
	
	self:AcceptWhitespaceAndNewlines ()
	if self:Peek () ~= "{" then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	local blockStatement = self:StatementBlock ()
	if not blockStatement then
		self:RestorePosition ()
		return self:ExpressionVariable ()
	end
	
	self:CommitPosition ()
	anonymousFunctionExpression:SetBody (blockStatement)
	anonymousFunctionExpression:SetEndToken (blockStatement:GetEndToken ())
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
		local booleanLiteral = GCompute.AST.BooleanLiteral (self:GetLastToken ().Value)
		booleanLiteral:SetStartToken (self:GetLastToken ())
		booleanLiteral:SetEndToken (self:GetLastToken ())
		return booleanLiteral
	end
	return nil
end

function self:ExpressionNumericLiteral ()
	if self:AcceptType (GCompute.Lexing.TokenType.Number) then
		local numericLiteral = GCompute.AST.NumericLiteral (self:GetLastToken ().Value)
		numericLiteral:SetStartToken (self:GetLastToken ())
		numericLiteral:SetEndToken (self:GetLastToken ())
		return numericLiteral
	end
	return nil
end

function self:ExpressionStringLiteral ()
	local stringToken = self:AcceptType (GCompute.Lexing.TokenType.String)
	if stringToken then
		local stringLiteral = GCompute.AST.StringLiteral (stringToken)
		stringLiteral:SetStartToken (self:GetLastToken ())
		stringLiteral:SetEndToken (self:GetLastToken ())
		return stringLiteral
	end
	return nil
end

function self:Type ()
	return self:IndexOrParametricIndexOrArrayOrFunction ()
end

local validOperators =
{
	["."] = true,
	["<"] = true,
	["["] = true,
	["("] = true
}
function self:IndexOrParametricIndexOrArrayOrFunction ()
	local leftExpression = self:UnqualifiedIdentifier ()
	if not leftExpression then return nil end
	
	local nextOperator = self:Peek ()
	while validOperators [nextOperator] do
		self:Accept (nextOperator)
		
		if nextOperator == "." then
			local nameIndex = GCompute.AST.NameIndex ()
			nameIndex:SetStartToken (leftExpression:GetStartToken ())
			
			nameIndex:SetLeftExpression (leftExpression)
			local unqualifiedIdentifier = self:UnqualifiedIdentifier () or GCompute.AST.Error ("Expected <identifier> after '.', got " .. self:Peek (), self:GetCurrentToken ())
			
			nameIndex:SetIdentifier (unqualifiedIdentifier)
			leftExpression = nameIndex
		elseif nextOperator == "(" then
			local functionType = GCompute.AST.FunctionType ()
			functionType:SetStartToken (leftExpression:GetStartToken ())
			functionType:SetReturnTypeExpression (leftExpression)
			
			functionType:GetParameterList ():SetStartToken (self:GetLastToken ())
			
			if self:Peek () ~= ")" then
				repeat
					local parameterName = nil
					local parameterType = self:Type ()
					
					if not parameterType then
						functionType:AddErrorMessage ("Expected <type> after '(' in function type.", self:GetCurrentToken ())
						break
					end
					if self:Accept (":") then
						parameterName = parameterType
						parameterType = self:Type ()
						if not parameterType then
							functionType:AddErrorMessage ("Expected <type> after ':' in argument list of function type.", self:GetCurrentToken ())
						end
					else
						local possibleType = self:Type ()
						if possibleType then
							parameterName = parameterType
							parameterType = possibleType
						end
					end
					if parameterName and not parameterName:Is ("Identifier") then
						functionType:AddErrorMessage ("Parameter name cannot be a qualified identifier.", self:GetCurrentToken ())
					end
					
					functionType:GetParameterList ():AddParameter (parameterType, parameterName and parameterName:ToString () or nil)
				until not self:Accept (",")
			end
			if not self:Accept (")") then
				functionType:AddErrorMessage ("Expected ')' to close argument list in function type.", self:GetCurrentToken ())
			end
			functionType:GetParameterList ():SetEndToken (self:GetLastToken ())
			leftExpression = functionType
		else
			leftExpression:AddErrorMessage ("Unhandled operator in type (" .. nextOperator .. ")", self:GetCurrentToken ())
		end
		nextOperator = self:Peek ()
	end
	
	leftExpression:SetEndToken (self:GetLastToken ())
	return leftExpression
end

function self:QualifiedIdentifier ()
	return self:IndexOrParametricIndexOrArrayOrFunction ()
end

function self:UnqualifiedIdentifier ()
	if not self:AcceptType (GCompute.Lexing.TokenType.Identifier) then return nil end
	return GCompute.AST.Identifier (self:GetLastToken ().Value)
		:SetStartToken (self:GetLastToken ())
		:SetEndToken (self:GetLastToken ())
end