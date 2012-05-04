local Block = {}
Block.__Type = "Block"
GCompute.AST.Block = GCompute.AST.MakeConstructor (Block)

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

function Block:ctor ()
	self.Children = {}
	self.Count = 0
	
	self.Scope = GCompute.Scope ()	-- definition Scope
	self.BlockType = BlockType.Block
	
	self.OptimizedBlock = nil
	self.Optimized = false
end

function Block:AddNode (node)
	self.Children [#self.Children + 1] = node
	self.Count = self.Count + 1
end

function Block:Evaluate (executionContext)
	-- Function scopes are pushed onto the stack by the Function class in order to set parameters, not here.
	local pushedScope = false
	if self.Scope:HasVariables () and self.BlockType ~= BlockType.Function then
		pushedScope = true
		executionContext:PushBlockScope (self.Scope)
	end
	
	local statements = self:GetOptimizedBlock ():GetNodes ()
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

function Block:GetBlockType ()
	return self.BlockType
end

function Block:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Children [i]
	end
end

function Block:GetNodes ()
	return self.Children
end

function Block:GetOptimizedBlock ()
	return self.OptimizedBlock or self
end

function Block:GetScope ()
	return self.Scope
end

function Block:IsOptimized ()
	return self.Optimized
end

function Block:SetBlockType (blockType)
	self.BlockType = blockType
end

function Block:SetOptimized (optimized)
	self.Optimized = optimized
end

function Block:SetOptimizedBlock (optimizedBlock)
	self.OptimizedBlock = optimizedBlock
end

function Block:ToString ()
	local content = ""
	for item in self:GetEnumerator () do
		content = content .. "\n    " .. item:ToString ():gsub ("\n", "\n    ")
		if item:Is ("Expression") or item:Is ("VariableDeclaration") or item:Is ("Control") then
			content = content .. ";"
		end
	end
	return "[" .. (BlockTypeLookup [self.BlockType] or "?") .. "]\n{" .. content .. "\n}"
end