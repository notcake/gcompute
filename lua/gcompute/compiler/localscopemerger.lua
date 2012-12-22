local self = {}
GCompute.LocalScopeMerger = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.AST = self.CompilationUnit:GetAbstractSyntaxTree ()
end

function self:VisitRoot (blockStatement)
	blockStatement:GetDefinition ():SetConstructorAST (blockStatement)
end

function self:VisitBlock (blockStatement)
	blockStatement:GetDefinition ():SetConstructorAST (blockStatement)
end

function self:VisitStatement (statement)
	local parentNamespace = nil
	local parentMergedScope = nil
	if statement:Is ("FunctionDeclaration") or
	   statement:Is ("VariableDeclaration") then
		parentNamespace = self:GetGlobalNamespace (statement:GetParentDefinition ())
		parentMergedScope = parentNamespace:GetMergedLocalScope () or GCompute.MergedLocalScope ()
		parentNamespace:SetMergedLocalScope (parentMergedScope)
	end
	
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
	end
	
	if parentMergedScope then
		if statement:Is ("FunctionDeclaration") then
			parentMergedScope:AddMember (statement:GetMethodDefinition ())
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

function self:VisitFunction (functionNode)
	local methodDefinition = functionNode:GetDefinition ()
	local mergedLocalScope = methodDefinition:GetMergedLocalScope () or GCompute.MergedLocalScope ()
	methodDefinition:SetMergedLocalScope (mergedLocalScope)
	
	functionNode:GetBody ():SetPopStackFrame (true)
	
	for _, parameterName in functionNode:GetParameterList ():GetEnumerator () do
		mergedLocalScope:AddMember (methodDefinition:GetNamespace ():GetMember (parameterName))
	end
end

function self:GetGlobalNamespace (objectDefinition)
	local namespaceType = objectDefinition:GetNamespace ():GetNamespaceType ()
	if namespaceType == GCompute.NamespaceType.Global or
	   namespaceType == GCompute.NamespaceType.FunctionRoot then
		return objectDefinition
	end
	return self:GetGlobalNamespace (objectDefinition:GetDeclaringObject ())
end