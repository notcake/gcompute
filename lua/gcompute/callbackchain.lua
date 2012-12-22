local self = {}
GCompute.CallbackChain = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Callbacks = {}
	self.ErrorCallbacks = {}
end

function self:Execute (...)
	self:GetCallback (1) (...)
end

function self:GetCallback (i)
	i = i or 1
	return function (...)
		if not self.Callbacks [i] then return end
		self.Callbacks [i] (self:GetCallback (i + 1), self:GetErrorCallback (i), ...)
	end
end

function self:GetErrorCallback (i)
	i = i or 1
	return function (...)
		if not self.ErrorCallbacks [i] then return end
		self.ErrorCallbacks [i] (self:GetCallback (i + 1), ...)
	end
end

local function wrap (f)
	return function (...)
		return xpcall (f, GCompute.Error, ...)
	end
end

function self:Then (callback, errorCallback)
	if not callback then return self end
	
	self.Callbacks [#self.Callbacks + 1] = wrap (callback)
	self.ErrorCallbacks [#self.ErrorCallbacks + 1] = errorCallback or error
	
	return self
end

function self:ThenUnwrap (callback, errorCallback)
	if not callback then return self end
	
	return self:Then (
		function (_, _, ...)
			callback (...)
		end
	)
end