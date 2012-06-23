local self = {}
GCompute.TypeParameterList = GCompute.MakeConstructor (self)

function self:ctor ()
	self.ParameterCount = 0
	self.ParameterNames = {}
	self.ParameterDocumentation = {}
end

--- Adds a parameter to the list
-- @param parameterName The name of the parameter
-- @return The id of the newly added parameter
function self:AddParameter (parameterName)
	self.ParameterCount = self.ParameterCount + 1
	self.ParameterNames [self.ParameterCount] = parameterName
	
	return self.ParameterCount
end

--- Gets the number of parameters in this type parameter list
-- @return The number of parameters in this type parameter list
function self:GetParameterCount ()
	return self.ParameterCount
end

--- Gets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @return The documentation string for the parameter
function self:GetParameterDocumentation (parameterId)
	return self.ParameterDocumentation [parameterId]
end

-- Returns the name of the given parameter
-- @param parameterId The id of the parameter
-- @return The name of the parameter or nil if it is unnamed
function self:GetParameterName (parameterId)
	return self.ParameterNames [parameterId]
end

--- Sets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @param documentation The documentation string for the parameter
function self:SetParameterDocumentation (parameterId, documentation)
	self.ParameterDocumentation [parameterId] = documentation
end

-- Sets the name of the given parameter
-- @param parameterId The id of the parameter
-- @param parameterName The new name of the parameter
function self:SetParameterName (parameterId, parameterName)
	self.ParameterNames [parameterId] = parameterName
end