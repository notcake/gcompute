local self = {}
GCompute.MemberFunctionCall = GCompute.MakeConstructor (self, GCompute.FunctionCall)

function self:ctor ()
	self.TypeArgumentList = nil
	
	self:SetHasPrependedArgument (true)
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Member lookup
	-- State 2: Evaluate arguments
	-- State 3: Call
	if state == 0 then
		-- Return to state 1
		astRunner:PushState (1)
		
		-- Expression, state 0
		astRunner:PushNode (self:GetLeftExpression ())
		astRunner:PushState (0)
	elseif state == 1 then
		-- Return to state 2
		astRunner:PushState (2)
		
		local leftValue = astRunner:PopValue ()
		astRunner:PushValue (leftValue)
		
		if self.FunctionDefinition then
			astRunner:PushValue (self.FunctionDefinition)
		elseif self.Function then
			astRunner:PushValue (self.Function)
		else
			astRunner:PushValue (leftValue.FunctionTable.Virtual [self.FunctionName])
		end
	elseif state == 2 then
		self.__base.ExecuteAsAST (self, astRunner, state)
	elseif state == 3 then
		self.__base.ExecuteAsAST (self, astRunner, state)
	end
end

function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:IsMemberFunctionCall ()
	return true
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	return leftExpression .. ":" .. (self.FunctionName or "[Nothing]") .. (self.TypeArgumentList and (" " .. self.TypeArgumentList:ToString ()) or "") .. argumentList
end