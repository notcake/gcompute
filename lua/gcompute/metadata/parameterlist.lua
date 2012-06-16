local self = {}
GCompute.ParameterList = GCompute.MakeConstructor (self)

function self:ctor ()
	self.ParameterCount = 0
	self.ParameterTypes = {}
	self.ParameterNames = {}
	self.ParameterDocumentation = {}
end

--- Adds a parameter to the list
-- @param typeName The type of the parameter, as a string or TypeReference
-- @param name (Optional) The name of the parameter
-- @return The id of the newly added parameter
function self:AddParameter (typeName, name)
	self.ParameterCount = self.ParameterCount + 1
	self.ParameterTypes [self.ParameterCount] = typeName
	self.ParameterNames [self.ParameterCount] = name
	
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

--- Sets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @param documentation The documentation string for the parameter
function self:SetParameterDocumentation (parameterId, documentation)
	self.ParameterDocumentation [parameterId] = documentation
end

--- Sets the name of the given parameter
-- @param parameterId The id of the parameter
-- @param The new name of the parameter
function self:SetParameterName (parameterId, name)
	self.ParameterNames [parameterId] = name
end