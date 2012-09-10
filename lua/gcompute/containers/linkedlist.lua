local self = {}
GCompute.Containers.LinkedList = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LinkedList     = GCompute.Containers.LinkedList
	self.LinkedListNode = GCompute.Containers.LinkedListNode
	
	self.First = nil
	self.Last = nil
	self.Count = 0
end

function self:AddAfter (node, value)
	if node == nil then return self:AddFirst (value) end
	
	local linkedListNode = self.LinkedListNode ()
	linkedListNode.List = self
	linkedListNode.Next = node.Next
	linkedListNode.Previous = node
	
	if node.Next then
		node.Next.Previous = linkedListNode
	end
	node.Next = linkedListNode
	
	if self.Last == node then
		self.Last = linkedListNode
	end
	
	self.Count = self.Count + 1
	linkedListNode.Value = value
	
	return linkedListNode
end

function self:AddBefore (node, value)
	if node == nil then return self:AddLast (value) end
	
	local linkedListNode = self.LinkedListNode ()
	linkedListNode.List = self
	linkedListNode.Next = node
	linkedListNode.Previous = node.Previous
	
	if node.Previous then
		node.Previous.Next = linkedListNode
	end
	node.Previous = linkedListNode
	
	if self.First == node then
		self.First = linkedListNode
	end
	
	self.Count = self.Count + 1
	linkedListNode.Value = value
	
	return linkedListNode
end

function self:AddFirst (value)
	if not self.First then
		self.First = self.LinkedListNode ()
		self.First.List = self
		self.Last = self.First
	else
		self.First.Previous = self.LinkedListNode ()
		self.First.Previous.List = self
		self.First.Previous.Next = self.First
		self.First = self.First.Previous
	end
	self.Count = self.Count + 1
	self.First.Value = value
	
	return self.First
end

function self:AddLast (value)
	if not self.Last then
		self.First = self.LinkedListNode ()
		self.First.List = self
		self.Last = self.First
	else
		self.Last.Next = self.LinkedListNode ()
		self.Last.Next.List = self
		self.Last.Next.Previous = self.Last
		self.Last = self.Last.Next
	end
	self.Count = self.Count + 1
	self.Last.Value = value
	
	return self.Last
end

function self:Append (linkedList)
	if not linkedList then return end
	if not linkedList.First then return end
	
	if self.Last then
		self.Last.Next = linkedList.First
		
		self.Count = self.Count + linkedList.Count
		
		local node = self.Last
		while node do
			node.List = self
			node = node.Next
		end
		
		self.Last.Next.Previous = self.Last
		self.Last = linkedList.Last
	else
		self.First = linkedList.First
		self.Last = linkedList.Last
		self.Count = linkedList.Count
		
		for node in self:GetEnumerator () do
			node.List = self
		end
	end
	
	linkedList.First = nil
	linkedList.Last = nil
	linkedList.Count = 0
end

function self:Clear ()
	self.First = nil
	self.Last = nil
	self.Count = 0
end

function self:ComputeMemoryUsage (memoryUsageReport, poolName)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure (poolName or "Linked Lists", self)
	for linkedListNode in self:GetEnumerator () do
		memoryUsageReport:CreditTableStructure (poolName or "Linked Lists", linkedListNode)
		memoryUsageReport:CreditObject (poolName or "Linked Lists", linkedListNode.Value)
	end
	return memoryUsageReport
end

function self:Filter (filter)
	if not filter then return end
	
	for linkedListNode in self:GetEnumerator () do
		if not filter (linkedListNode) then
			linkedListNode:Remove ()
		end
	end
end

--- Returns an iterator which returns LinkedListNodes in this LinkedList. Deletion of the last LinkedListNode returned by the iterator is allowed.
-- @return An iterator which returns LinkedListNodes in this LinkedList
function self:GetEnumerator ()
	local node = self.First
	return function ()
		local ret = node
		node = node and node.Next
		return ret
	end
end

function self:GetItem (n)
	if n > self.Count then return nil end

	local node = self.First
	while node do
		if n == 0 then return node.Value else n = n - 1 end
		node = node.Next
	end
	
	return nil
end

function self:InsertNodeBefore (postInsertionNode, insertionNode)
	if not insertionNode then return end
	
	if not postInsertionNode then
		insertionNode.Previous = self.Last
		self.Last = insertionNode
	else
		insertionNode.Next = postInsertionNode
		insertionNode.Previous = postInsertionNode.Previous
		
		postInsertionNode.Previous = insertionNode
	end
	
	if insertionNode.Previous then
		insertionNode.Previous.Next = insertionNode
	else
		self.First = insertionNode
	end
	
	insertionNode.List = self
	self.Count = self.Count + 1
