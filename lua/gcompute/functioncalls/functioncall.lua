local self = {}
GCompute.FunctionCall = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LeftExpression    = nil
	self.MethodName        = nil
	self.FunctionType      = nil
	
	self.ArgumentList      = nil
	self.PrependedArgument = false
	
	-- Runtime caching
	self.MethodDefinition  = nil
	self.Function          = nil
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Nothing
	-- State 2: Evaluate arguments
	-- State 3: Call
	if state == 0 then
		-- Return to state 2
		astRunner:PushState (2)
		
		if self.MethodDefinition then
			astRunner:PushValue (self.MethodDefinition)
		elseif self.Function then
			astRunner:PushValue (self.Function)
		elseif self.LeftExpression then
			-- Expression, state 0
			astRunner:PushNode (self:GetLeftExpression ())
			astRunner:PushState (0)
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no native function, MethodDefinition or left expression provided)\n")
		end
	elseif state == 2 then
		-- Return to state 3
		astRunner:PushState (3)
		
		-- ArgumentList, state 0
		astRunner:PushNode (self:GetArgumentList ())
		astRunner:PushState (0)
	elseif state == 3 then
		-- Discard ASTNode
		astRunner:PopNode ()
		
		-- Generate arguments array
		local arguments = {}
		
		for i = self.ArgumentList:GetArgumentCount (), 1, -1 do
			arguments [i] = astRunner:PopValue ()
		end
		
		local nativeFunctionOrMethodDefinition = astRunner:PopValue ()
		local methodDefinition = nil
		local nativeFunction
		if type (nativeFunctionOrMethodDefinition) == "table" then
			methodDefinition = nativeFunctionOrMethodDefinition
			nativeFunction = methodDefinition:GetNativeFunction ()
		else
			nativeFunction = nativeFunctionOrMethodDefinition
		end
		
		local prependedArgument = nil
		if self.PrependedArgument then
			prependedArgument = astRunner:PopValue ()
		end
		
		if nativeFunction then
			if self.PrependedArgument then
				astRunner:PushValue (nativeFunction (prependedArgument, unpack (arguments)))
			else
				astRunner:PushValue (nativeFunction (unpack (arguments)))
			end
		elseif methodDefinition then
			local functionDeclaration = methodDefinition:GetFunctionDeclaration ()
			local namespace = methodDefinition:GetNamespace ()
			local mergedLocalScope = methodDefinition:GetMergedLocalScope ()
			local block = functionDeclaration:GetBody ()
			if block then
				if mergedLocalScope then
					local stackFrame = mergedLocalScope:CreateStackFrame ()
					executionContext:PushStackFrame (stackFrame)
					
					for i = 1, methodDefinition:GetParameterCount () do
						stackFrame [mergedLocalScope:GetRuntimeName (namespace:GetMember (methodDefinition:GetParameterName (i)))] = arguments [i]
					end
					if self.PrependedArgument then
						stackFrame ["this"] = prependedArgument
					end
				end
			
				astRunner:PushNode (block)
				astRunner:PushState (0)
			else
				astRunner:PushValue (nil)
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (MethodDefinition has no native function or AST block node)\n")
			end
		else
			astRunner:PushValue (nil)
			ErrorNoHalt ("Failed to call " .. self.MethodName .. " (no native function or MethodDefinition)\n")
		end
	end
end

function self:GetArgument (index)
	return self.ArgumentList:GetArgument (index)
end

function self:GetArgumentCount ()
	return self.ArgumentList:GetArgumentCount ()
end

function self:GetArgumentList ()
	return self.ArgumentList
end

function self:GetFunction ()
	return self.Function
end

function self:GetFunctionType ()
	return self.FunctionType
end

function self:GetMethodDefinition ()
	return self.MethodDefinition
end

function self:GetMethodName ()
	return self.MethodName
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:HasPrependedArgument ()
	return self.PrependedArgument
end

function self:IsMemberFunctionCall ()
	return false
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
end

function self:SetFunction (f)
	self.Function = f
end

function self:SetMethodName (methodName)
	self.MethodName = methodName
end

function self:SetFunctionType (functionType)
	self.FunctionType = functionType
end

function self:SetHasPrependedArgument (hasPrependedArgument)
	self.PrependedArgument = hasPrependedArgument
end

function self:SetMethodDefinition (methodDefinition)
	self.MethodDefinition = methodDefinition
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
end

function self:ToString ()
	if self.LeftExpression then
		return self.LeftExpression:ToString () .. " " .. (self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])")
	end
	return (self.MethodName or "[Nothing]") .. " " .. (self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])")
end