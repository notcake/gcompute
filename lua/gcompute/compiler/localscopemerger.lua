local self = {}
GCompute.LocalScopeMerger = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.AST = self.CompilationUnit:GetAbstractSyntaxTree ()
end

function self:VisitRoot (blockStatement)
	blockStatement:SetNamespace (blockStatement:GetNamespace () or GCompute.NamespaceDefinition ())
	blockStatement:GetNamespace ():SetConstructorAST (blockStatement)
end

function self:VisitBlock (blockStatement)
	blockStatement:SetNamespace (blockStatement:GetNamespace () or GCompute.NamespaceDefinition ())
	blockStatement:GetNamespace ():SetContainingNamespace (blockStatement:GetParentNamespace ())
	blockStatement:GetNamespace ():SetConstructorAST (blockStatement)
end

function self:VisitStatement (statement)
	if statement:HasNamespace () then
		statement:SetNamespace (statement:GetNamespace () or GCompute.NamespaceDefinition ())
		statement:GetNamespace ():SetContainingNamespace (statement:GetParentNamespace ())
	end
	
	local definition = nil
	if statement:Is ("FunctionDeclaration") then
		definition = statement:GetFunctionDefinition ()
	elseif statement:Is ("VariableDeclaration") then
		definition = statement:GetVariableDefinition ()
	end
	
	if definition then
		local rootNamespace = self:GetRootNamespace (self:GetNamespace (statement))
		self.CompilationUnit:Debug ("Namespace of " .. statement:ToString () .. " is " .. rootNamespace:ToString ())
	end
end

function self:GetNamespace (statement)
	if statement:HasNamespace () then
		return statement:GetNamespace ()
	end
	return self:GetNamespace (statement:GetParent ())
end

function self:GetRootNamespace (namespaceDefinition)
	local namespaceType = namespaceDefinition:GetNamespaceType ()
	if namespaceType == GCompute.NamespaceType.Global or
	   namespaceType == GCompute.NamespaceType.FunctionRoot then
		return namespaceDefinition
	end
	return self:GetRootNamespace (namespaceDefinition:GetContainingNamespace ())
end