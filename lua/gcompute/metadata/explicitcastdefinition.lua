local self = {}
GCompute.ExplicitCastDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name)
end

-- Definition
function self:GetCorrespondingDefinition (globalNamespace)
	GCompute.Error ("ExplicitCastDefinition:GetCorrespondingDefinition : Not implemented.")
end

function self:ResolveTypes (objectResolver, errorReporter)
	self.__base.ResolveTypes (self, objectResolver, errorReporter)
	
	self.Name = "explicit operator " .. self:GetReturnType ():GetFullName ()
end