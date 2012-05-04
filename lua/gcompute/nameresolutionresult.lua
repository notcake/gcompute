local self = {}
GCompute.NameResolutionResult = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Value = nil
	self.Reference = nil
	self.Type = nil
	
	self.Static = false	-- can this result change during runtime?
	
	self.IndexType = nil
end

function self:GetIndexType ()
	return self.IndexType
end

function self:GetReference ()
	return self.Reference
end

function self:GetType ()
	return self.Type
end

function self:GetValue ()
	return self.Value
end

function self:IsStatic ()
	return self.Static
end

function self:SetIndexType (indexType)
	self.IndexType = indexType
end

function self:SetResult (value, type, reference)
	self.Value = value
	self.Reference = reference
	self.Type = type
end

function self:SetStatic (static)
	self.Static = static
end

function self:ToString ()
	local value = tostring (self.Value)
	if type (self.Value) == "table" and type (self.Value.ToString) == "function" then
		value = self.Value:ToString ()
	end
	if self.Reference then
		value = self.Reference:ToString ()
	end
	return self.Type:ToString () .. " " .. value
end