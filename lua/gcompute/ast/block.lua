local self = {}
self.__Type = "Block"
GCompute.AST.Block = GCompute.AST.MakeConstructor (self)

local BlockType =
{
	Global				= 1,
	Function			= 2,
	AnonymousFunction	= 3,
	Block				= 4
}
GCompute.AST.BlockType = BlockType

local BlockTypeLookup =
{
	[BlockType.Global]				= "GlobalBlock",
	[BlockType.Function]			= "FunctionBlock",
	[BlockType.AnonymousFunction]	= "AnonymousFunctionBlock",
	[BlockType.Block]				= "Block"
}

function self:ctor ()
	self.BlockType = BlockType.Block
	
	self.Statements = {}
	self.StatementCount = 0
	
	self.NamespaceDefinition = nil -- NamespaceDefinition or ClassDefinition
	self.PopStackFrame = false
end

function self:AddStatement (node)	
	self.Statements [#self.Statements + 1] = node
	self.StatementCount = self.StatementCount + 1
	if node then node:SetParent (self) end
end

function self:AddStatements (statements)
	for _, statement in ipairs (statements) do
		self:AddStatement (statement)
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.Statements)
	for statement in self:GetEnumerator () do
		statement:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.NamespaceDefinition then
		self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Evaluate (executionContext)
	-- Function scopes are pushed onto the stack by the Function class in order to set parameters, not here.
	local pushedScope = false
	if self.Scope:HasVariables () and self.BlockType ~= BlockType.Function then
		pushedScope = true
		executionContext:PushBlockScope (self.Scope)
	end
	
	local statements = self:GetOptimizedBlock ():GetStatements ()
	local statementCount = #statements
	for i = 1, statementCount do
		statements [i]:Evaluate (executionContext)
		if executionContext.InterruptFlag then
			break
		end
	end
	
	if pushedScope then
		executionContext:PopScope ()
	end
end

function self:ExecuteAsAST (astRunner, state)
	if executionContext.InterruptFlag then
		if self:GetMergedLocalScope () or self.PopStackFrame then
			executionContext:PopStackFrame ()
		end
		
		astRunner:PopNode ()
		
		if executionContext.ReturnFlag and self:GetBlockType () == GCompute.AST.BlockType.Function then
			astRunner:PushValue (executionContext:ClearReturn ())
		end
		return
	end
	
	astRunner:PushState (state + 1)
	
	if state == 0 and self:GetMergedLocalScope () and self:GetBlockType () ~= GCompute.AST.BlockType.Function then
		executionContext:PushStackFrame (self:GetMergedLocalScope ():CreateStackFrame ())
	end
	
	if state > 0 then
		local statement = self:GetStatement (state)
		if statement:Is ("Expression") then
			-- Discard last Expression value
			astRunner:PopValue ()
		elseif statement:Is ("VariableDeclaration") and statement:GetRightExpression () then
			-- Discard BinaryAssignmentOperator value
			astRunner:PopValue ()
		end
	end
	
	if state >= self:GetStatementCount () then
		astRunner:PopNode ()
		astRunner:PopState ()
	else
		astRunner:PushNode (self:GetStatement (state + 1))
		astRunner:PushState (0)
	end
end

function self:GetBlockType ()
	return self.BlockType
end

function self:GetChildEnumerator ()
	return self:GetEnumerator ()
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Statements [i]
	end
end

function self:GetMergedLocalScope ()
	return self:GetNamespace () and self:GetNamespace ():GetMergedLocalScope ()
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetStatement (index)
	return self.Statements [index]
end

function self:GetStatementCount ()
	return self.StatementCount
end

function self:GetStatements ()
	return self.Statements
end

function self:GetOptimizedBlock ()
	return self.OptimizedBlock or self
end

function self:GetScope ()
	return self.Scope
end

function self:IsOptimized ()
	return self.Optimized
end

function self:SetBlockType (blockType)
	self.BlockType = blockType
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:SetOptimized (optimized)
	self.Optimized = optimized
end

function self:SetOptimizedBlock (optimizedBlock)
	self.OptimizedBlock = optimizedBlock
end

function self:SetPopStackFrame (popStackFrame)
	self.PopStackFrame = popStackFrame
end

function self:SetStatement (index, statement)
	self.Statements [index] = statement
end

function self:ToString ()
	local block = "[" .. (BlockTypeLookup [self.BlockType] or "?") .. "]\n{\n"
	if self.NamespaceDefinition and not self.NamespaceDefinition:IsEmpty () then
		block = block .. "    " .. self.NamespaceDefinition:ToString ():gsub ("\n", "\n    ") .. "\n    \n"
	end
	
	local contents = {}
	for item in self:GetEnumerator () do
		local content = "    " .. item:ToString ():gsub ("\n", "\n    ")
		if item.Is then
			if item:Is ("Expression") or item:Is ("VariableDeclaration") or item:Is ("Control") then
				content = content .. ";"
			end
		end
		contents [#contents + 1] = content
	end
	block = block .. table.concat (contents, "\n") .. "\n}"
	return block
end

function self:Visit (astVisitor, ...)
	local astOverride = astVisitor:VisitBlock (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
	
	for i = 1, self:GetStatementCount () do
		self:SetStatement (i, self:GetStatement (i):Visit (astVisitor, ...) or self:GetStatement (i))
	end
end
