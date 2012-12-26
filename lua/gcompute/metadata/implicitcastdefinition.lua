local self = {}
GCompute.ImplicitCastDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name)
end

-- Definition
function self:GetCorrespondingDefinition (globalNamespace)
	GCompute.Error ("ImplicitCastDefinition:GetCorrespondingDefinition : Not implemented.")
end

function self:ResolveTypes (objectResolver, errorReporter)
	self.__base.ResolveTypes (self, objectResolver, errorReporter)
	
	self.Name = "implicit operator " .. self:GetReturnType ():GetFullName ()
end