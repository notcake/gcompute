local self = {}
self.__Type = "BinaryAssignmentOperator"
GCompute.AST.BinaryAssignmentOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.BinaryOperator)

function self:ctor ()
end

function self:Evaluate (executionContext)
	local left, leftReference = self.Left:Evaluate (executionContext)
	local right, rightReference = self.Right:Evaluate (executionContext)
	
	local value = self:EvaluationFunction (executionContext, left, right, leftReference, rightReference)
	leftReference:SetValue (value)
	
	return value, leftReference
end

function self:SetOperator (operator)
	self.__base.SetOperator (self, operator:sub (1, 1))
	self.Operator = operator
end