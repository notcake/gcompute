local self = {}
GCompute.ParameterList = GCompute.MakeConstructor (self)

function self:ctor (parameters)
	self.ParameterCount = 0
	self.ParameterTypes = {}
	self.ParameterNames = {}
	self.ParameterDocumentation = {}
	
	if parameters then
		for _, parameter in ipairs (parameters) do
			self:AddParameter (parameter [1], parameter [2])
		end
	end
end

--- Adds a parameter to the list
-- @param parameterType The type of the parameter, as a string or TypeReference
-- @param parameterName (Optional) The name of the parameter
-- @return The id of the newly added parameter
function self:AddParameter (parameterType, parameterName)
	self.ParameterCount = self.ParameterCount + 1
	self.ParameterTypes [self.ParameterCount] = GCompute.NamedType (parameterType)
	self.ParameterNames [self.ParameterCount] = parameterName
	
	return self.ParameterCount
end

--- Gets the number of parameters in this parameter list
-- @return The number of parameters in this parameter list
function self:GetParameterCount ()
	return self.ParameterCount
end

--- Gets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @return The documentation string for the parameter
function self:GetParameterDocumentation (parameterId)
	return self.ParameterDocumentation [parameterId]
end

--- Gets the name of the given parameter
-- @param parameterId The id of the parameter
-- @return The name of the parameter or nil if it is unnamed
function self:GetParameterName (parameterId)
	return self.ParameterNames [parameterId]
end

--- Gets the type of the given parameter
-- @param parameterId The id of the parameter
-- @return The type of the parameter as a NamedType or nil if it is unknown
function self:GetParameterType (parameterId)
	return self.ParameterTypes [parameterId]
end

--- Sets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @param documentation The documentation string for the parameter
function self:SetParameterDocumentation (parameterId, documentation)
	self.ParameterDocumentation [parameterId] = documentation
end

--- Sets the name of the given parameter
-- @param parameterId The id of the parameter
-- @param parameterName The new name of the parameter
function self:SetParameterName (parameterId, parameterName)
	self.ParameterNames [parameterId] = parameterName
end

--- Sets the type of the given parameter
-- @param parameterId The id of the parameter
-- @param parameterType The new type of the parameter
function self:SetParameterType (parameterId, parameterType)
	self.ParameterTypes [parameterId] = parameterType and GCompute.NamedType (parameterType) or nil
end