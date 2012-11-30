local self = {}
self.__Type = "Break"
GCompute.AST.Break = GCompute.AST.MakeConstructor (self, GCompute.AST.Control)

function self:ctor ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	executionContext:Break ()
end

function self:ExecuteAsAST (astRunner)
	astRunner:PopNode ()
	
	executionContext:Break ()
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:ToString ()
	return "break"
end

function self:Visit (astVisitor, ...)
	return astVisitor:VisitStatement (self, ...)
end