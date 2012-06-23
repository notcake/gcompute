local self = {}
GCompute.OverloadedTypeDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this type
function self:ctor (name)
	self.Types = {}
end

--- Adds a type to this type group
-- @param typeParamterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
-- @return The new TypeDefinition
function self:AddType (typeParameterList)
	self.Types [#self.Types + 1] = GCompute.TypeDefinition (self:GetName (), typeParameterList)
	self.Types [#self.Types]:SetContainingNamespace (self:GetContainingNamespace ())
	return self.Types [#self.Types]
end