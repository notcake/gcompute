local LinkedList = {}
local LinkedListNode = {}
GCompute.Containers.LinkedList = GCompute.MakeConstructor (LinkedList)
GCompute.Containers.LinkedListNode = GCompute.MakeConstructor (LinkedListNode)

-- Linked list
function LinkedList:ctor ()
	self.First = nil
	self.Last = nil
	self.Count = 0
end

function LinkedList:AddAfter (value)
	if value == nil then
		return
	end
	local LinkedListNode = GCompute.Containers.LinkedListNode ()
	LinkedListNode.Previous = value
	LinkedListNode.Next = value.Next
	
	if value.Next then
		value.Next.Previous = LinkedListNode
	end
	value.Next = LinkedListNode
	
	if self.Last == value then
		self.Last = LinkedListNode
	end
	
	self.Count = self.Count + 1
	LinkedListNode.Value = value
	
	return LinkedListNode
end

function LinkedList:AddBefore (value)
	if value == nil then
		return
	end
	local LinkedListNode = GCompute.Containers.LinkedListNode ()
	LinkedListNode.Previous = value.Previous
	LinkedListNode.Next = value
	
	if value.Previous then
		value.Previous.Next = LinkedListNode
	end
	value.Previous = LinkedListNode
	
	if self.First == value then
		self.First = LinkedListNode
	end
	
	self.Count = self.Count + 1
	LinkedListNode.Value = value
	
	return LinkedListNode
end

function LinkedList:AddFirst (value)
	if not self.First then
		self.First = GCompute.Containers.LinkedListNode ()
		self.Last = self.First
	else
		self.First.Previous = GCompute.Containers.LinkedListNode ()
		self.First.Previous.Next = self.First
		self.First = self.First.Previous
	end
	self.Count = self.Count + 1
	self.First.Value = value
	
	return self.First
end

function LinkedList:AddLast (value)
	if not self.Last then
		self.First = GCompute.Containers.LinkedListNode ()
		self.Last = self.First
	else
		self.Last.Next = GCompute.Containers.LinkedListNode ()
		self.Last.Next.Previous = self.Last
		self.Last = self.Last.Next
	end
	self.Count = self.Count + 1
	self.Last.Value = value
	
	return self.Last
end

function LinkedList:Clear ()
	self.First = nil
	self.Last = nil
	self.Count = 0
end

function LinkedList:GetEnumerator ()
	local Node = self.First
	return function ()
		local Return = Node
		if Node then
			Node = Node.Next
		end
		return Return
	end
end

function LinkedList:GetItem (n)
	local Node = self.First
	while Node do
		if n == 0 then return Node.Value else n = n - 1 end
		Node = Node.Next
	end
	
	return nil
end

function LinkedList:IsEmpty ()
	return self.Count == 0
end

function LinkedList:Remove (LinkedListNode)
	if not LinkedListNode then
		return
	end

	if LinkedListNode.Previous then
		LinkedListNode.Previous.Next = LinkedListNode.Next
	end
	if LinkedListNode.Next then
		LinkedListNode.Next.Previous = LinkedListNode.Previous
	end
	if self.First == LinkedListNode then
		self.First = LinkedListNode.Next
	end
	if self.Last == LinkedListNode then
		self.Last = LinkedListNode.Previous
	end
	LinkedListNode.Previous = nil
	LinkedListNode.Next = nil
	self.Count = self.Count - 1
end

function LinkedList:ToString ()
	local Content = ""
	for LinkedListNode in self:GetEnumerator () do
		if Content ~= "" then
			Content = Content .. ", "
		end
		Content = Content .. LinkedListNode:ToString ()
	end
	return "[" .. tostring (self.Count) .. "] : {" .. Content .. "}"
end

-- Linked list node
function LinkedListNode:ctor ()
	self.Previous = nil
	self.Next = nil
	self.Value = nil
end

function LinkedListNode:ToString ()
	if not self.Value then return "[nil]" end
	
	if type (self.Value) == "table" and self.Value.ToString then return self.Value:ToString () end
	if type (self.Value) == "string" then return "\"" .. self.Value .. "\"" end
	return tostring (self.Value)
end

if CLIENT then
	concommand.Add ("gcompute_test_array", function (ply, _, args)
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		GCompute.PrintDebug ("Testing array:")
		local Array = {}
		GCompute.PrintDebug ("+2, +3, +5, 0+, -5, -2")
		table.insert (Array, 2)
		table.insert (Array, 3)
		table.insert (Array, 5)
		table.insert (Array, 1, 0)
		table.remove (Array, 4)
		table.remove (Array, 2)
		local Contents = ""
		for _, Value in pairs (Array) do
			if Contents ~= "" then
				Contents = Contents .. ", "
			end
			Contents = Contents .. tostring (Value)
		end
		GCompute.PrintDebug (Contents)
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Test 1 took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)

	concommand.Add ("gcompute_test_linkedlist", function (ply, _, args)
		GCompute.ClearDebug ()
	
		local StartTime = SysTime ()
		GCompute.PrintDebug ("Testing linked list:")
		local LinkedList = GCompute.Containers.LinkedList ()
		GCompute.PrintDebug ("+2, +3, +5, 0+, -5, -2")
		local Remove = LinkedList:AddLast (2)
		LinkedList:AddLast (3)
		local Remove2 = LinkedList:AddLast (5)
		LinkedList:AddFirst (0)
		LinkedList:Remove (Remove2)
		LinkedList:Remove (Remove)
		GCompute.PrintDebug (LinkedList:ToString ())
		local EndTime = SysTime ()
		GCompute.PrintDebug ("Test 1 took " .. tostring (math.floor ((EndTime - StartTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)
end