local self = {}
self.__Type = "AnonymousFunction"
GCompute.AST.AnonymousFunction = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.ReturnTypeExpression = nil
	
	self.ParameterList = GCompute.AST.ParameterList ()
	
	self.Body = nil
	
	self.MethodDefinition = nil
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
	if self.Body then
		self.Body:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.MethodDefinition then
		self.MethodDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	astRunner:PushValue (self.MethodDefinition)
	
	-- Discard AnonymousFunction
	astRunner:PopNode ()
end

function self:GetBody ()
	return self.Body
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.ReturnTypeExpression
		elseif i == 2 then
			return self.ParameterList
		elseif i == 3 then
			return self.Body
		end
		return nil
	end
end

function self:GetDefinition ()
	return self.MethodDefinition
end

function self:GetMethodDefinition ()
	return self.MethodDefinition
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:GetResolutionResult ()
	return self.MethodDefinition
end

function self:GetReturnTypeExpression ()
	return self.ReturnTypeExpression
end

function self:SetBody (blockStatement)
	self.Body = blockStatement
	if self.Body then
		self.Body:SetBlockType (GCompute.AST.BlockType.Function)
		self.Body:SetParent (self)
	end
end

function self:SetDefinition (methodDefinition)
	self.MethodDefinition = methodDefinition
end

function self:SetMethodDefinition (methodDefinition)
	self.MethodDefinition = methodDefinition
end

function self:SetParameterList (parameterList)
	self.ParameterList = parameterList
	if parameterList then parameterList:SetParent (self) end
end

function self:SetReturnTypeExpression (returnTypeExpression)
	self.ReturnTypeExpression = returnTypeExpression
	if self.ReturnTypeExpression then self.ReturnTypeExpression:SetParent (self) end
end

function self:ToString ()
	local returnTypeExpression = self.ReturnTypeExpression and self.ReturnTypeExpression:ToString () or "[Unknown Type]"
	local body = self.Body and self.Body:ToString () or "[Unknown Statement]"
	
	return returnTypeExpression .. " " .. self:GetParameterList ():ToString () .. "\n" .. body
end

function self:Visit (astVisitor, ...)
	if self:GetParameterList () then
		self:SetParameterList (self:GetParameterList ():Visit (astVisitor, ...) or self:GetParameterList ())
	end
	
	if self:GetReturnTypeExpression () then
		self:SetReturnTypeExpression (self:GetReturnTypeExpression ():Visit (astVisitor, ...) or self:GetReturnTypeExpression ())
	end
	
	local astOverride = astVisitor:VisitExpression (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
	
	self:SetBody (self:GetBody ():Visit (astVisitor, ...) or self:GetBody ())
end