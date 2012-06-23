local self = {}
GCompute.SimpleNameResolver = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	SimpleNameResolver
	
	Resolves using directives
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.NameResolver = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNameResolver () or nil
	if not self.NameResolver then
		self.NameResolver = GCompute.NameResolver ()
		self.NameResolver:SetGlobalNamespace (GCompute.GlobalNamespace)
	end
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

function self:VisitExpression (expression)
	if expression:Is ("Identifier") then
		local nameResolutionResults = self.NameResolver:LookupUnqualifiedIdentifier (expression:GetParentNamespace (), expression:GetName ())
		expression.NameResolutionResults = nameResolutionResults
		self.CompilationUnit:Debug (expression:GetName ())
		self.CompilationUnit:Debug (nameResolutionResults:ToString ())
	elseif expression:Is ("NameIndex") then
		local nameResolutionResults = GCompute.NameResolutionResults ()
		expression.NameResolutionResults = nameResolutionResults
		local leftResults = expression:GetLeftExpression ().NameResolutionResults
		for i = 1, leftResults:GetGlobalResultCount () do
			local result = leftResults:GetGlobalResult (i).Result
			self.NameResolver:LookupQualifiedIdentifier (result, expression:GetIdentifier (), nameResolutionResults)
		end
		self.CompilationUnit:Debug (expression:GetIdentifier ())
		self.CompilationUnit:Debug (nameResolutionResults:ToString ())
	end
end

function self:ResolveUsings (statement)
	local namespace = statement:GetNamespace ()
	for i = 1, namespace:GetUsingCount () do
		local usingDirective = namespace:GetUsing (i)
		namespace:GetUsing (i):Resolve (self)
	end
end