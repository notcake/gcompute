local self = {}
GCompute.TypeParameterDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition, GCompute.Type)

function self:ctor (name)
end

function self:IsTypeParameter ()
	return true
end

function self:ResolveTypes (globalNamespace, errorReporter)
end

function self:ToString ()
	return "[Type Parameter] " .. self:GetName ()
end