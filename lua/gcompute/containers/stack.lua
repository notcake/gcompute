local self = {}
GCompute.Containers.Stack = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Items = {}
	self.Count = 0
	self.Top = nil
end

--- Clears the stack
function self:Clear ()
	self.Count = 0
	self.Top = nil
end

--- Returns whether the stack is empty
-- @return true if the stack is empty
function self:IsEmpty ()
	return self.Count == 0
end

--- Pushes an item onto the top of the stack
-- @param value The item to be pushed onto the top of the stack
function self:Push (value)
	self.Count = self.Count + 1
	self.Items [self.Count] = value
	self.Top = value
end

--- Pops an item from the top of the stack
-- @return The item that was popped from the top of the stack or nil if the stack was already empty
function self:Pop ()
	if self.Count == 0 then return nil end
	local top = self.Top
	self.Items [self.Count] = nil
	self.Count = self.Count - 1
	self.Top = self.Items [self.Count]
	return top
end