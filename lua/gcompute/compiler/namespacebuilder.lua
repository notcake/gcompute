local self = {}
GCompute.NamespaceBuilder = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	NamespaceBuilder
		Operates on source file ASTs
		
	1. Assigns a NamespaceDefinition to all Statements that should have one
		and adds member variables to them
	2. Assigns MethodDefinitions to FunctionDeclarations and AnonymousFunctions
		and adds function parameters to them
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.AST = self.CompilationUnit:GetAbstractSyntaxTree ()
end

function self:VisitRoot (blockStatement)
	if blockStatement:GetDefinition () then
		blockStatement:AddErrorMessage ("Compiler bug: The root BlockStatement should not be assigned a NamespaceDefinition by anything other than the NamespaceBuilder!")
	end
	blockStatement:SetDefinition (self.CompilationUnit:GetCompilationGroup ():GetRootNamespace ())
end

function self:VisitBlock (blockStatement)
	blockStatement:SetDefinition (blockStatement:GetDefinition () or GCompute.NamespaceDefinition ())
	
	local namespace = blockStatement:GetDefinition ()
	self:SetupDefinitionHierarchy (namespace, blockStatement:GetParentDefinition ())
	namespace:AddConstructorAST (blockStatement)
	if namespace:GetNamespaceType () == GCompute.NamespaceType.Unknown then
		namespace:SetNamespaceType (GCompute.NamespaceType.Local)
	end
end

function self:VisitStatement (statement)
	if statement:Is ("FunctionDeclaration") then
		self:VisitFunction (statement)
		return
	end
	
	if statement:HasDefinition () then
		statement:SetDefinition (statement:GetDefinition () or GCompute.NamespaceDefinition ())
		self:SetupDefinitionHierarchy (statement:GetDefinition (), statement:GetParentDefinition ())
	end
	
	if statement:Is ("RangeForLoop") then
		statement:GetDefinition ():SetNamespaceType (GCompute.NamespaceType.Local)
	end
	
	if statement:Is ("VariableDeclaration") then
		if not statement:GetType () then
			statement:SetType (GCompute.InferredType ())
		end
		
		local variableDefinition = statement:GetParentDefinition ():AddVariable (statement:GetName (), statement:GetType ())
		statement:SetVariableDefinition (variableDefinition)
	end
end

function self:VisitExpression (expression)
	if expression:Is ("AnonymousFunction") then
		self:VisitFunction (expression)
	end
end

function self:VisitFunction (functionNode)
	local methodDefinition = nil
	
	local declaringObject = functionNode:GetParentDefinition ()
	while declaringObject:GetNamespace ():GetNamespaceType () ~= GCompute.NamespaceType.Global and
		  declaringObject:GetNamespace ():GetNamespaceType () ~= GCompute.NamespaceType.Type do
		declaringObject = declaringObject:GetDeclaringObject ()
	end
	
	if functionNode:Is ("FunctionDeclaration") then
		methodDefinition = declaringObject:GetNamespace ():AddMethod (functionNode:GetName (), functionNode:GetParameterList ():ToParameterList ())
	else
		methodDefinition = GCompute.MethodDefinition ("<anonymous-function>", functionNode:GetParameterList ():ToParameterList ())
		self:SetupDefinitionHierarchy (methodDefinition, functionNode:GetParentDefinition ())
		declaringObject:GetNamespace ():SetupMemberHierarchy (methodDefinition)
	end
	
	methodDefinition:SetReturnType (GCompute.DeferredObjectResolution (functionNode:GetReturnTypeExpression (), GCompute.ResolutionObjectType.Type))
	
	methodDefinition:SetFunctionDeclaration (functionNode)
	methodDefinition:SetBlockStatement (functionNode:GetBody ())
	
	functionNode:SetMethodDefinition (methodDefinition)
	
	-- Set up function parameter namespace
	methodDefinition:BuildNamespace ()
end

function self:SetupDefinitionHierarchy (child, parent)
	if not parent then return end
	
	child:SetGlobalNamespace (parent:GetGlobalNamespace ())
	child:SetDeclaringMethod (parent:IsMethod () and parent or parent:GetDeclaringMethod ())
	child:SetDeclaringNamespace (parent:IsNamespace () and parent or parent:GetDeclaringNamespace ())
	child:SetDeclaringObject (parent)
	child:SetDeclaringType (parent:IsType () and parent or parent:GetDeclaringType ())
end