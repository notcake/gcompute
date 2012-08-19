local self = {}
GCompute.StackFrame = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Locals = {}
end