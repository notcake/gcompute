local self = {}
self.__Type = "LeftUnaryOperator"
GCompute.AST.LeftUnaryOperator = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.RightExpression = nil
	
	self.Operator = "[Unknown Operator]"
	self.Precedence = 0
	
	self.FunctionCall = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	memoryUsageReport:CreditString ("Syntax Trees", self.Operator)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local value, reference = self.RightExpression:Evaluate (executionContext)
	
	value = self:EvaluationFunction (executionContext, value, reference)
	
	return value
end

function self:ExecuteAsAST (astRunner, state)
	if not self.FunctionCall then
		ErrorNoHalt (self:ToString () .. "\n")
	end
	self.FunctionCall:ExecuteAsAST (astRunner, state)
end

function self:GetChildEnumerator ()
	return GLib.SingleValueEnumerator (self.RightExpression)
end

function self:GetOperator ()
	return self.Operator
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:SetOperator (operator)
	self.Operator = operator
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:ToString ()
	local rightExpression = self.RightExpression and self.RightExpression:ToString () or "[Unknown Expression]"
	
	return self.Operator .. rightExpression
end

function self:Visit (astVisitor, ...)
	if self:GetRightExpression () then
		self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end