local self = {}
GCompute.ConstructorDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name, parameterList)
end

-- Definition
function self:GetCorrespondingDefinition (globalNamespace)
	GCompute.Error ("ConstructorDefinition:GetCorrespondingDefinition : Not implemented.")
end

function self:ToString ()
	return self:GetShortName () .. " " .. self:GetParameterList ():GetRelativeName (self)
end