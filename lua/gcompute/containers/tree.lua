local Tree = {}
Tree.__index = Tree

function GCompute.Containers.Tree (...)
	local Object = {}
	setmetatable (Object, Tree)
	Object:ctor (...)
	return Object
end

function Tree:ctor (Value)
	self.Value = Value
	self.Children = nil
	self.ChildCount = 0
end

function Tree:Add (Value)
	local Child = GCompute.Containers.Tree (Value)
	if not self.Children then
		self.Children = GCompute.Containers.LinkedList ()
	end
	self.Children:AddLast (Child)
	self.ChildCount = self.Children.Count + 1
	return Child
end

function Tree:AddNode (Tree)
	if type (Tree) ~= "table" then
		CAdmin.Debug.PrintStackTrace ()
	end
	if not self.Children then
		self.Children = GCompute.Containers.LinkedList ()
	end
	self.Children:AddLast (Tree)
	self.ChildCount = self.Children.Count + 1
	return Tree
end

function Tree:AddRange (Array)
	if not self.Children then
		self.Children = GCompute.Containers.LinkedList ()
	end
	for _, Value in ipairs (Array) do
		self.Children:AddLast (GCompute.Containers.Tree ()).Value.Value = Value
		self.ChildCount = self.Children.Count + 1
	end
end

function Tree:Clear ()
	if self.Children then
		self.Children:Clear ()
	end
	self.Count = 0
end

function Tree:FindChild (Value)
	if not self.Children or
		not self.Children.First then
		return
	end
	local Current = self.Children.First
	while Current do
		if Current.Value.Value == Value then
			return Current.Value
		end
		Current = Current.Next
	end
	return nil
end

function Tree:GetFirstChild ()
	if not self.Children or
		not self.Children.First then
		return
	end
	return self.Children.First.Value
end

function Tree:GetEnumerator ()
	if not self.Children then
		return function ()
			return nil
		end
	end
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
	if not self.Children or
		not self.Children.Last then
		return
	end
	self.ChildCount = self.ChildCount - 1
	self.Children:Remove (self.Children.Last)
end

function Tree:ToString (Indent)
	if not Indent then
		Indent = 0
	end
	local String = string.rep (" ", Indent) .. "+" .. tostring (self.Value)
	if self.Children then
		for Child in self.Children:GetEnumerator () do
			local Value = Child.Value
			if Value then
				Value = Value:ToString (Indent + 1)
			else
				Value = string.rep (" ", Indent + 1) .. "+[nil]"
			end
			String = String .. "\n" .. Value
		end
	end
	return String
end