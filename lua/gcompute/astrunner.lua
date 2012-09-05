local self = {}
GCompute.ASTRunner = GCompute.MakeConstructor (self)

function self:ctor ()
	self.NodeStack = GCompute.Containers.Stack ()
	self.StateStack = GCompute.Containers.Stack ()
	self.ValueStack = GCompute.Containers.Stack ()
end

function self:Execute ()
	self:Resume ()
end

function self:PeekNode (offset)
	return self.NodeStack:Peek (offset)
end

function self:PeekState (offset)
	return self.StateStack:Peek (offset)
end

function self:PeekValue (offset)
	return self.ValueStack:Peek (offset)
end

function self:PopNode ()
	-- print (string.rep (" ", self.NodeStack.Count - 1) .. "POP: " .. self.NodeStack.Top:ToString ())
	return self.NodeStack:Pop ()
end

function self:PopState ()
	return self.StateStack:Pop ()
end

function self:PopValue ()
	-- print (string.rep (" ", self.ValueStack.Count - 1) .. "POP: " .. tostring (self.ValueStack.Top))
	return self.ValueStack:Pop ()
end

function self:PushNode (astNode)
	-- print (string.rep (" ", self.NodeStack.Count) .. "PUSH: " .. astNode:ToString ())
	self.NodeStack:Push (astNode)
end

function self:PushState (state)
	self.StateStack:Push (state)
end

function self:PushValue (value)
	-- print (string.rep (" ", self.ValueStack.Count) .. "PUSH: " .. tostring (value))
	self.ValueStack:Push (value)
end

function self:Resume ()
	for i = 1, 1000 do
		local topNode = self.NodeStack.Top
		if not topNode then
			self:PopNode ()
			print ("Done.")
			return
		end
		local state = self.StateStack:Pop ()
		-- print (("    "):rep (self.NodeStack.Count) .. (topNode and topNode:GetNodeType () or "nil") .. ":" .. (state or 0))
		if topNode.ExecuteAsAST then
			topNode:ExecuteAsAST (self, state)
		elseif topNode:Is ("WhileLoop") then
			-- state 0: evaluate condition
			-- state 1: check condition value, evaluate block
			if state == 0 then
				self.StateStack:Push (1)
				
				-- expression, state 0
				self.NodeStack:Push (topNode:GetCondition ())
				self.StateStack:Push (0)
			else
				local value = self.ValueStack:Pop ()
				if value then
					self.StateStack:Push (0)
					
					-- block, state 0
					self.NodeStack:Push (topNode:GetBody ())
					self.StateStack:Push (0)
				else
					-- while loop done
					self.NodeStack:Pop ()
				end
			end
		else
			ErrorNoHalt ("Unknown node type " .. topNode:GetNodeType () .. "\n")
			self.NodeStack:Pop ()
		end
	end
	
	executionContext:PushResumeFunction (
		function ()
			self:Resume ()
		end
	)
end