end

function self:IsEmpty ()
	return self.Count == 0
end

function self:Remove (linkedListNode)
	if not linkedListNode then
		return
	end

	if linkedListNode.Previous then
		linkedListNode.Previous.Next = linkedListNode.Next
	end
	if linkedListNode.Next then
		linkedListNode.Next.Previous = linkedListNode.Previous
	end
	if self.First == linkedListNode then
		self.First = linkedListNode.Next
	end
	if self.Last == linkedListNode then
		self.Last = linkedListNode.Previous
	end
	linkedListNode.List = nil
	linkedListNode.Next = nil
	linkedListNode.Previous = nil
	self.Count = self.Count - 1
end

function self:RemoveRange (startNode, endNode)
	startNode = startNode or self.First
	endNode = endNode or self.Last

	local removalCount = 1
	local currentNode = startNode
	while currentNode and currentNode ~= endNode do
		currentNode = currentNode.Next
		removalCount = removalCount + 1
	end
	if not currentNode then return end
	
	if not startNode.Previous then
		self.First = endNode.Next
	else
		startNode.Previous.Next = endNode.Next
	end
	if not endNode.Next then
		self.Last = startNode.Previous
	else
		endNode.Next.Previous = startNode.Previous
	end
	
	self.Count = self.Count - removalCount
end

function self:Split (node)
	local linkedList = self.LinkedList ()
	linkedList.LinkedList = self.LinkedList
	linkedList.LinkedListNode = self.LinkedListNode
	
	if not node then return linkedList end
	
	linkedList.First = node
	linkedList.Last = self.Last
	
	if node then
		self.Last = node.Previous
		if self.Last then
			self.Last.Next = nil
		end
	end
	
	if linkedList.First then
		linkedList.First.Previous = nil
	end
	if linkedList.Last then
		linkedList.Last.Next = nil
	end
	for node in linkedList:GetEnumerator () do
		node.List = linkedList
		self.Count = self.Count - 1
		linkedList.Count = linkedList.Count + 1
	end
	
	return linkedList
end

function self:ToArray ()
	local array = {}
	
	for node in self:GetEnumerator () do
		array [#array + 1] = node.Value
	end
	
	return array
end

function self:ToString ()
	local content = ""
	for linkedListNode in self:GetEnumerator () do
		if content ~= "" then
			content = content .. ", "
		end
		
		if content:len () > 2048 then
			content = content .. "..."
			break
		end
		
		content = content .. linkedListNode:ToString ()
	end
	return "[" .. tostring (self.Count) .. "] : {" .. content .. "}"
end

if CLIENT then
	concommand.Add ("gcompute_test_array", function (ply, _, args)
		GCompute.ClearDebug ()
	
		local startTime = SysTime ()
		GCompute.PrintDebug ("Testing array:")
		local array = {}
		GCompute.PrintDebug ("+2, +3, +5, 0+, -5, -2")
		table.insert (array, 2)
		table.insert (array, 3)
		table.insert (array, 5)
		table.insert (array, 1, 0)
		table.remove (array, 4)
		table.remove (array, 2)
		local contents = ""
		for _, value in pairs (array) do
			if contents ~= "" then
				contents = contents .. ", "
			end
			contents = contents .. tostring (value)
		end
		GCompute.PrintDebug (contents)
		local endTime = SysTime ()
		GCompute.PrintDebug ("Test 1 took " .. tostring (math.floor ((endTime - startTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)

	concommand.Add ("gcompute_test_linkedlist", function (ply, _, args)
		GCompute.ClearDebug ()
	
		local startTime = SysTime ()
		GCompute.PrintDebug ("Testing linked list:")
		local linkedList = GCompute.Containers.LinkedList ()
		GCompute.PrintDebug ("+2, +3, +5, 0+, -5, -2")
		local remove = LinkedList:AddLast (2)
		linkedList:AddLast (3)
		local remove2 = LinkedList:AddLast (5)
		linkedList:AddFirst (0)
		linkedList:Remove (remove2)
		linkedList:Remove (remove)
		GCompute.PrintDebug (linkedList:ToString ())
		local endTime = SysTime ()
		GCompute.PrintDebug ("Test 1 took " .. tostring (math.floor ((endTime - startTime) * 100000 + 0.5) * 0.01) .. "ms.")
	end)
end