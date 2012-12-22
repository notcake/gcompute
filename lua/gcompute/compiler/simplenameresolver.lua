local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleObjectResolver
	
	1. Sets the TypeSystem of everything
	2. Resolves using directives
	3. Resolves names
	4. Updates the type of function parameters in FunctionRoot NamespaceDefinitions
	
	This class should be generating ObjectResolutionResults
	using the ObjectResolver class and filtering them.
	Only the ObjectResolver class should be populating ObjectResolutionResults.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.GlobalNamespace = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition () or GCompute.GlobalNamespace
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement,
		function ()
			self.CompilationUnit:GetNamespaceDefinition ():ResolveTypes (self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition (), self.CompilationUnit)
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
		statement:GetDefinition ():SetTypeSystem (self.GlobalNamespace:GetTypeSystem ())
		self:ResolveUsings (statement)
	end
	
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
	elseif statement:Is ("VariableDeclaration") then
		if statement:GetTypeExpression () then
			local typeResults = statement:GetTypeExpression ():GetResolutionResults ()
			typeResults:FilterToConcreteTypes ()
			typeResults:FilterByLocality ()
			statement:SetType (typeResults:GetFilteredResultObject (1))
			statement:GetVariableDefinition ():SetType (typeResults:GetFilteredResultObject (1))
		end
	end
end

function self:VisitExpression (expression, referenceNamespace)
	if expression:Is ("Identifier") then
		GCompute.ObjectResolver:ResolveASTNode (expression, false, self.GlobalNamespace, referenceNamespace or expression:GetParentDefinition ())
		local resolutionResults = expression:GetResolutionResults ()
		resolutionResults:FilterByLocality ()
		
		if resolutionResults:GetFilteredResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve identifier " .. expression:GetName () .. ".")
		end
	elseif expression:Is ("NameIndex") then
		GCompute.ObjectResolver:ResolveASTNode (expression, false, self.GlobalNamespace, referenceNamespace or expression:GetParentDefinition ())
		local resolutionResults = expression:GetResolutionResults ()
		
		if resolutionResults:GetFilteredResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve " .. expression:ToString () .. ".")
		end
	elseif expression:Is ("FunctionType") then
		GCompute.ObjectResolver:ResolveASTNode (expression, false, self.GlobalNamespace, referenceNamespace or expression:GetParentDefinition ())
	elseif expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

-- AnonymousFunction or FunctionDeclaration
function self:VisitFunction (functionNode)
	local methodDefinition = functionNode:GetMethodDefinition ()
	methodDefinition:SetTypeSystem (self.GlobalNamespace:GetTypeSystem ())
	
	local parameterNamespace = methodDefinition:GetNamespace ()
	
	local returnTypeResults = functionNode:GetReturnTypeExpression ():GetResolutionResults ()
	returnTypeResults:FilterToConcreteTypes ()
	methodDefinition:SetReturnType (returnTypeResults:GetFilteredResultObject (1))
	
	local parameterList = functionNode:GetParameterList ()
	local parameterType
	local parameterTypeResults
	for i = 1, parameterList:GetParameterCount () do
		parameterType = parameterList:GetParameterType (i)
		if parameterType then
			parameterTypeResults = parameterType:GetResolutionResults ()
			parameterTypeResults:FilterToConcreteTypes ()
			methodDefinition:GetParameterList ():SetParameterType (i, parameterTypeResults:GetFilteredResultObject (1))
			parameterNamespace:GetMember (parameterList:GetParameterName (i)):SetType (parameterTypeResults:GetFilteredResultObject (1))
		end
	end
end

function self:ResolveUsings (statement)
	local definition = statement:GetDefinition ()
	if not definition then return end
	if not definition:IsNamespace () or not definition:IsClass () then return end
	
	definition:ResolveUsings (self.GlobalNamespace)
end