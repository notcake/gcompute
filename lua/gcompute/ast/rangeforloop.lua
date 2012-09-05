local self = {}
self.__Type = "RangeForLoop"
GCompute.AST.RangeForLoop = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.LoopVariable = nil -- VariableDeclaration or QualifiedIdentifier
	self.Range = {}
	
	self.LoopVariableValue = GCompute.AST.NumericLiteral (0)
	
	self.LoopVariableAssignment = GCompute.AST.BinaryAssignmentOperator ()
	self.LoopVariableAssignment:SetOperator ("=")
	self.LoopVariableAssignment:SetRightExpression (self.LoopVariableValue)
	self.LoopVariableAssignment:SetParent (self)
	
	self.NamespaceDefinition = nil
	self.Body = nil
end

function self:AddValue (n)
	self.Range [#self.Range + 1] = { n }
	if n then n:SetParent (self) end
end

function self:AddRange (startValue, endValue, increment)
	self.Range [#self.Range + 1] = { startValue, endValue, increment }
	
	if #self.Range == 1 then
		-- Set the right expression of the assignment to the start value so
		-- that the type inferer will use its type for the left variable declaration
		-- later on
		self.LoopVariableAssignment:SetRightExpression (startValue)
	end
	
	if startValue then startValue:SetParent (self) end
	if endValue then endValue:SetParent (self) end
	if increment then increment:SetParent (self) end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.Range)
	
	for _, rangeEntry in ipairs (self.Range) do
		for _, expression in ipairs (rangeEntry) do
			expression:ComputeMemoryUsage (memoryUsageReport)
		end
	end
	
	if self.LoopVariable then
		self.LoopVariable:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.Body then
		self.Body:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.NamespaceDefinition then
		self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate (executionContext)
end

function self:ExecuteAsAST (astRunner, state)
	-- State 0 - n: Compute ranges
	-- State -1: Assign loop variable, run loop
	-- State -2: Check loop variable
	
	if state > 0 then
		-- Finished evaluating a range, jiggle it.
		if #self.Range [#self.Range - state + 1] == 1 then
			local startValue = astRunner:PopValue ()
			astRunner:PushValue ({ startValue })
		elseif #self.Range [#self.Range - state + 1] == 2 then
			local increment = 1
			local endValue = astRunner:PopValue ()
			local startValue = astRunner:PopValue ()
			astRunner:PushValue ({ startValue, endValue, increment })
		else
			local increment = astRunner:PopValue ()
			local endValue = astRunner:PopValue ()
			local startValue = astRunner:PopValue ()
			astRunner:PushValue ({ startValue, endValue, increment })
		end
	end
	
	if state == #self.Range then
		astRunner:PushState (-1)
		astRunner:PushValue (astRunner:PeekValue () [1])
	elseif state >= 0 then
		if state == 0 then
			self.LoopVariableAssignment:SetRightExpression (self.LoopVariableValue)
			astRunner:PushValue (nil)
		end
		astRunner:PushState (state + 1)
		
		if executionContext.InterruptFlag then
			while astRunner:PopValue () do end
			astRunner:PopNode ()
			return
		end
		
		local range = self.Range [#self.Range - state]
		if #range == 1 then
			-- Expression, state 0
			astRunner:PushNode (range [1])
			astRunner:PushState (0)
		elseif #range == 3 then
			-- Expression, state 0
			astRunner:PushNode (range [3])
			astRunner:PushState (0)
		end
		if #range >= 2 then
			-- Expression, state 0
			astRunner:PushNode (range [2])
			astRunner:PushState (0)
			
			-- Expression, state 0
			astRunner:PushNode (range [1])
			astRunner:PushState (0)
		end
	elseif state == -1 then
		-- Assign loop variable, increment variable, run loop
		local i = astRunner:PopValue ()
		astRunner:PushValue (i + (astRunner:PeekValue () [3] or 1))
		self.LoopVariableValue:SetNumber (i)
		
		-- Return to state -2
		astRunner:PushState (-2)
		
		-- Statement, state 0
		astRunner:PushNode (self.Body)
		astRunner:PushState (0)
		
		-- Expression, state 0
		astRunner:PushNode (self.LoopVariableAssignment)
		astRunner:PushState (0)
	elseif state == -2 then
		-- Discard loop variable assignment value
		astRunner:PopValue ()
		
		-- Clear continue flag
		if executionContext.ContinueFlag then
			executionContext:ClearContinue ()
		end
		
		-- Break or other interrupt
		if executionContext.InterruptFlag then
			if executionContext.BreakFlag then
				executionContext:ClearBreak ()
			end
			
			while astRunner:PopValue () do end
			astRunner:PopNode ()
			return
		end
	
		-- Check loop variable
		local i = astRunner:PeekValue ()
		local range = astRunner:PeekValue (-1)
		
		if not range [2] or i > range [2] then
			-- Done with this range.
			astRunner:PopValue () -- Pop i
			astRunner:PopValue () -- Pop range
			
			range = astRunner:PeekValue ()
			if not range then
				-- Done with this loop
				astRunner:PopValue () -- Pop nil
				astRunner:PopNode ()
			else
				-- Continue with next range
				astRunner:PushState (-1)
				astRunner:PushValue (range [1])
			end
		else
			-- Continue with current range
			astRunner:PushState (-1)
		end
	end
end

function self:GetBody ()
	return self.Body
end

function self:GetLoopVariable ()
	return self.LoopVariable
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:SetBody (statement)
	self.Body = statement
	if self.Body then self.Body:SetParent (self) end
end

function self:SetLoopVariable (loopVariable)
	self.LoopVariable = loopVariable
	self.LoopVariableAssignment:SetLeftExpression (loopVariable)
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:ToString ()
	local loopVariable = self.LoopVariable and self.LoopVariable:ToString () or "[Unknown Identifier]"
	local range = ""
	
	for _, rangeEntry in ipairs (self.Range) do
		if range ~= "" then range = range .. ", " end
		if #rangeEntry == 1 then
			range = range .. rangeEntry [1]:ToString ()
		else
			range = range .. rangeEntry [1]:ToString () .. ":" .. rangeEntry [2]:ToString ()
			if rangeEntry [3] then
				range = range .. ":" .. rangeEntry [3]:ToString ()
			end
		end
	end
	
	local bodyStatement = "    [Unknown Statement]"
	
	if self.Body then
		if self.Body:Is ("Block") then
			bodyStatement = self.Body:ToString ()
		else
			bodyStatement = "    " .. self.Body:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "for (" .. loopVariable .. " = " .. range .. ")\n" .. bodyStatement
end

function self:Visit (astVisitor, ...)
	local astOverride = astVisitor:VisitStatement (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
	
	self.LoopVariableAssignment:Visit (astVisitor, ...)
	for _, range in ipairs (self.Range) do
		for i = 1, #range do
			range [i] = range [i]:Visit (astVisitor, ...) or range [i]
		end
	end
	self:SetBody (self:GetBody ():Visit (astVisitor, ...) or self:GetBody ())
end