local self = {}
self.__Type = "Identifier"
GCompute.AST.Identifier = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor (name)
	self.Name = name
	self.TypeArgumentList = nil
	
	self.ResolutionResults = GCompute.ResolutionResults ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Name)
	
	if self.TypeArgumentList then
		self.TypeArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	
	self.ResolutionResults:ComputeMemoryUsage (memoryUsageReport)
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	self.VariableReadPlan:ExecuteAsAST (astRunner, self, state)
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

function self:GetName ()
	return self.Name
end

function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:SetName (name)
	self.Name = name
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
	if self.TypeArgumentList then self.TypeArgumentList:SetParent (self) end
end

function self:ToString ()
	local identifier = self.Name or "[Nothing]"
	if self.TypeArgumentList then
		identifier = identifier .. " " .. self.TypeArgumentList:ToString ()
	end
	return identifier
end

function self:ToTypeNode ()
	return self
end

function self:Visit (astVisitor, ...)
	if self:GetTypeArgumentList () then
		self:SetTypeArgumentList (self:GetTypeArgumentList ():Visit (astVisitor, ...) or self:GetTypeArgumentList ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end