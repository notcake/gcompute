local Tree = {}
GCompute.Containers.Tree = GCompute.MakeConstructor (Tree)

function Tree:ctor (value)
	self.Value = value
	self.Children = GCompute.Containers.LinkedList ()
	self.ChildCount = 0
end

function Tree:Add (Value)
	local Child = GCompute.Containers.Tree (Value)
	self.Children:AddLast (Child)
	self.ChildCount = self.ChildCount + 1
	return Child
end

function Tree:AddNode (Tree)
	if type (Tree) ~= "table" then
		GCompute.PrintStackTrace ()
	end
	self.Children:AddLast (Tree)
	self.ChildCount = self.ChildCount + 1
	return Tree
end

function Tree:AddRange (Array)
	for _, Value in ipairs (Array) do
		self.Children:AddLast (GCompute.Containers.Tree ()).Value.Value = Value
		self.ChildCount = self.ChildCount + 1
	end
end

function Tree:Clear ()
	self.Children:Clear ()
	self.ChildCount = 0
end

function Tree:FindChild (value)
	for LinkedListNode in self.Children:GetEnumerator () do
		if LinkedListNode.Value.Value == value then
			return LinkedListNode.Value
		end
	end
	return nil
end

function Tree:GetChild (n)
	return self.Children:GetItem (n)
end

function Tree:GetChildCount ()
	return self.ChildCount
end

function Tree:GetFirstChild ()
	if not self.Children.First then
		return
	end
	return self.Children.First.Value
end

function Tree:GetEnumerator ()
	local Enumerator = self.Children:GetEnumerator ()
	return function ()
		local ChildNode = Enumerator ()
		if not ChildNode then
			return nil
		end
		return ChildNode.Value
	end
end

function Tree:RemoveLast ()
	if not self.Children.Last then
		return
	end
	self.ChildCount = self.ChildCount - 1
	self.Children:Remove (self.Children.Last)
end

function Tree:ToString (indent)
	indent = indent or 0
	local String = string.rep ("  ", indent) .. "+" .. tostring (self.Value)
	
	for LinkedListNode in self.Children:GetEnumerator () do
		local TreeNode = LinkedListNode.Value
		local Value
		if TreeNode then
			Value = TreeNode:ToString (indent + 1)
		else
			Value = string.rep ("  ", indent + 1) .. "+[nil]"
		end
		String = String .. "\n" .. Value
	end
	return String
end