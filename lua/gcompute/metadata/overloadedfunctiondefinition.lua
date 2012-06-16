local self = {}
GCompute.OverloadedFunctionDefinition = GCompute.MakeConstructor (self, GCompute.MetadataObject)

--- @param name The name of this function
function self:ctor (name)
	self.Functions = {}
end

--- Adds a type to this type group
-- @param typeParamterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
-- @return The new TypeDefinition
function self:AddFunction (parameterList, typeParameterList)
	self.Functions [#self.Functions + 1] = GCompute.FunctionDefinition (self:GetName (), parameterList, typeParameterList)
	self.Functions [#self.Functions]:SetContainingNamespace (self:GetContainingNamespace ())
	return self.Functions [#self.Functions]
end