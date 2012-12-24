local self = {}
GCompute.Expression2.Container = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Values = {}
	self.Types  = {}
end

function self:Clear ()
	self.Values = {}
	self.Types  = {}
end