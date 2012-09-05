local self = {}
GCompute.Containers.LinkedListNode = GCompute.MakeConstructor (self)

function self:ctor ()
	self.List = nil
	self.Next = nil
	self.Previous = nil
	self.Value = nil
end

function self:Remove ()
	self.List:Remove (self)
end

function self:ToString ()
	if not self.Value then return "[nil]" end
	
	if type (self.Value) == "table" and self.Value.ToString then return self.Value:ToString () end
	if type (self.Value) == "string" then return "\"" .. GCompute.String.Escape (self.Value) .. "\"" end
	return tostring (self.Value)
end