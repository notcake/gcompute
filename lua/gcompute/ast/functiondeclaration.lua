local self = {}
self.__Type = "FunctionDeclaration"
GCompute.AST.FunctionDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Name = "[Unknown Identifier]"
	
	self.ReturnTypeExpression = nil	
	
	self.MemberFunction = false
	self.TypeExpression = nil
	
	self.ParameterList = GCompute.ParameterList ()
	
	self.Body = nil
	
	self.FunctionDefinition = nil
	
	self.NamespaceDefinition = nil
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
	if self.TypeExpression then
		self.TypeExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.Body then
		self.Body:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.FunctionDefinition then
		self.FunctionDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.NamespaceDefinition then
		self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate ()
end

function self:GetBody ()
	return self.Body
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			if not self.TypeExpression then i = 2 end
			return self.ReturnTypeExpression
		elseif i == 2 then
			return self.TypeExpression
		elseif i == 3 then
			return self.Body
		else
			local parameterType = self.ParameterList:GetParameterType (i - 3)
			if not parameterType then return nil end
			
			if parameterType:IsDeferredNameResolution () then
				return parameterType:GetParsedName ()
			else
				return parameterType
			end
		end
		return nil
	end
end

function self:GetFunctionDefinition ()
	return self.FunctionDefinition
end

function self:GetName ()
	return self.Name
end

function self:GetNamespace ()
	return self.NamespaceDefinition
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

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:IsMemberFunction ()
	return self.MemberFunction
end

function self:SetBody (blockStatement)
	self.Body = blockStatement
	if self.Body then
		self.Body:SetBlockType (GCompute.AST.BlockType.Function)
		self.Body:SetParent (self)
	end
end

function self:SetFunctionDefinition (functionDefinition)
	self.FunctionDefinition = functionDefinition
end

function self:SetMemberFunction (memberFunction)
	self.MemberFunction = memberFunction
end

function self:SetName (name)
	self.Name = name
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
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

function self:SetTypeExpression (typeExpression)
	self.TypeExpression = typeExpression
	if self.TypeExpression then self.TypeExpression:SetParent (self) end
end

function self:ToString ()
	local returnTypeExpression = self.ReturnTypeExpression and self.ReturnTypeExpression:ToString () or "[Unknown Type]"
	local body = self.Body and self.Body:ToString () or "[Unknown Statement]"
	
	local functionDeclaration = "[Function Declaration]\n" .. returnTypeExpression .. " "
	
	if self.MemberFunction then
		local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Expression]"
		functionDeclaration = functionDeclaration .. typeExpression .. ":"
	end
	functionDeclaration = functionDeclaration .. self.Name .. " " .. self:GetParameterList ():ToString () .. "\n"
	if self.NamespaceDefinition then
		functionDeclaration = functionDeclaration .. self.NamespaceDefinition:ToString () .. "\n"
	end
	functionDeclaration = functionDeclaration .. body
	return functionDeclaration
end

function self:Visit (astVisitor, ...)
	for i = 1, self:GetParameterCount () do
		local parameterType = self:GetParameterType (i)
		local newParameterType = nil
		if parameterType:IsDeferredNameResolution () then
			newParameterType = parameterType:GetParsedName ():Visit (astVisitor, ...)
		end
		if newParameterType and newParameterType ~= parameterType then
			self:SetParameterType (i, newParameterType)
		end
	end
	
	if self:GetReturnTypeExpression () then
		self:SetReturnTypeExpression (self:GetReturnTypeExpression ():Visit (astVisitor, ...) or self:GetReturnTypeExpression ())
	end
	
	local astOverride = astVisitor:VisitStatement (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
	
	if self:GetBody () then
		self:SetBody (self:GetBody ():Visit (astVisitor, ...) or self:GetBody ())
	end
end