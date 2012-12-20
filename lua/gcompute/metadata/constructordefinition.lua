local self = {}
GCompute.ConstructorDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name, parameterList)
end

-- Definition
function self:ToString ()
	return self:GetShortName () .. " " .. self:GetParameterList ():GetRelativeName (self)
end