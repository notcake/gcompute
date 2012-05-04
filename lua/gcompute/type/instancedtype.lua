local self = {}
GCompute.InstancedType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (parametricType)
	self.ParametricType = parametricType
	
	self.Arguments = {}
end

function self:GetArgumentCount ()
	return self.ParametricType:GetArgumentCount ()
end

function self:GetFullName ()
	local str = ""
	if self.ParametricType:GetParentScope () then
		str = self.ParametricType:GetParentScope ():GetFullName () .. "."
	end
	
	str = str .. self.ParametricType:GetName ()
	if self.ArgumentCount > 0 then
		str = str .. "<"
		for i = 1, self.ArgumentCount do
			if i > 1 then
				str = str .. ", "
			end
			str = str .. self.Arguments [i]:ToString ()
		end
		str = str .. ">"
	end
	return str
end

self.ToDefinitionString = self.GetFullName
self.ToString = self.GetFullName