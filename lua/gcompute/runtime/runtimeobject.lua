local self = {}
GCompute.RuntimeObject = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Type = nil
	self.BoxedValue = nil
	self.HasBoxedValue = false
	
	self.FunctionTable = {}
	self.MemberTables  = {}
	self.NativeStorage = {}
	self._             = self.NativeStorage
end

function self:Box (value, type)
	if self.Type or self.BoxedValue then
		GCompute.Error ("RuntimeObject:Box : This RuntimeObject is already initialized!\n")
	end
	
	self.Type          = type
	self.BoxedValue    = value
	self.HasBoxedValue = true
	
	self.FunctionTable = self.Type:GetFunctionTable ()
	
	return self
end

function self:GetBoxedValue ()
	return self.BoxedValue
end

function self:GetNativeStorage ()
	return self.NativeStorage
end

function self:GetType ()
	return self.Type
end

function self:IsBox ()
	return self.HasBoxedValue
end

function self:SetBoxedValue (boxedValue)
	self.BoxedValue    = boxedValue
	self.HasBoxedValue = true
end

function self:SetType (type)
	self.Type = type
end

function self:Unbox ()
	return self.BoxedValue
end

function self:ToString ()
	local value = self
	if self.HasBoxedValue then
		value = self.BoxedValue
	end
	
	local toString = self.FunctionTable.Virtual.ToString
	if type (toString) == "function" then
		return toString (value)
	end
	return "{" .. self:GetType ():GetFullName () .. "}"
end