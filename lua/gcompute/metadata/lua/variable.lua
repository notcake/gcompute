local self = {}
GCompute.Lua.Variable = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor (name, value)
	self.Value = value
end

function self:GetDisplayText ()
	local value
	if type (self.Value) == "string" then
		value = "\"" .. GLib.String.Escape (self.Value) .. "\""
	else
		value = tostring (self.Value)
	end
	return self:GetName () .. " = " .. value
end

function self:IsVariable ()
	return true
end

function self:ToString ()
	return self:GetName () or "[Unnamed]"
end