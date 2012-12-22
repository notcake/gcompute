local self = {}
GCompute.ExplicitCastDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name)
end

-- Definition
function self:GetCorrespondingDefinition (globalNamespace, typeSystem)
	GCompute.Error ("ExplicitCastDefinition:GetCorrespondingDefinition : Not implemented.")
end

function self:ResolveTypes (globalNamespace, errorReporter)
	self.__base.ResolveTypes (self, globalNamespace, errorReporter)
	
	self.Name = "explicit operator " .. self:GetReturnType ():GetFullName ()
end