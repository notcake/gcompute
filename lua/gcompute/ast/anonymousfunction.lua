local self = {}
self.__Type = "AnonymousFunction"
GCompute.AST.AnonymousFunction = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.ReturnTypeExpression = nil
	
	self.ParameterList = GCompute.ParameterList ()
	
	self.Body = nil
end

function self:AddParameter (parameterType, parameterName)
	self.ParameterList:AddParameter (GCompute.DeferredNameResolution (parameterType), parameterName or "[Unknown Identifier]")
	if parameterType then parameterType:SetParent (self) end
end

function self:GetBody ()
	return self.Body
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

function self:SetArgumentName (index, name)
	self.ArgumentNames [index] = name
end

function self:SetArgumentType (index, type)
	self.ArgumentNames [index] = type
	if type then type:SetParent (self) end
end

function self:SetBody (blockStatement)
	self.Body = blockStatement
	if self.Body then self.Body:SetParent (self) end
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
	local body = self.Body and self.Body:ToString () or "[Unknown Statement]"
	
	return returnTypeExpression .. " " .. self:GetParameterList ():ToString () .. "\n" .. body
end