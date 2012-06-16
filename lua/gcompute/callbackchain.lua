local self = {}
GCompute.CallbackChain = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Callbacks = {}
end

function self:Add (callback)
	self.Callbacks [#self.Callbacks + 1] = callback
end

function self:AddUnwrap (callback)
	self.Callbacks [#self.Callbacks + 1] = function (_, ...)
		callback (...)
	end
end

function self:Execute (...)
	self.Callbacks [1] (self:GetCallback (2), ...)
end

function self:GetCallback (i)
	i = i or 1
	return function (...)
		if not self.Callbacks [i] then return end
		self.Callbacks [i] (self:GetCallback (i + 1), ...)
	end
end