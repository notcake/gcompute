local self = {}
GCompute.TypeParameterType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (typeParameterDefinition)
	self.Definition = typeParameterDefinition
end

local forwardedFunctions =
{
	"GetFullName",
	"GetRelativeName",
	"GetTypeParameterPosition"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		return self.Definition [functionName] (self.Definition, ...)
	end
end

function self:IsTypeParameter ()
	return true
end