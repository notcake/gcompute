local self = {}
GCompute.ASTVisitor = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement, callback)
end

function self:ProcessRoot (blockStatement, callback, ...)
	callback = callback or GCompute.NullCallback

	self:VisitRoot (blockStatement, ...)
	blockStatement:Visit (self, ...)
	
	callback ()
end

function self:ProcessStatement (statement, ...)
	if not statement then return end
	
	if statement:Is ("Block") then
		return blockStatement:Visit (self, ...)
	elseif statement:Is ("Expression") then
		return statement:Visit (self, ...)
	end
	
	local ret = self:VisitStatement (statement, ...)
	statement = ret or statement
	
	if statement:Is ("IfStatement") then
		statement:Visit (self, ...)
	elseif statement:Is ("RangeForLoop") then
		statement:Visit (self, ...)
	elseif statement:Is ("IteratorForLoop") then
		statement:SetBody (self:ProcessStatement (statement:GetBody (), ...) or statement:GetBody ())
	elseif statement:Is ("WhileLoop") then
		statement:SetCondition (self:ProcessStatement (statement:GetCondition (), ...) or statement:GetCondition ())
		statement:SetBody (self:ProcessStatement (statement:GetBody (), ...) or statement:GetBody ())
	elseif statement:Is ("FunctionDeclaration") then
		statement:SetBody (self:ProcessStatement (statement:GetBody (), ...) or statement:GetBody ())
	end
	
	return ret
end

function self:ProcessExpression (expression, ...)
	if not expression then return end
	
	if expression:Is ("BinaryOperator") then
		return expression:Visit (self, ...)
	elseif expression:Is ("UnaryOperator") then
		expression:SetLeftExpression (self:ProcessExpression (expression:GetLeftExpression (), ...) or expression:GetLeftExpression ())
	elseif expression:Is ("FunctionCall") then
		return expression:Visit (self, ...)
	elseif expression:Is ("MemberFunctionCall") then
		return expression:Visit (self, ...)
	elseif expression:Is ("NameIndex") then
		expression:SetLeftExpression (self:ProcessExpression (expression:GetLeftExpression (), ...) or expression:GetLeftExpression ())
	end
	
	return self:VisitExpression (expression, ...)
end

function self:VisitRoot (blockStatement, ...)
end

function self:VisitBlock (blockStatement, ...)
end

function self:VisitStatement (statement, ...)
end

function self:VisitExpression (expression, ...)
end