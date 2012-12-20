local self = {}
self.__Type = "FunctionType"
GCompute.AST.FunctionType = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.TypeSystem = nil
	
	self.Name = "[Unknown Identifier]"
	
	self.ReturnTypeExpression = nil	
	self.ParameterList = GCompute.AST.ParameterList ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Name)
	
	if self.ReturnTypeExpression then
		self.ReturnTypeExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.ParameterList then
		self.ParameterList:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.ReturnTypeExpression
		elseif i == 2 then
			return self.ParameterList
		end
		return nil
	end
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetResolutionResult ()
	return GCompute.FunctionType (self:GetReturnTypeExpression ():GetResolutionResult (), self:GetParameterList ():ToParameterList ())
		:SetTypeSystem (self:GetTypeSystem ())
end

function self:GetReturnTypeExpression ()
	return self.ReturnTypeExpression
end

function self:GetTypeSystem ()
	return self.TypeSystem
end

function self:SetParameterList (parameterList)
	self.ParameterList = parameterList
	if parameterList then parameterList:SetParent (self) end
end

function self:SetReturnTypeExpression (returnTypeExpression)
	self.ReturnTypeExpression = returnTypeExpression
	if self.ReturnTypeExpression then self.ReturnTypeExpression:SetParent (self) end
end

function self:SetTypeSystem (typeSystem)
	self.TypeSystem = typeSystem
end

function self:ToString ()
	local returnTypeExpression = self.ReturnTypeExpression and self.ReturnTypeExpression:ToString () or "[Unknown Type]"
	
	return returnTypeExpression .. " " .. self:GetParameterList ():ToString ()
end

function self:Visit (astVisitor, ...)
	if self:GetReturnTypeExpression () then
		self:SetReturnTypeExpression (self:GetReturnTypeExpression ():Visit (astVisitor, ...) or self:GetReturnTypeExpression ())
	end
	
	if self:GetParameterList () then
		self:SetParameterList (self:GetParameterList ():Visit (astVisitor, ...) or self:GetParameterList ())
	end
	
	return astVisitor:VisitExpression (self, ...)
end