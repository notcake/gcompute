local self = {}
GCompute.TypeParameterDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition, GCompute.Type)

function self:ctor (name)
	self.DeclaringFunction = nil
	self.TypeParameterPosition = 1
end

function self:GetDeclaringFunction ()
	return self.DeclaringFunction
end

function self:GetTypeParameterPosition ()
	return self.TypeParameterPosition
end

function self:IsTypeParameter ()
	return true
end

function self:ResolveTypes (globalNamespace, errorReporter)
end

function self:SetDeclaringFunction (declaringFunction)
	self.DeclaringFunction = declaringFunction
	return self
end

function self:SetTypeParameterPosition (typeParameterPosition)
	self.TypeParameterPosition = typeParameterPosition
	return self
end

function self:SubstituteTypeParameters (substitutionMap)
	return substitutionMap:GetReplacement (self)
end

function self:ToString ()
	return "[Type Parameter] " .. self:GetName ()
end