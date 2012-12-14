local self = {}
GCompute.FunctionCall = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LeftExpression = nil
	self.FunctionName = nil
	self.FunctionType = nil
	
	self.ArgumentList = nil
	self.PrependedArgument = false
	
	-- Runtime caching
	self.FunctionDefinition = nil
	self.Function = nil
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Nothing
	-- State 2: Evaluate arguments
	-- State 3: Call
	if state == 0 then
		-- Return to state 2
		astRunner:PushState (2)
		
		if self.FunctionDefinition then
			astRunner:PushValue (self.FunctionDefinition)
		elseif self.Function then
			astRunner:PushValue (self.Function)
		elseif self.LeftExpression then
			-- Expression, state 0
			astRunner:PushNode (self:GetLeftExpression ())
			astRunner:PushState (0)
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no native function, FunctionDefinition or left expression provided)\n")
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
		
		local nativeFunctionOrFunctionDefinition = astRunner:PopValue ()
		local functionDefinition = nil
		local nativeFunction
		if type (nativeFunctionOrFunctionDefinition) == "table" then
			functionDefinition = nativeFunctionOrFunctionDefinition
			nativeFunction = functionDefinition:GetNativeFunction ()
		else
			nativeFunction = nativeFunctionOrFunctionDefinition
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
		elseif functionDefinition then
			local functionDeclaration = functionDefinition:GetFunctionDeclaration ()
			local namespace = functionDeclaration:GetNamespace ()
			local mergedLocalScope = namespace:GetMergedLocalScope ()
			local block = functionDeclaration:GetBody ()
			if block then
				if mergedLocalScope then
					local stackFrame = mergedLocalScope:CreateStackFrame ()
					executionContext:PushStackFrame (stackFrame)
					
					for i = 1, functionDefinition:GetParameterCount () do
						stackFrame [mergedLocalScope:GetRuntimeName (namespace:GetMember (functionDefinition:GetParameterName (i)))] = arguments [i]
					end
					if self.PrependedArgument then
						stackFrame ["this"] = prependedArgument
					end
				end
			
				astRunner:PushNode (block)
				astRunner:PushState (0)
			else
				astRunner:PushValue (nil)
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (FunctionDefinition has no native function or AST block node)\n")
			end
		else
			astRunner:PushValue (nil)
			ErrorNoHalt ("Failed to call " .. self.FunctionName .. " (no native function or FunctionDefinition)\n")
		end
	end
end

function self:GetArgumentList ()
	return self.ArgumentList
end

function self:GetFunction ()
	return self.Function
end

function self:GetFunctionDefinition ()
	return self.FunctionDefinition
end

function self:GetFunctionName ()
	return self.FunctionName
end

function self:GetFunctionType ()
	return self.FunctionType
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

function self:SetFunctionDefinition (functionDefinition)
	self.FunctionDefinition = functionDefinition
end

function self:SetFunctionName (functionName)
	self.FunctionName = functionName
end

function self:SetFunctionType (functionType)
	self.FunctionType = functionType
end

function self:SetHasPrependedArgument (hasPrependedArgument)
	self.PrependedArgument = hasPrependedArgument
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
end

function self:ToString ()
	if self.LeftExpression then
		return self.LeftExpression:ToString () .. " " .. (self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])")
	end
	return (self.FunctionName and self.FunctionName or "[Nothing]") .. " " .. (self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])")
end