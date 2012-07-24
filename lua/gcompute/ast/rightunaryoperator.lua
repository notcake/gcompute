local self = {}
self.__Type = "RightUnaryOperator"
GCompute.AST.RightUnaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

local EvaluationFunctions =
{
	["default"] = function (self, executionContext, value) return value end,
	["++"] = function (self, executionContext, value) return value + 1 end,
	["--"] = function (self, executionContext, value) return value - 1 end
}

function self:ctor ()
	self.LeftExpression = nil
	
	self.Operator = "[Unknown Operator]"
	self.Precedence = 0
	
	self.EvaluationFunction = EvaluationFunctions.default
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local value, reference = self.LeftExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	reference:SetValue (value)
	
	return value
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetOperator ()
	return self.Operator
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetOperator (operator)
	self.Operator = operator
	
	self.EvaluationFunction = EvaluationFunctions [operator] or EvaluationFunctions.default
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Unknown Expression]"
	
	return leftExpression .. self.Operator
end