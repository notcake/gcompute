local self = {}
GCompute.Compiler2 = GCompute.MakeConstructor (self, GCompute.CompilerPass)

function self:Process (compilationUnit, rootBlock)
	self:ProcessBlock (compilationUnit, rootBlock)
end

function self:ProcessBlock (compilationUnit, block)
	local Block = GCompute.AST.Block ()
	
	block:SetOptimizedBlock (Block)
	block:GetScope ().OptimizedBlock = Block
	
	Block.Scope = block:GetScope ()
	Block:SetBlockType (block:GetBlockType ())
	Block:SetOptimized (true)
	
	for statement in block:GetEnumerator () do
		if statement:Is ("Expression") then
			Block:AddStatement (statement)
		elseif statement:Is ("ForLoop") then
			Block:AddStatement (statement)
			self:ProcessBlock (compilationUnit, statement.Loop)
		elseif statement:Is ("IfStatement") then
			Block:AddStatement (statement)
			self:ProcessBlock (compilationUnit, statement.Statement)
			
			if statement.Else then
				self:ProcessBlock (compilationUnit, statement.Else)
			end
		elseif statement:Is ("Control") then
			Block:AddStatement (statement)
		elseif statement:Is ("FunctionDeclaration") then
			self:ProcessBlock (compilationUnit, statement.Block)
		elseif statement:Is ("VariableDeclaration") then
			if statement.Value then
				local Assignment = GCompute.AST.BinaryAssignmentOperator ()
				Assignment:SetOperator ("=")
				Assignment.Left = GCompute.AST.Identifier ()
				Assignment.Left:SetName (statement.Name)
				Assignment.Right = statement.Value
				Block:AddStatement (Assignment)
			end
		else
			compilationUnit:Error ("Compiler2: Unhandled AST node " .. statement:GetNodeType () .. " (" .. statement:ToString () .. ")")
		end
	end
end