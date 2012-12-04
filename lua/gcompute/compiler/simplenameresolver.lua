local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleNameResolver
	
	1. Resolves using directives
	2. Resolves names
	3. Updates the type of function parameters in FunctionRoot NamespaceDefinitions
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.NameResolver = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNameResolver () or GCompute.NameResolver ()
	self.GlobalNamespace = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition () or GCompute.GlobalNamespace
end

function self:GetNameResolver ()
	return self.NameResolver
end

function self:Process (blockStatement, callback)
	self:ProcessRoot (blockStatement,
		function ()
			self.CompilationUnit:GetNamespaceDefinition ():ResolveTypes (self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition ())
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
	if statement:HasNamespace () then
		self:ResolveUsings (statement)
	end
	
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
	end
end

function self:VisitExpression (expression, referenceNamespace)
	if expression:Is ("Identifier") then
		local resolutionResults = self.NameResolver:LookupUnqualifiedIdentifier (expression:GetName (), self.GlobalNamespace, referenceNamespace or expression:GetParentNamespace ())
		resolutionResults:FilterLocalResults ()
		expression.ResolutionResults = resolutionResults
		
		if resolutionResults:GetResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve identifier " .. expression:GetName () .. ".")
		end
	elseif expression:Is ("NameIndex") then
		-- TODO: Merge with NameResolver's NameIndex processing
		local resolutionResults = GCompute.NameResolutionResults ()
		expression.ResolutionResults = resolutionResults
		local leftResults = expression:GetLeftExpression ().ResolutionResults
		local identifier = expression:GetIdentifier () -- either an Identifier or ParametricIdentifier
		if not identifier then
			self.CompilationUnit:Error ("NameIndex has no Identifier (" .. expression:ToString () .. ")", expression:GetLocation ())
			return
		end
		local name = identifier:GetName ()
		for i = 1, leftResults:GetGlobalResultCount () do
			local result = leftResults:GetGlobalResult (i)
			self.NameResolver:LookupQualifiedIdentifier (result, name, resolutionResults)
		end
		
		if resolutionResults:GetResultCount () == 0 then
			expression:AddErrorMessage ("Cannot resolve " .. expression:GetName () .. ".")
		end
	elseif expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

-- AnonymousFunction or FunctionDeclaration
function self:VisitFunction (func)
	local resolutionResults = func:GetReturnTypeExpression ().ResolutionResults
	
	local functionDefinition = func:GetFunctionDefinition ()
	local namespace = func:GetNamespace ()

	-- Force early resolution of the parameter types, since we'll need them
	functionDefinition:ResolveTypes (self.CompilationUnit:GetCompilationGroup ():GetNamespaceDefinition ())
	
	local parameterList = func:GetParameterList ()
	local parameterType
	for i = 1, parameterList:GetParameterCount () do
		parameterType = parameterList:GetParameterType (i)
		if parameterType then
			-- TODO: This is WRONG, fix it.
			
			-- resolvedObject should always be a Type or TypeDefinition (which is a Type) or OverloadedTypeDefinition here.
			local resolvedObject = parameterType.ResolutionResults:GetResult (1)
			if resolvedObject:UnwrapAlias ():IsOverloadedTypeDefinition () then
				resolvedObject = resolvedObject:GetType (1):UnwrapAlias ()
			end
			functionDefinition:GetParameterList ():SetParameterType (i, resolvedObject)
			namespace:GetMember (parameterList:GetParameterName (i)):SetType (resolvedObject)
		end
	end
end

function self:ResolveUsings (statement)
	local namespace = statement:GetNamespace ()
	for i = 1, namespace:GetUsingCount () do
		local usingDirective = namespace:GetUsing (i)
		namespace:GetUsing (i):Resolve (self)
	end
end