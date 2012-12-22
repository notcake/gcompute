local self = {}
GCompute.PropertyAccessorDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name)
end

-- Definition
function self:GetCorrespondingDefinition (globalNamespace)
	GCompute.Error ("PropertyAccessorDefinition:GetCorrespondingDefinition : Not implemented.")
end