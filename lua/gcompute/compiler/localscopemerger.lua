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
	blockStatement:GetNamespace ():SetDeclaringNamespace (blockStatement:GetParentNamespace ())
	blockStatement:GetNamespace ():SetConstructorAST (blockStatement)
end

function self:VisitStatement (statement)
	local parentNamespace = nil
	local parentMergedScope = nil
	if statement:Is ("FunctionDeclaration") or
	   statement:Is ("VariableDeclaration") then
		parentNamespace = self:GetGlobalNamespace (statement:GetParentNamespace ())
		parentMergedScope = parentNamespace:GetMergedLocalScope () or GCompute.MergedLocalScope ()
		parentNamespace:SetMergedLocalScope (parentMergedScope)
	end
	
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
	end
	
	if parentMergedScope then
		if statement:Is ("FunctionDeclaration") then
			parentMergedScope:AddMember (statement:GetFunctionDefinition ())
		elseif statement:Is ("VariableDeclaration") then
			parentMergedScope:AddMember (statement:GetVariableDefinition ())
		end
	end
end

function self:VisitExpression (expression)
	if expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

function self:VisitFunction (func)
	local namespace = func:GetNamespace ()
	local mergedLocalScope = namespace:GetMergedLocalScope () or GCompute.MergedLocalScope ()
	namespace:SetMergedLocalScope (mergedLocalScope)
	
	func:GetBody ():SetPopStackFrame (true)
	
	for _, parameterName in func:GetParameterList ():GetEnumerator () do
		mergedLocalScope:AddMember (namespace:GetMember (parameterName))
	end
end

function self:GetNamespace (statement)
	if statement:HasNamespace () then
		return statement:GetNamespace ()
	end
	return self:GetNamespace (statement:GetParent ())
end

function self:GetGlobalNamespace (objectDefinition)
	local namespaceType = objectDefinition:GetNamespace ():GetNamespaceType ()
	if namespaceType == GCompute.NamespaceType.Global or
	   namespaceType == GCompute.NamespaceType.FunctionRoot then
		return objectDefinition
	end
	return self:GetGlobalNamespace (objectDefinition:GetDeclaringObject ())
end