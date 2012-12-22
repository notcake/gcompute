local self = {}
GCompute.TypeParameterDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor (name)
	self.TypeParameterType = GCompute.TypeParameterType (self)
	self.TypeParameterPosition = 1
end

-- System
function self:SetGlobalNamespace (globalNamespace)
	if self.GlobalNamespace == globalNamespace then return end
	
	self.GlobalNamespace = globalNamespace
	self.TypeParameterType:SetGlobalNamespace (globalNamespace)
end

-- Type Parameter
function self:GetTypeParameterPosition ()
	return self.TypeParameterPosition
end

function self:IsConcreteType ()
	return true
end

function self:SetTypeParameterPosition (typeParameterPosition)
	self.TypeParameterPosition = typeParameterPosition
	return self
end

-- Definition
function self:IsTypeParameter ()
	return true
end

function self:IsType ()
	return true
end

function self:ResolveTypes (globalNamespace, errorReporter)
end

function self:ToString ()
	return "[Type Parameter] " .. self:GetName ()
end

function self:ToType ()
	return self.TypeParameterType
end