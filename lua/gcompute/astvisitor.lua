local self = {}
GCompute.ASTVisitor = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Process (blockStatement)
	self:ProcessRoot (blockStatement)
end

function self:ProcessRoot (blockStatement)
	self:VisitRoot (blockStatement)
	self:ProcessBlock (blockStatement)
end

function self:ProcessBlock (blockStatement)
	local ret = self:VisitBlock (blockStatement)
	blockStatement = ret or blockStatement

	for i = 1, blockStatement:GetStatementCount () do
		blockStatement:SetStatement (i, self:ProcessStatement (blockStatement:GetStatement (i)) or blockStatement:GetStatement (i))
	end
	
	return ret
end

function self:ProcessStatement (statement)
	if not statement then return end
	
	if statement:Is ("Block") then
		return self:ProcessBlock (statement)
	elseif statement:Is ("Expression") then
		return self:ProcessExpression (statement)
	end
	
	local ret = self:VisitStatement (statement)
	statement = ret or statement
	
	if statement:Is ("IfStatement") then
		for i = 1, statement:GetConditionCount () do
			statement:SetCondition (i, self:ProcessExpression (statement:GetCondition (i)) or statement:GetCondition (i))
			statement:SetStatement (i, self:ProcessStatement (statement:GetStatement (i)) or statement:GetStatement (i))
		end
		if statement:GetElseStatement () then
			statement:SetElseStatement (self:ProcessStatement (statement:GetElseStatement ()) or statement:GetElseStatement ())
		end
	elseif statement:Is ("RangeForLoop") then
		statement:SetLoopStatement (self:ProcessStatement (statement:GetLoopStatement ()) or statement:GetLoopStatement ())
	end
	
	return ret
end

function self:ProcessExpression (expression)
	if not expression then return end
	
	if expression:Is ("BinaryOperator") then
		expression:SetLeftExpression (self:ProcessExpression (expression:GetLeftExpression ()) or expression:GetLeftExpression ())
		expression:SetRightExpression (self:ProcessExpression (expression:GetRightExpression ()) or expression:GetRightExpression ())
	elseif expression:Is ("UnaryOperator") then
		expression:SetLeftExpression (self:ProcessExpression (expression:GetLeftExpression ()) or expression:GetLeftExpression ())
	elseif expression:Is ("FunctionCall") then
		expression:SetFunctionExpression (self:ProcessExpression (expression:GetFunctionExpression ()) or expression:GetFunctionExpression ())
		for i = 1, expression:GetArgumentCount () do
			expression:SetArgument (i, self:ProcessExpression (expression:GetArgument (i)) or expression:GetArgument (i))
		end
	end
	
	return self:VisitExpression (expression)
end

function self:VisitRoot (blockStatement)
end

function self:VisitBlock (blockStatement)
end

function self:VisitStatement (statement)
end

function self:VisitExpression (expression)
end