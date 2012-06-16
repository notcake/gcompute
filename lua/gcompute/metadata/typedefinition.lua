local self = {}
GCompute.TypeDefinition = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition)

--- @param The name of this type
-- @param typeParameterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
function self:ctor (name, typeParameterList)
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
end

--- Adds a child type to this type definition
-- @param name The name of the child type
-- @return The new TypeDefinition
function self:AddNamespace (name)
	return self:AddType (name)
end

--- Gets the type parameter list of this type
-- @return The type parameter list of this type
function self:GetTypeParameterList ()
	return self.TypeParameterList
end