local self = {}
self.__Type = "BinaryAssignmentOperator"
GCompute.AST.BinaryAssignmentOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.BinaryOperator)

function self:ctor ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local left, leftReference = self.Left:Evaluate (executionContext)
	local right, rightReference = self.Right:Evaluate (executionContext)
	
	local value = self:EvaluationFunction (executionContext, left, right, leftReference, rightReference)
	leftReference:SetValue (value)
	
	return value, leftReference
end

function self:ExecuteAsAST (astRunner, state)
	self.AssignmentPlan:ExecuteAsAST (astRunner, self, state)
end