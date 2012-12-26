local self = {}
self.__Type = "NameIndex"
GCompute.AST.NameIndex = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.Identifier = nil
	
	self.ResolutionResults = GCompute.ResolutionResults ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.Identifier then
		self.Identifier:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.Identifier and self.Identifier:GetTypeArgumentList () then
		self.Identifier:GetTypeArgumentList ():ComputeMemoryUsage (memoryUsageReport)
	end
	
	self.ResolutionResults:ComputeMemoryUsage (memoryUsageReport)
	
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	local left, leftReference = self.LeftExpression:Evaluate (executionContext)
	if self.NameLookupType == GCompute.AST.NameLookupType.Value then
		return left:GetMember (self.Right.Name)
	else
		return left:GetMemberReference (self.Right.Name)
	end
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.Identifier
		end
		return nil
	end
end

function self:GetIdentifier ()
	return self.Identifier
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:GetTypeArgumentList ()
	if not self.Identifier then return end
	return self.Identifier:GetTypeArgumentList ()
end

function self:SetIdentifier (identifier)
	self.Identifier = identifier
	if self.Identifier then self.Identifier:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetTypeArgumentList (typeArgumentList)
	self.Identifier:SetTypeArgumentList (typeArgumentList)
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local identifier = self.Identifier and self.Identifier:ToString () or "[Nothing]"
	return leftExpression .. "." .. identifier
end

function self:ToTypeNode ()
	return self
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	
	if self:GetTypeArgumentList () then
		self:SetTypeArgumentList (self:GetTypeArgumentList ():Visit (astVisitor, ...) or self:GetTypeArgumentList ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end