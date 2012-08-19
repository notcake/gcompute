local self = {}
self.__Type = "StringLiteral"
GCompute.AST.StringLiteral = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (str)
	self.String = str
	
	self.IsConstant = true
	self.IsCached = true
	self.CachedValue = self.String
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self)
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	return self.String
end

function self:ExecuteAsAST (astRunner, state)
	-- Discard StringLiteral
	astRunner:PopNode ()
	
	astRunner:PushValue (self.String)
end

function self:ToString ()
	return "\"" .. GCompute.String.Escape (self.String) .. "\""
end

function self:Visit (astVisitor, ...)
	return astVisitor:VisitExpression (self, ...)
end