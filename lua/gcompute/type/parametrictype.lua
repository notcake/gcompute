local self = {}
GCompute.ParametricType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (name)
	self.Name = name
	self.ParentScope = nil
	self.ResolutionScope = nil
	
	self.Members = GCompute.Scope (self)
	self.Members:SetName (name)
	
	self.BaseTypes = {}
	
	self.ArgumentCount = 0
	self.Arguments = {}
	
	self.Instances = {}
	
	self:AddBaseType ("Object")
end

function self:AddArgument (type, name)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] =
		{
			Type = GCompute.TypeReference (type),
			Name = name
		}
		
	self.Arguments [self.ArgumentCount].Type:SetResolutionScope (self.ResolutionScope)
	
	self.Members:AddTypeReference (name, "void")
end

function self:AddBaseType (typeName)
	self.BaseTypes [#self.BaseTypes + 1] = GCompute.TypeReference (typeName)
	self.BaseTypes [#self.BaseTypes]:SetResolutionScope (self.ResolutionScope)
end

function self:ClearBaseTypes ()
	self.BaseTypes = {}
end

function self:CreateInstance (...)
end

function self:GetArgumentCount ()
	return 0
end

function self:GetFullName ()
	local str = ""
	if self.ParentScope then
		str = self.ParentScope:GetFullName () .. "."
	end
	
	str = str .. self.Name
	if self.ArgumentCount > 0 then
		str = str .. "<"
		for i = 1, self.ArgumentCount do
			if i > 1 then
				str = str .. ", "
			end
			str = str .. self.Arguments [i].Type:GetFullName () .. " " .. self.Arguments [i].Name
		end
		str = str .. ">"
	end
	return str
end

function self:GetMembers ()
	return self.Members
end

function self:GetName ()
	return self.Name
end

function self:GetResolutionScope ()
	return self.ResolutionScope
end

function self:SetResolutionScope (resolutionScope)
	if self.ResolutionScope and self.ResolutionScope ~= resolutionScope then GCompute.Error ("Resolution scope already set!") end

	self.ParentScope = resolutionScope
	self.ResolutionScope = resolutionScope
	
	for i = 1, #self.BaseTypes do
		self.BaseTypes [i]:SetResolutionScope (resolutionScope)
	end
	
	for i = 1, self.ArgumentCount do
		self.Arguments [i].Type:SetResolutionScope (resolutionScope)
	end
	
	self.Members:SetParentScope (resolutionScope)
	if resolutionScope then
		self.Members:SetGlobalScope (resolutionScope:GetGlobalScope ())
	end
end

function self:ToDefinitionString ()
	local str = self:GetFullName ()
	if #self.BaseTypes > 0 then
		str = str .. " : "
		for i = 1, #self.BaseTypes do
			if i > 1 then
				str = str .. ", "
			end
			str = str .. self.BaseTypes [i]:ToString ()
		end
	end
	return str
end

self.ToString = self.GetFullName