local self = {}
GCompute.VariableDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this variable
-- @param typeName The type of this variable
function self:ctor (name, typeName)
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	self.Type = typeName and GCompute.NamedType (typeName) or nil
end

--- Returns a string representing this VariableDefinition
-- @return A string representing this VariableDefinition
function self:ToString ()
	local type = self.Type and self.Type:ToString () or "[Unknown Type]"
	return "Variable: " .. type .. " " .. self:GetName ()
end