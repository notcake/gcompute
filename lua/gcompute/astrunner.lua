local self = {}
GCompute.ASTRunner = GCompute.MakeConstructor (self)

function self:ctor (ast)
	self.AST = ast
	self.NodeStack = GCompute.Containers.Stack ()
	self.StateStack = GCompute.Containers.Stack ()
	self.ValueStack = GCompute.Containers.Stack ()
end

function self:Execute (executionContext)
	self.NodeStack:Push (self.AST)
	self.StateStack:Push (0)
	self:Resume (executionContext)
end

function self:Resume (executionContext)
	for i = 1, 1000 do
		local topNode = self.NodeStack.Top
		local state = self.StateStack:Pop ()
		print (("    "):rep (self.NodeStack.Count) .. (topNode and topNode:GetNodeType () or "nil"))
		if topNode:Is ("Block") then
			self.StateStack:Push (state + 1)
			
			if state >= topNode:GetStatementCount () then
				self.NodeStack:Pop ()
				self.StateStack:Pop ()
			else
				self.NodeStack:Push (topNode:GetStatement (state + 1))
				self.StateStack:Push (0)
			end
		elseif topNode:Is ("IfStatement") then
			-- state 2n: evaluate condition n
			-- state 2n + 1: check condition value, evaluate block
			self.StateStack:Push (state + 1)
			if state % 2 == 0 then
				local condition = topNode:GetCondition (state / 2 + 1)
				
				if not condition then
					-- discard if statement
					self.NodeStack:Pop ()
					self.StateStack:Pop ()
				
					-- else block
					if topNode:GetElseStatement () then
						self.NodeStack:Push (topNode:GetElseStatement ())
						self.StateStack:Push (0)
					end
				else
					-- expression, state 0
					self.NodeStack:Push (condition)
					self.StateStack:Push (0)
				end
			else
				local value = self.ValueStack:Pop ()
				if value then
					-- discard if statement
					self.NodeStack:Pop ()
					self.StateStack:Pop ()
					
					-- body block
					self.NodeStack:Push (topNode:GetConditionBody ((state - 1) / 2 + 1))
					self.StateStack:Push (0)
				else
					-- next condition
				end
			end
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
		elseif topNode:Is ("BinaryExpression") then
		elseif topNode:Is ("FunctionCall") then
			-- state 0: evaluate left
			-- state 2+: evaluate arguments
			-- state 1: call
			if state == 0 then
				self.StateStack:Push (2)
				
				-- expression, state 0
				self.NodeStack:Push (topNode:GetLeftExpression ())
				self.StateStack:Push (0)
			elseif state == 1 then
				-- discard function call
				self.NodeStack:Pop ()
				
				local arguments = {}
				for i = topNode:GetArgumentCount (), 1, -1 do
					arguments [i] = self.ValueStack:Pop ()
				end
				local func = self.ValueStack:Pop ()
				func (unpack (arguments))
			else
				if state - 1 <= topNode:GetArgumentCount () then
					self.StateStack:Push (state + 1)
					
					-- expression, state 0
					self.NodeStack:Push (topNode:GetArgument (state - 1))
					self.StateStack:Push (1)
				else
					-- no more arguments
					self.StateStack:Push (1)
				end
			end
		elseif topNode:Is ("Identifier") then
			self.NodeStack:Pop ()
			self.ValueStack:Push (topNode.ResolutionResults:GetResult (1).Result)
		else
			ErrorNoHalt ("Unknown node type " .. topNode:GetNodeType () .. "\n")
			self.NodeStack:Pop ()
		end
	end

	executionContext:GetThread ():Yield (
		function (executionContext)
			self:Resume (executionContext)
		end
	)
end