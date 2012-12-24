local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleObjectResolver
		Operates on source file ASTs
		TODO: Operate on method ASTs
	
	1. Resolves using directives
	2. Resolves names
	3. Updates the type of function parameters in FunctionRoot NamespaceDefinitions
	
	This pass should be generating ObjectResolutionResults
	using the ObjectResolver class and filtering them.
	Only the ObjectResolver class should be populating ObjectResolutionResults.
	
	This pass will only report object resolution failures due to ambiguity.
	The TypeInfererTypeAssigner pass should report object resolution failures due
	to lack of results.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.FileId = self.CompilationUnit:GetSourceFileId ()
	
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
			local type = self:ResolveConcreteType (statement:GetTypeExpression (), true)
			statement:SetType (type or GCompute.ErrorType ())
			statement:GetVariableDefinition ():SetType (type or GCompute.ErrorType ())
		end
	end
end

function self:VisitExpression (expression, referenceNamespace)
	if expression:Is ("Identifier") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition (), self.FileId)
		local resolutionResults = expression:GetResolutionResults ()
		resolutionResults:FilterByLocality ()
	elseif expression:Is ("NameIndex") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition (), self.FileId)
		local resolutionResults = expression:GetResolutionResults ()
		
		if resolutionResults:GetFilteredResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve " .. expression:ToString () .. ".")
		end
	elseif expression:Is ("New") then
		new:GetLeftExpression ():GetResolutionResults ():FilterToConcreteTypes ()
	elseif expression:Is ("FunctionType") then
		self.ObjectResolver:ResolveASTNode (expression, false, referenceNamespace or expression:GetParentDefinition (), self.FileId)
	elseif expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

-- AnonymousFunction or FunctionDeclaration
function self:VisitFunction (functionNode)
	local methodDefinition = functionNode:GetMethodDefinition ()
	
	local parameterNamespace = methodDefinition:GetNamespace ()
	
	local returnType = self:ResolveConcreteType (functionNode:GetReturnTypeExpression (), true)
	methodDefinition:SetReturnType (returnType or GCompute.ErrorType ())
	
	-- Resolve parameter type nodes as concrete types
	local parameterList = functionNode:GetParameterList ()
	local parameterTypeNode
	local parameterTypeResults
	for i = 1, parameterList:GetParameterCount () do
		parameterTypeNode = parameterList:GetParameterType (i)
		if parameterTypeNode then
			local parameterType = self:ResolveConcreteType (parameterTypeNode, true)
			methodDefinition:GetParameterList ():SetParameterType (i, parameterType or GCompute.ErrorType ())
			parameterNamespace:GetMember (parameterList:GetParameterName (i)):SetType (parameterType or GCompute.ErrorType ())
		end
	end
end

function self:VisitTypeArgumentList (typeArgumentList)
	for typeArgument in typeArgumentList:GetEnumerator () do
		self:ResolveConcreteType (typeArgument, true)
	end
end

function self:ResolveConcreteType (astNode, generateError)
	local results = astNode:GetResolutionResults ()
	
	if not results then
		-- The node is a FunctionType or something that does not require resolution
		return astNode:GetResolutionResult ()
	end
	
	results:FilterToConcreteTypes ()
	results:FilterByLocality ()
	
	local type = results:GetFilteredResultObject (1)
	type = type and type:ToType ()
	if not type and generateError then
		if results:GetResultCount () == 0 then
			-- TypeInfererTypeAssigner will report zero-result resolution failures
		elseif results:GetFilteredResultCount () == 0 then
			astNode:AddErrorMessage (astNode:ToString () .. " is not a concrete type.")
		else
			astNode:AddErrorMessage (astNode:ToString () .. " is ambiguous.")
		end
	end
	return type
end

function self:ResolveUsings (statement)
	local definition = statement:GetDefinition ()
	if not definition then return end
	if not definition:IsNamespace () or not definition:IsClass () then return end
	
	definition:ResolveUsings (self.GlobalNamespace)
end