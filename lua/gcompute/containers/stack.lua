local Stack = {}
Stack.__index = Stack

function GCompute.Containers.Stack ()
	local Object = {}
	setmetatable (Object, Stack)
	Object:ctor ()
	return Object
end

function Stack:ctor ()
	self.Items = {}
	self.Count = 0
	self.Top = nil
end

function Stack:Clear ()
	self.Count = 0
	self.Top = nil
end

function Stack:IsEmpty ()
	return self.Count == 0
end

function Stack:Push (Value)
	self.Count = self.Count + 1
	self.Items [self.Count] = Value
	self.Top = Value
end

function Stack:Pop ()
	if self.Count == 0 then
		return nil
	end
	local Top = self.Items [self.Count]
	self.Items [self.Count] = nil
	self.Count = self.Count - 1
	self.Top = self.Items [self.Count]
	return Top
end