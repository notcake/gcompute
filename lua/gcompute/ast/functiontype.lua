local self = {}
self.__Type = "FunctionType"
GCompute.AST.FunctionType = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Name = "[Unknown Identifier]"
	
	self.ReturnTypeExpression = nil	
	self.ParameterList = GCompute.ParameterList ()
end

function self:AddParameter (parameterType, parameterName)
	self.ParameterList:AddParameter (GCompute.DeferredNameResolution (parameterType), parameterName or "[Unknown Identifier]")
	if parameterType then parameterType:SetParent (self) end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Name)
	self.ParameterList:ComputeMemoryUsage (memoryUsageReport, "Syntax Trees")
	
	if self.ReturnTypeExpression then
		self.ReturnTypeExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate ()
end

function self:GetParameterCount ()
	return self.ParameterList:GetParameterCount ()
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetParameterName (parameterId)
	return self.ParameterList:GetParameterName (parameterId)
end

function self:GetParameterType (parameterId)
	return self.ParameterList:GetParameterType (parameterId)
end

function self:GetReturnTypeExpression ()
	return self.ReturnTypeExpression
end

function self:SetParameterName (parameterId, parameterName)
	self.ParameterList:SetParameterName (parameterId, parameterName)
end

function self:SetParameterType (parameterId, parameterType)
	self.ParameterList:SetParameterType (parameterId, GCompute.DeferredNameResolution (parameterType))
	if parameterType then parameterType:SetParent (self) end
end

function self:SetReturnTypeExpression (returnTypeExpression)
	self.ReturnTypeExpression = returnTypeExpression
	if self.ReturnTypeExpression then self.ReturnTypeExpression:SetParent (self) end
end

function self:ToString ()
	local returnTypeExpression = self.ReturnTypeExpression and self.ReturnTypeExpression:ToString () or "[Unknown Type]"
	
	return returnTypeExpression .. " " .. self:GetParameterList ():ToString ()
end