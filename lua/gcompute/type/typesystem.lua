local self = {}
GCompute.TypeSystem = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Top    = nil
	self.Bottom = nil
	self.Type   = nil
end

function self:Clone (globalNamespace)
	local typeSystem = GCompute.TypeSystem ()
	if globalNamespace then
		typeSystem:SetBottom (self.Bottom and self.Bottom:GetCorrespondingDefinition (globalNamespace) or nil)
		typeSystem:SetTop    (self.Top    and self.Top   :GetCorrespondingDefinition (globalNamespace) or nil)
		typeSystem:SetType   (self.Type   and self.Type  :GetCorrespondingDefinition (globalNamespace) or nil)
	else
		typeSystem:SetBottom (self.Bottom)
		typeSystem:SetTop    (self.Top)
		typeSystem:SetType   (self.Type)
	end
	return typeSystem
end

function self:GetBottom ()
	return self.Bottom
end

function self:GetObject ()
	return self.Top
end

function self:GetTop ()
	return self.Top
end

function self:GetType ()
	return self.Type
end

function self:GetVoid ()
	return self.Void
end

function self:SetBottom (bottom)
	self.Bottom = bottom
end

function self:SetObject (object)
	self.Top = object
end

function self:SetTop (top)
	self.Top = top
end

function self:SetType (type)
	self.Type = type
end

function self:SetVoid (void)
	self.Bottom = void
end

function self:ToString ()
	local typeSystem = "[Type System]\n{\n"
	typeSystem = typeSystem .. "    Bottom = " .. (self.Bottom and self.Bottom:GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Top    = " .. (self.Top    and self.Top   :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Type   = " .. (self.Type   and self.Type  :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "}"
	
	return typeSystem
end