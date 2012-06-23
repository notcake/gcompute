local self = {}
GCompute.ASTVisitor = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Process (blockStatement, callback)
	callback = callback or GCompute.NullCallback

	self:ProcessRoot (blockStatement)
	callback ()
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
			statement:SetCondition (i, self:ProcessStatement (statement:GetCondition (i)) or statement:GetCondition (i))
			statement:SetConditionBody (i, self:ProcessStatement (statement:GetConditionBody (i)) or statement:GetConditionBody (i))
		end
		if statement:GetElseStatement () then
			statement:SetElseStatement (self:ProcessStatement (statement:GetElseStatement ()) or statement:GetElseStatement ())
		end
	elseif statement:Is ("RangeForLoop") then
		statement:SetBody (self:ProcessStatement (statement:GetBody ()) or statement:GetBody ())
	elseif statement:Is ("IteratorForLoop") then
		statement:SetBody (self:ProcessStatement (statement:GetBody ()) or statement:GetBody ())
	elseif statement:Is ("WhileLoop") then
		statement:SetCondition (self:ProcessStatement (statement:GetCondition ()) or statement:GetCondition ())
		statement:SetBody (self:ProcessStatement (statement:GetBody ()) or statement:GetBody ())
	elseif statement:Is ("FunctionDeclaration") then
		statement:SetBody (self:ProcessStatement (statement:GetBody ()) or statement:GetBody ())
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
		expression:SetLeftExpression (self:ProcessExpression (expression:GetLeftExpression ()) or expression:GetLeftExpression ())
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