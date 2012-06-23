local self = {}
self.__Type = "FunctionDeclaration"
GCompute.AST.FunctionDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Name = "[Unknown Identifier]"
	
	self.ReturnType = nil	
	
	self.MemberFunction = false
	self.TypeExpression = nil
	
	self.ParameterList = GCompute.ParameterList ()
	
	self.Body = nil
end

function self:AddParameter (parameterType, parameterName)
	self.ParameterList:AddParameter (parameterType, parameterName or "[Unknown Identifier]")
	if parameterType then parameterType:SetParent (self) end
end

function self:Evaluate ()
end

function self:GetBody ()
	return self.Body
end

function self:GetName ()
	return self.Name
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

function self:GetReturnType ()
	return self.ReturnType
end

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:IsMemberFunction ()
	return self.MemberFunction
end

function self:SetBody (blockStatement)
	self.Body = blockStatement
	if self.Body then self.Body:SetParent (self) end
end

function self:SetMemberFunction (memberFunction)
	self.MemberFunction = memberFunction
end

function self:SetName (name)
	self.Name = name
end

function self:SetParameterName (parameterId, parameterName)
	self.ParameterList:SetParameterName (parameterId, parameterName)
end

function self:SetParameterType (parameterId, parameterType)
	self.ParameterList:SetParameterType (parameterId, parameterType)
	if parameterType then parameterType:SetParent (self) end
end

function self:SetReturnType (returnType)
	self.ReturnType = returnType
	if self.ReturnType then self.ReturnType:SetParent (self) end
end

function self:SetTypeExpression (typeExpression)
	self.TypeExpression = typeExpression
	if self.TypeExpression then self.TypeExpression:SetParent (self) end
end

function self:ToString ()
	local returnType = self.ReturnType and self.ReturnType:ToString () or "[Unknown Type]"
	local body = self.Body and self.Body:ToString () or "[Unknown Statement]"
	
	local arguments = ""
	for i = 1, self:GetParameterCount () do
		if arguments ~= "" then
			arguments = arguments .. ", "
		end
		local argumentType = self:GetParameterType (i) and self:GetParameterType (i):ToString () or "[Unknown Type]"
		arguments = arguments .. argumentType .. " " .. self:GetParameterName (i)
	end
	if self.MemberFunction then
		local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Expression]"
		return "[Function Declaration]\n" .. returnType .. " " .. typeExpression .. ":" .. self.Name .. " (" .. arguments .. ")\n" .. body
	else
		return "[Function Declaration]\n" .. returnType .. " " .. self.Name .. " (" .. arguments .. ")\n" .. body
	end
end