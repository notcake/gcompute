local self = {}
Pass = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	Language: Expression 2
	Purpose:
		Add static global variable declarations for variables that were not explicitly declared.
		Mark local variables in the top level namespace as file static.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit

	self.Root = nil
	self.RootNamespace = nil
end

function self:VisitRoot (blockStatement)
	self.Root = blockStatement
	self.RootNamespace = self.Root:GetNamespace () or GCompute.NamespaceDefinition ()
	self.Root:SetNamespace (self.RootNamespace)
	self.Root:GetNamespace ():AddUsing ("Expression2"):Resolve ()
end

function self:VisitBlock (blockStatement)
	
end

function self:VisitStatement (statement)
	if statement:Is ("RangeForLoop") then
		if statement:GetLoopVariable ():Is ("Identifier") then
			self:ProcessIdentifier (statement:GetLoopVariable (), "Expression2.number")
		end
	elseif statement:Is ("IteratorForLoop") then
		for i = 1, statement:GetVariableCount () do
			if statement:GetVariable (i):Is ("Identifier") then
				self:ProcessIdentifier (statement:GetLoopVariable ())
			end
		end
	elseif statement:Is ("VariableDeclaration") then
		if statement:GetParent () == self.Root then
			if statement:IsLocal () then
				statement:SetStatic (true)
				statement:GetVariableDefinition ():SetFileStatic (true)
			end
		end
	end
end

function self:VisitExpression (expression)
	if expression:Is ("BinaryOperator") and expression:GetOperator () == "=" then
		local leftExpression = expression:GetLeftExpression ()
		if leftExpression:Is ("Identifier") then
			self:ProcessIdentifier (leftExpression, "Expression2.number")
		end
	end
end

function self:ProcessIdentifier (identifier, type)
	local namespace = identifier:GetParentNamespace ()
	local resolutionResults = GCompute.ResolutionResults ()
	GCompute.ObjectResolver:ResolveUnqualifiedIdentifier (resolutionResults, identifier:GetName (), GCompute.GlobalNamespace, namespace)
	if resolutionResults:GetFilteredResultCount () == 0 then
		self.CompilationUnit:Debug ("Adding variable declaration for " .. identifier:GetName ())
		self.RootNamespace:AddMemberVariable (identifier:GetName (), type or GCompute.InferredType ())
			:SetFileStatic (true)
	end
end