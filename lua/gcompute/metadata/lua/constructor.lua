local self = {}
GCompute.Lua.Constructor = GCompute.MakeConstructor (self, GCompute.Lua.Function)

function self:ctor (name, f)
end

function self:IsConstructor ()
	return true
end