local self = {}
GCompute.ImplicitCastDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor (name)
end

-- Definition
function self:ResolveTypes (globalNamespace, errorReporter)
	self.__base.ResolveTypes (self, globalNamespace, errorReporter)
	
	self.Name = "implicit operator " .. self:GetReturnType ():GetFullName ()
end