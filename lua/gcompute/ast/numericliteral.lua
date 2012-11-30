local self = {}
self.__Type = "NumericLiteral"
GCompute.AST.NumericLiteral = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (num)
	self.Number = tonumber (num)
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.Number
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	return memoryUsageReport
end

function self:Evaluate ()
	return self.Number
end

function self:ExecuteAsAST (astRunner, state)
	-- Discard NumericLiteral
	astRunner:PopNode ()
	
	astRunner:PushValue (self.Number)
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:GetNumber ()
	return self.Number
end

function self:SetNumber (num)
	self.Number = num
end

function self:ToString ()
	return tostring (self.Number)
end

function self:Visit (astVisitor, ...)
	return astVisitor:VisitExpression (self, ...)
end