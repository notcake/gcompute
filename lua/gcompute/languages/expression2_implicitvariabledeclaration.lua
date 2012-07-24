local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		Add static global variable declarations for variables that were not explicitly declared.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.NameResolver = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ():GetNameResolver () or GCompute.NameResolver ()

	self.Root = nil
	self.RootNamespace = nil
end

function self:VisitRoot (blockStatement)
	self.Root = blockStatement
	self.RootNamespace = self.Root:GetNamespace () or GCompute.NamespaceDefinition ()
	self.Root:SetNamespace (self.RootNamespace)
	self.Root:GetNamespace ():AddUsing ("Expression2")
end

function self:VisitBlock (blockStatement)
	
end

function self:VisitStatement (statement)
	if statement:Is ("RangeForLoop") then
		if statement:GetLoopVariable ():Is ("Identifier") then
			self:ProcessIdentifier (statement:GetLoopVariable ())
		end
	elseif statement:Is ("IteratorForLoop") then
		for i = 1, statement:GetVariableCount () do
			if statement:GetVariable (i):Is ("Identifier") then
				self:ProcessIdentifier (statement:GetLoopVariable ())
			end
		end
	end
end

function self:VisitExpression (expression)
	if expression:Is ("BinaryOperator") and expression:GetOperator () == "=" then
		local leftExpression = expression:GetLeftExpression ()
		if leftExpression:Is ("Identifier") then
			self:ProcessIdentifier (leftExpression)
		end
	end
end

function self:ProcessIdentifier (identifier)
	local namespace = identifier:GetParentNamespace ()
	local resolutionResults = self.NameResolver:LookupUnqualifiedIdentifier (identifier:GetName (), GCompute.GlobalNamespace, namespace)
	if resolutionResults:GetResultCount () == 0 then
		self.CompilationUnit:Debug ("Adding variable declaration for " .. identifier:GetName ())
		self.RootNamespace:AddMemberVariable (identifier:GetName (), GCompute.InferredType ())
			:SetFileStatic (true)
	end
end