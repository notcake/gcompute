local self = {}
GCompute.NameResolutionPass = GCompute.MakeConstructor (self, GCompute.CompilerPass)

--[[
	This pass:
		1. Processes using directives and resolves them.
		2. Resolves variable declaration types, function declaration return and argument types
		3. Resolves name lookups, excluding function calls
]]

function self:Process (compilationUnit, rootBlock)
	self:ProcessBlock (compilationUnit, rootBlock)
end

function self:ProcessBlock (compilationUnit, block)	
	for statement in block:GetEnumerator () do
		if statement:Is ("Expression") then
		elseif statement:Is ("ForLoop") then
			if statement.Initializer:Is ("VariableDeclaration") then
				self:ProcessVariableDeclaration (compilationUnit, statement.Scope, statement.Initializer)
			end
			self:ProcessBlock (compilationUnit, statement.Loop)
		elseif statement:Is ("IfStatement") then
			self:ProcessBlock (compilationUnit, statement.Statement)
			
			if statement.Else then
				self:ProcessBlock (compilationUnit, Statement.Else)
			end
		elseif statement:Is ("Control") then
		elseif statement:Is ("FunctionDeclaration") then
			local functionObject = statement:GetFunction ()
			
			functionObject:SetReturnType (self:ProcessType (compilationUnit, block.Scope, statement.ReturnType))
			
			-- add function argument data
			for i = 1, statement:GetArgumentCount () do
				functionObject:SetArgumentType (i, self:ProcessType (compilationUnit, block.Scope, statement:GetArgumentType (i)))
			end
			self:ProcessBlock (compilationUnit, statement.Block)
		elseif statement:Is ("VariableDeclaration") then
			self:ProcessVariableDeclaration (compilationUnit, block.Scope, statement)
		else
			compilationUnit:Error ("NameResolutionPass: Unhandled AST node " .. statement.__Type .. " (" .. statement:ToString () .. ")", statement:GetSourceLine (), statement:GetSourceCharacter ())
		end
	end
end

function self:ProcessVariableDeclaration (compilationUnit, scope, variableDeclaration)
	scope:SetMemberType (variableDeclaration.Name, self:ProcessType (compilationUnit, scope, variableDeclaration.Type))
end

function self:ProcessType (compilationUnit, scope, typeNode)
	GCompute.NameResolver:Resolve (scope, typeNode)
	
	for result in typeNode.NameResolutionResults:GetEnumerator () do
		return result:GetValue ()
	end
	
	compilationUnit:Error ("NameResolutionPass:ProcessType : Failed to resolve type " .. typeNode:ToString () .. ".", typeNode:GetSourceLine (), typeNode:GetSourceCharacter ())
end