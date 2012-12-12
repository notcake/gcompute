local self = {}
self.__Type = "New"
GCompute.AST.New = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	
	self.ArgumentList = GCompute.AST.ArgumentList ()
	
	self.NativelyAllocated = false
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.ArgumentList then
		self.ArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0: Evaluate left
	-- State 1: Nothing
	-- State 2: Evaluate arguments
	-- State 3: Call
	if state == 0 then
		-- Return to state 2
		astRunner:PushState (2)
		
		local functionCallPlan = self.FunctionCallPlan
		if functionCallPlan:GetFunctionDefinition () then
			astRunner:PushValue (functionCallPlan:GetFunctionDefinition ())
		elseif functionCallPlan:GetFunction () then
			astRunner:PushValue (functionCallPlan:GetFunction ())
		else
			-- Expression, state 0
			astRunner:PushNode (self:GetLeftExpression ())
			astRunner:PushState (0)
		end
	elseif state == 2 then
		-- Return to state 3
		astRunner:PushState (3)
		
		-- ArgumentList, state 0
		astRunner:PushNode (self:GetArgumentList ())
		astRunner:PushState (0)
	elseif state == 3 then
		-- Discard FunctionCall
		astRunner:PopNode ()
		
		local arguments = {}
		for i = self:GetArgumentList ():GetArgumentCount (), 1, -1 do
			arguments [i] = astRunner:PopValue ()
		end
		local functionDefinition = astRunner:PopValue ()
		local func = functionDefinition
		if type (functionDefinition) == "table" then
			func = functionDefinition:GetNativeFunction ()
		else
			functionDefinition = nil
		end
		
		if func then
			astRunner:PushValue (func (unpack (arguments)))
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
				end
			
				astRunner:PushNode (block)
				astRunner:PushState (0)
			else
				ErrorNoHalt ("Failed to run " .. self:ToString () .. " (FunctionDefinition has no native function or AST block node)\n")
			end
		else
			ErrorNoHalt ("Failed to run " .. self:ToString () .. " (no function or FunctionDefinition)\n")
		end
	end
end

function self:GetArgumentList ()
	return self.ArgumentList
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.ArgumentList
		end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:IsNativelyAllocated ()
	return self.NativelyAllocated
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
	if self.ArgumentList then self.ArgumentList:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetNativelyAllocated (nativelyAllocated)
	self.NativelyAllocated = nativelyAllocated
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	
	return "new " .. leftExpression .. " " .. argumentList
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	
	return astVisitor:VisitExpression (self, ...)
end