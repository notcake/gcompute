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
	self.Statements = {}
	self.StatementCount = 0
	
	self.NamespaceDefinition = nil -- NamespaceDefinition or TypeDefinition
	
	-- TODO: Remove this
	self.Scope = GCompute.Scope ()	-- definition Scope
	self.BlockType = BlockType.Block
	
	self.OptimizedBlock = nil
	self.Optimized = false
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

function self:GetBlockType ()
	return self.BlockType
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Statements [i]
	end
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

function self:SetStatement (index, statement)
	self.Statements [index] = statement
end

function self:ToString ()
	local content = ""
	for item in self:GetEnumerator () do
		content = content .. "\n    " .. item:ToString ():gsub ("\n", "\n    ")
		if item.Is then
			if item:Is ("Expression") or item:Is ("VariableDeclaration") or item:Is ("Control") then
				content = content .. ";"
			end
		end
	end
	return "[" .. (BlockTypeLookup [self.BlockType] or "?") .. "]\n{" .. content .. "\n}"
end