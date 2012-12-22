local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleObjectResolver
		Operates on source file ASTs
		TODO: Operate on method ASTs
	
	1. Resolves using directives
	2. Resolves names
	3. Updates the type of function parameters in FunctionRoot NamespaceDefinitions
	
	This class should be generating ObjectResolutionResults
	using the ObjectResolver class and filtering them.
	Only the ObjectResolver class should be populating ObjectResolutionResults.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.ObjectResolver = GCompute.ObjectResolver2 ()
	for referencedModule in self.CompilationUnit:GetCompilationGroup ():GetModule ():GetReferencedModuleEnumerator () do
		self.ObjectResolver:AddRootNamespace (referencedModule:GetRootNamespace ())
	end
	self.ObjectResolver:AddRootNamespace (self.CompilationUnit:GetCompilationGroup ():GetRootNamespace ())
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement,
		function ()
			self.CompilationUnit:GetCompilationGroup ():GetRootNamespace ():ResolveTypes (self.CompilationUnit:GetCompilationGroup ():GetRootNamespace (), self.CompilationUnit)
			callback ()
		end
	)
end

function self:VisitRoot (blockStatement)
end

function self:VisitBlock (blockStatement)
	self:ResolveUsings (blockStatement)
end

function self:VisitStatement (statement)
	if statement:HasDefinition () then
		self:ResolveUsings (statement)
	end
	
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
	elseif statement:Is ("VariableDeclaration") then
		if statement:GetTypeExpression () then
			local typeResults = statement:GetTypeExpression ():GetResolutionResults ()
			typeResults:FilterToConcreteTypes ()
			typeResults:FilterByLocality ()
			
			local type = typeResults:GetFilteredResultObject (1)
			if not type then
				statement:GetTypeExpression ():AddErrorMessage ("Cannot resolve " .. statement:GetTypeExpression ():ToString () .. " as a type!")
			end
			statement:SetType (type or GCompute.ErrorType ())
			statement:GetVariableDefinition ():SetType (type or GCompute.ErrorType ())
		end
	end
end

function self:VisitExpression (expression, referenceNamespace)
	if expression:Is ("Identifier") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition ())
		local resolutionResults = expression:GetResolutionResults ()
		resolutionResults:FilterByLocality ()
		
		if resolutionResults:GetFilteredResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve identifier " .. expression:GetName () .. ".")
		end
	elseif expression:Is ("NameIndex") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition ())
		local resolutionResults = expression:GetResolutionResults ()
		
		if resolutionResults:GetFilteredResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve " .. expression:ToString () .. ".")
		end
	elseif expression:Is ("FunctionType") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition ())
	elseif expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

-- AnonymousFunction or FunctionDeclaration
function self:VisitFunction (functionNode)
	local methodDefinition = functionNode:GetMethodDefinition ()
	
	local parameterNamespace = methodDefinition:GetNamespace ()
	
	local returnTypeResults = functionNode:GetReturnTypeExpression ():GetResolutionResults ()
	returnTypeResults:FilterToConcreteTypes ()
	methodDefinition:SetReturnType (returnTypeResults:GetFilteredResultObject (1))
	
	-- Resolve parameter type nodes as concrete types
	local parameterList = functionNode:GetParameterList ()
	local parameterTypeNode
	local parameterTypeResults
	for i = 1, parameterList:GetParameterCount () do
		parameterTypeNode = parameterList:GetParameterType (i)
		if parameterTypeNode then
			local parameterType
			parameterTypeResults = parameterTypeNode:GetResolutionResults ()
			if parameterTypeResults then
				parameterTypeResults:FilterToConcreteTypes ()
				parameterType = parameterTypeResults:GetFilteredResultObject (1)
			else
				-- The node is a FunctionType or something that does not
				-- require resolution
				parameterType = parameterTypeNode:GetResolutionResult ()
			end
			methodDefinition:GetParameterList ():SetParameterType (i, parameterType)
			parameterNamespace:GetMember (parameterList:GetParameterName (i)):SetType (parameterType)
		end
	end
end

function self:ResolveUsings (statement)
	local definition = statement:GetDefinition ()
	if not definition then return end
	if not definition:IsNamespace () or not definition:IsClass () then return end
	
	definition:ResolveUsings (self.GlobalNamespace)
end