local self = {}
self.__Type = "ParametricName"
GCompute.AST.ParametricName = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Name = nil
	self.Arguments = {}
	self.ArgumentCount = 0
	
	self.LookupType = GCompute.AST.NameLookupType.Reference
	self.ResolutionResults = GCompute.ResolutionResults ()
end

function self:AddArgument (argument)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = argument
	if argument then argument:SetParent (self) end
end

function self:GetArgument (index)
	return self.Arguments [index]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:GetLookupType ()
	return self.LookupType
end

function self:SetLookupType (lookupType)
	self.LookupType = lookupType
end

function self:ToString ()
	local name = self.Name and self.Name:ToString () or "[Unknown]"
	
	name = name .. "<"
	for i = 1, self.ArgumentCount do
		if i > 1 then
			name = name .. ", "
		end
		name = name .. self.Arguments [i]:ToString ()
	end
	name = name .. ">"
	
	return name
end