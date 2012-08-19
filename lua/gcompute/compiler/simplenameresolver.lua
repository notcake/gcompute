local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleNameResolver
	
	Resolves using directives
	Resolves names
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
end

function self:VisitExpression (expression, referenceNamespace)
	if expression:Is ("Identifier") then
		local resolutionResults = self.NameResolver:LookupUnqualifiedIdentifier (expression:GetName (), self.GlobalNamespace, referenceNamespace or expression:GetParentNamespace ())
		resolutionResults:FilterLocalResults ()
		expression.ResolutionResults = resolutionResults
	elseif expression:Is ("NameIndex") then
		local resolutionResults = GCompute.NameResolutionResults ()
		expression.ResolutionResults = resolutionResults
		local leftResults = expression:GetLeftExpression ().ResolutionResults
		local identifier = expression:GetIdentifier () -- either an Identifier or ParametricIdentifier
		if not identifier then
			self.CompilationUnit:Error ("NameIndex has no Identifier (" .. expression .. ")", expression:GetLocation ())
			return
		end
		local name = identifier:GetName ()
		for i = 1, leftResults:GetGlobalResultCount () do
			local result = leftResults:GetGlobalResult (i).Result
			self.NameResolver:LookupQualifiedIdentifier (result, name, resolutionResults)
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