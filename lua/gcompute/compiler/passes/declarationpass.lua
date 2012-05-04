local self = {}
GCompute.DeclarationPass = GCompute.MakeConstructor (self, GCompute.CompilerPass)

--[[
	This pass:
		1. Registers namespace, class, function and variable declarations
		2. Sets up the scope hierarchy
		3. Sets up the resolution scope for TypeReferences
]]

function self:Process (compilationUnit, rootBlock)
	rootBlock.Scope:SetGlobalScope (GCompute.GlobalScope)
	rootBlock.Scope:SetParentScope (GCompute.GlobalScope)
	self:ProcessBlock (compilationUnit, rootBlock)
end

function self:ProcessBlock (compilationUnit, block)	
	for statement in block:GetEnumerator () do
		if statement:Is ("Expression") then
		elseif statement:Is ("ForLoop") then
			statement.Scope:SetGlobalScope (block.Scope:GetGlobalScope ())
			statement.Scope:SetParentScope (block.Scope)
			statement.Loop.Scope:SetGlobalScope (block.Scope:GetGlobalScope ())
			statement.Loop.Scope:SetParentScope (statement.Scope)
			if statement.Initializer:Is ("VariableDeclaration") then
				self:ProcessVariableDeclaration (compilationUnit, statement.Scope, statement.Initializer)
			end
			self:ProcessBlock (compilationUnit, statement.Loop)
		elseif statement:Is ("IfStatement") then
			statement.Statement.Scope:SetGlobalScope (block.Scope:GetGlobalScope ())
			statement.Statement.Scope:SetParentScope (block.Scope)
			self:ProcessBlock (compilationUnit, statement.Statement)
			
			if statement.Else then
				statement.Else.Scope:SetGlobalScope (block.Scope:GetGlobalScope ())
				statement.Else.Scope:SetParentScope (block.Scope)
				self:ProcessBlock (compilationUnit, Statement.Else)
			end
		elseif statement:Is ("Control") then
		elseif statement:Is ("FunctionDeclaration") then
			-- setup scope hierarchy
			statement.Block.Scope:SetGlobalScope (block.Scope:GetGlobalScope ())
			statement.Block.Scope:SetParentScope (block.Scope)
			
			local Function = block.Scope:AddFunction (statement.Name, "UnresolvedType")
			
			-- link function block and scope
			Function:SetBlock (statement.Block)
			Function:SetScope (statement.Block.Scope)
			
			-- link ast node to function
			statement:SetFunction (Function)
			
			-- add function argument data
			for i = 1, statement:GetArgumentCount () do
				Function:AddArgument ("UnresolvedType", statement:GetArgumentName (i))
				Function.Scope:AddMemberVariable ("UnresolvedType", statement:GetArgumentName (i))
			end
			self:ProcessBlock (compilationUnit, statement.Block)
		elseif statement:Is ("VariableDeclaration") then
			self:ProcessVariableDeclaration (compilationUnit, block.Scope, statement)
		else
			compilationUnit:Error ("DeclarationPass: Unhandled AST node " .. statement.__Type .. " (" .. statement:ToString () .. ")", statement:GetSourceLine (), statement:GetSourceCharacter ())
		end
	end
end

function self:ProcessVariableDeclaration (compilationUnit, scope, variableDeclaration)
	-- add variable to scope
	scope:AddMemberVariable ("UnresolvedType", variableDeclaration.Name)
end