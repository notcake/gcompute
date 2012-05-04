local self = {}
GCompute.Reference = GCompute.MakeConstructor (self)

function self:ctor (scope, name)
	self.Scope = scope
	self.Name = name
	self.Type = GCompute.ReferenceType (self.Scope:GetMemberType (self.Name))
	self.Type:SetResolutionScope (self.Scope)
end

function self:GetName ()
	return self.Name
end

function self:GetScope ()
	return self.Scope
end

function self:GetType ()
	return self.Type
end

function self:GetValue ()
	return self.Scope:GetMember (self.Name)
end

function self:SetValue (value)
	self.Scope:SetMember (self.Name, value)
end

function self:ToString ()
	return self.Scope:GetFullName () .. "." .. tostring (self.Name)
end