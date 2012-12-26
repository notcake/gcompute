local self = {}
GCompute.AssignmentPlan = GCompute.MakeConstructor (self)

function self:ctor ()
	self.AssignmentType = GCompute.AssignmentType.None
	self.CachedLeft = nil
	self.LeftRuntimeName = nil
end

function self:GetAssignmentType ()
	return self.AssignmentType
end

function self:SetAssignmentType (assignmentType)
	self.AssignmentType = assignmentType
end

function self:SetLeftRuntimeName (runtimeName)
	self.LeftRuntimeName = runtimeName
end

function self:ExecuteAsAST (astRunner, node, state)
	-- State 0: Evaluate left
	-- State 1: Evaluate right
	-- State 2: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
	
		-- Expression, state 0
		-- astRunner:PushNode (node:GetLeftExpression ())
		-- astRunner:PushState (0)
	elseif state == 1 then
		-- Return to state 2
		astRunner:PushState (2)
		
		-- Expression, state 0
		astRunner:PushNode (node:GetRightExpression ())
		astRunner:PushState (0)
	elseif state == 2 then
		-- Discard BinaryAssignmentOperator
		astRunner:PopNode ()
		
		local right = astRunner:PopValue ()
		if right == nil then
			executionContext:GetProcess ():GetStdErr ():WriteLine ("AssignmentPlan:ExecuteAsAST : right expression evaluated to nil! (" .. node:GetRightExpression ():ToString () .. ")")
		end
		
		if self.AssignmentType == GCompute.AssignmentType.NamespaceMember then
			if not self.CachedLeft then
				self.CachedLeft = __
			end
			self.CachedLeft [self.LeftRuntimeName] = right
		elseif self.AssignmentType == GCompute.AssignmentType.Local then
			executionContext.TopStackFrame [self.LeftRuntimeName] = right
		else
			error ("AssignmentPlan : Unsupported left type of " .. GCompute.AssignmentType [self.AssignmentType] .. " in " .. node:ToString () .."\n")
		end
		astRunner:PushValue (right)
	end
end