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
	self.FileId = self.CompilationUnit:GetSourceFileId ()

	self.Root = nil
	self.RootNamespace = compilationUnit:GetCompilationGroup ():GetRootNamespace ()
	
	self.ObjectResolver = GCompute.ObjectResolver (self.CompilationUnit:GetCompilationGroup ():GetRootNamespaceSet ())
end

function self:VisitRoot (blockStatement)
	self.Root = blockStatement
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
			self:ProcessIdentifier (leftExpression)
		end
	end
end

function self:ProcessIdentifier (identifier, type)
	-- Attempt to resolve the identifier
	local resolutionResults = GCompute.ResolutionResults ()
	self.ObjectResolver:ResolveUnqualifiedIdentifier (resolutionResults, identifier, identifier:GetParentDefinition (), self.FileId)
	
	if identifier:GetParent ():Is ("BinaryOperator") and
	   identifier:GetParent ():GetOperator () == "=" and
	   identifier:GetParent ():GetLeftExpression () == identifier then
		resolutionResults:FilterToAssignables ()
	end
	if resolutionResults:GetFilteredResultCount () == 0 then
		-- Failed to resolve, add it as a file static variable
		self.CompilationUnit:Debug ("Adding file static variable declaration for " .. identifier:GetName ())
		
		self.RootNamespace:GetFileStaticNamespace (self.FileId)
			:AddVariable (identifier:GetName (), type or GCompute.InferredType ())
				:SetFileStatic (true)
	end
end