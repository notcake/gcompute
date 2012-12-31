local self = {}
GCompute.TypeInfererTypeAssigner = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

--[[
	TypeInfererTypeAssigner
	
	If an AST node's type is set to an ErrorType, it _must_
	have an error added to it.
	AST nodes encountered whose type is an ErrorType will not
	have additional error messages added to them.
]]

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.CompilationGroup = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ()
	
	self.RootNamespaceSet = self.CompilationGroup:GetRootNamespaceSet ()
	self.ObjectResolver = GCompute.ObjectResolver (self.RootNamespaceSet)
end

function self:VisitStatement (statement)
	if statement:Is ("VariableDeclaration") then
		if statement:GetRightExpression () then
			self:ResolveAssignment (statement)
		end
		
		-- Replacing Identifiers and NameIndexes with *Accesses in the type
		-- expressions of VariableDefinitions causes their type to be reset,
		-- so we have to set them again here.
		if statement:GetTypeExpression () then
			local typeResults = statement:GetTypeExpression ():GetResolutionResults ()
			local type = typeResults:GetFilteredResultObject (1)
			statement:SetType (type or GCompute.ErrorType ())
			statement:GetVariableDefinition ():SetType (type or GCompute.ErrorType ())
			
			if not statement:GetType () then
				statement:AddErrorMessage (statement:ToString () .. " has no type.")
			elseif statement:GetType ():UnwrapAlias ():IsErrorType () then
				statement:AddErrorMessage ("Type of " .. statement:ToString () .. " is " .. statement:GetType ():GetFullName ())
			end
		end
	end
end

function self:VisitExpression (expression)
	local overrideExpression = nil

	if expression:GetType () then
		if expression:GetType ():IsDeferredObjectResolution () then
			-- There shouldn't be any DeferredObjectResolutions here!
			expression:AddErrorMessage ("Pre-assigned type of " .. expression:ToString () .. " should not be a DeferredObjectResolution! (" .. expression:GetType ():ToString () .. ")")
		end
		return
	end
	
	if expression:Is ("Identifier") then
		local variableReadPlan = GCompute.VariableReadPlan ()
		expression.VariableReadPlan = variableReadPlan
	
		if expression.ResolutionResults:GetFilteredResultCount () > 0 then
			local result = expression.ResolutionResults:GetFilteredResultObject (1)
			local resultNamespace = result:GetDeclaringObject ()
			local namespaceType = resultNamespace:GetNamespace ():GetNamespaceType ()
			if namespaceType == GCompute.NamespaceType.Global then
				local staticMemberAccess = GCompute.AST.StaticMemberAccess ()
				
				staticMemberAccess:SetLeftExpression (self:CreateStaticMemberAccess (resultNamespace))
				staticMemberAccess:SetName (expression:GetName ())
				staticMemberAccess:SetRuntimeName (resultNamespace:GetMemberRuntimeName (result))
				
				staticMemberAccess:SetResolutionResults (expression:GetResolutionResults ())
				
				staticMemberAccess:SetStartToken (expression:GetStartToken ())
				staticMemberAccess:SetEndToken (expression:GetEndToken ())
				
				self:ResolveAccessType (staticMemberAccess)
				return staticMemberAccess
			elseif namespaceType == GCompute.NamespaceType.Local or
			       namespaceType == GCompute.NamespaceType.FunctionRoot then
				local mergedLocalScope = self:GetMergedLocalScope (result)
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				variableReadPlan:SetRuntimeName (mergedLocalScope:GetRuntimeName (result))
			else
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				self.CompilationUnit:Error ("TypeInfererTypeAssigner:VisitExpression : Identifier : Cannot handle namespace type of " .. expression:ToString () .." (" .. GCompute.NamespaceType [namespaceType] .. ").")
			end
			
			self:ResolveAccessType (expression)
		else
			expression:SetType (GCompute.ErrorType ())
			
			-- Produce an error message only if this Identifier is not being used
			-- as a function in a FunctionCall. VisitFunctionCall will produce
			-- a better error.
			if not expression:GetParent ():Is ("FunctionCall") or expression:GetParent ():GetLeftExpression () ~= expression then
				if expression.ResolutionResults:GetResultCount () == 0 then
					expression:AddErrorMessage ("Cannot resolve unqualified name \"" .. expression:ToString () .. "\".")
				elseif expression.ResolutionResults:GetResultCount () == 1 then
				else
					expression:AddErrorMessage ("Cannot resolve unqualified name \"" .. expression:ToString () .. "\" - too many results.")
				end
			end
		end
	elseif expression:Is ("NameIndex") then
		if expression.ResolutionResults:GetFilteredResultCount () > 0 then
			local result = expression.ResolutionResults:GetFilteredResultObject (1)
			local resultNamespace = result:GetDeclaringObject ()
			local namespaceType = resultNamespace:GetNamespaceType ()
			if namespaceType == GCompute.NamespaceType.Global then
				local staticMemberAccess = GCompute.AST.StaticMemberAccess ()
				
				staticMemberAccess:SetLeftExpression (expression:GetLeftExpression ())
				staticMemberAccess:SetName (expression:GetIdentifier ():GetName ())
				staticMemberAccess:SetRuntimeName (resultNamespace:GetMemberRuntimeName (result))
				
				staticMemberAccess:SetResolutionResults (expression:GetResolutionResults ())
				
				staticMemberAccess:SetStartToken (expression:GetStartToken ())
				staticMemberAccess:SetEndToken (expression:GetEndToken ())
				
				self:ResolveAccessType (staticMemberAccess)
				return staticMemberAccess
			elseif namespaceType == GCompute.NamespaceType.Local or
			       namespaceType == GCompute.NamespaceType.FunctionRoot then
				local mergedLocalScope = self:GetMergedLocalScope (result)
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				variableReadPlan:SetRuntimeName (mergedLocalScope:GetRuntimeName (result))
			else
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				self.CompilationUnit:Error ("TypeInfererTypeAssigner:VisitExpression : Identifier : Cannot handle namespace type of " .. expression:ToString () .." (" .. GCompute.NamespaceType [namespaceType] .. ").")
			end
			
			self:ResolveAccessType (expression)
		else
			expression:SetType (GCompute.ErrorType ())
			self.CompilationUnit:Error ("Cannot resolve qualified name \"" .. expression:ToString () .. "\".", expression:GetLocation ())
		end
	elseif expression:Is ("ArrayIndex") then
		overrideExpression = self:VisitArrayIndex (expression)
	elseif expression:Is ("FunctionCall") then
		overrideExpression = self:VisitFunctionCall (expression)
	elseif expression:Is ("MemberFunctionCall") then
		overrideExpression = self:VisitMemberFunctionCall (expression)
	elseif expression:Is ("New") then
		overrideExpression = self:VisitNew (expression)
	elseif expression:Is ("BinaryOperator") then
		overrideExpression = self:VisitBinaryOperator (expression)
	elseif expression:Is ("LeftUnaryOperator") then
		overrideExpression = self:VisitLeftUnaryOperator (expression)
	elseif expression:Is ("BooleanLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Boolean", GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Number",  GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	elseif expression:Is ("StringLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("String",  GCompute.ResolutionObjectType.Type):Resolve (self.ObjectResolver))
	elseif expression:Is ("FunctionType") then
		expression:SetType (GCompute.TypeSystem:GetType ())
	elseif expression:Is ("AnonymousFunction") then
		expression:SetType (expression:GetMethodDefinition ():GetType ())
	else
		expression:SetType (GCompute.ErrorType ())
		expression:AddErrorMessage ("TypeInfererTypeAssigner: Unhandled expression type " .. expression:GetNodeType ())
	end
	
	expression = overrideExpression or expression
	if not expression:GetType () then
		expression:AddErrorMessage (expression:ToString () .. " has no type.")
	end
	
	return overrideExpression
end

function self:VisitArrayIndex (arrayIndex)
	local functionCall = self:ResolveOperatorCall (arrayIndex, "operator[]", arrayIndex:GetLeftExpression (), arrayIndex:GetArgumentList (), arrayIndex:GetTypeArgumentList () and arrayIndex:GetTypeArgumentList ():ToTypeArgumentList ())
end

function self:VisitArrayIndexAssignment (arrayIndexAssignment)
	local argumentList = arrayIndexAssignment:GetArgumentList ():Clone ()
	argumentList:AddArgument (arrayIndexAssignment:GetRightExpression ())
	
	local functionCall = self:ResolveOperatorCall (arrayIndexAssignment, "operator[]", arrayIndexAssignment:GetLeftExpression (), argumentList, arrayIndexAssignment:GetTypeArgumentList () and arrayIndexAssignment:GetTypeArgumentList ():ToTypeArgumentList ())
	if functionCall then
		arrayIndexAssignment:SetRightExpression (functionCall:GetArgument (functionCall:GetArgumentCount ()))
	end
end

local comparisonOperators =
{
	["=="] = true,
	["!="] = true,
	["<="] = true,
	[">="] = true
}

function self:VisitBinaryOperator (binaryOperator)
	--[[
		Assignment
			<left> & = <right>
				Either:
					Overloaded assignment function (=)
						<base left>::operator= (<base right>)
						operator= (<ref base left>, <base right>)
					Default assignment (=)
						<left> == <base right>
			<left> & [op]= <right>
				Either:
					Overloaded operator-assignment function ([op]=)
					Overloaded operator then assignment ([op] then =)
					
		Assignments do not return references.
		(A = B) = C is invalid.
		A = B = C is valid, B = C returns the value of B after the assignment
	]]
	local operator = binaryOperator:GetOperator ()
	if operator:sub (-1, -1) ~= "=" or comparisonOperators [operator] then
		-- Pure binary operator
		
		local argumentList = GCompute.AST.ArgumentList ()
		argumentList:SetStartToken (binaryOperator:GetStartToken ())
		argumentList:SetEndToken (binaryOperator:GetEndToken ())
		argumentList:AddArgument (binaryOperator:GetRightExpression ())
		
		local functionCall = self:ResolveOperatorCall (binaryOperator, "operator" .. operator, binaryOperator:GetLeftExpression (), argumentList)
		if functionCall then
			binaryOperator:SetLeftExpression (functionCall:GetArgument (1))
			binaryOperator:SetRightExpression (functionCall:GetArgument (2))
		end
	else
		-- Either binary operator, then assignment
		-- or pure assignment
		return self:ResolveAssignment (binaryOperator)
	end
end

function self:VisitFunctionCall (functionCall)
	local leftExpression = functionCall:GetLeftExpression ()
	local leftDefinition = leftExpression:GetResolutionResult ()
	leftDefinition = leftDefinition and leftDefinition:UnwrapAlias ()
	
	local leftType = leftExpression:GetType ()
	leftType = leftType and leftType:UnwrapReference ()
	
	-- Note: leftType will be nil if leftDefinition is an OverloadedMethodDefinition
	
	if (leftDefinition and (leftDefinition:IsOverloadedMethod () or leftDefinition:IsMethod ())) or
	   (leftType and leftType:IsFunctionType ()) then
		-- leftDefinition could be an OverloadedMethodDefinition or a VariableDefinition
		
		local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Static, nil, functionCall:GetArgumentList ())
		
		-- Populate OverloadedFunctionResolver
		if not leftDefinition then
			-- leftExpression is some expression returning a function
			overloadedFunctionResolver:AddOverload (leftExpression)
		elseif leftDefinition:IsOverloadedMethod () then
			overloadedFunctionResolver:AddOverloads (leftDefinition)
		elseif leftDefinition:IsMethod () or
		       leftDefinition:GetType ():IsFunctionType () then
			overloadedFunctionResolver:AddOverload (leftDefinition)
		else
			self.CompilationUnit:Error ("Left hand side of function call is not a function! (" .. leftExpression:ToString () .. ")")
		end
		
		-- Resolve OverloadedFunctionResolver
		functionCall.FunctionCall = self:ResolveFunctionCall (functionCall, overloadedFunctionResolver, leftExpression:ToString ())
		if functionCall.FunctionCall then
			if not functionCall.FunctionCall:IsMemberFunctionCall () then
				functionCall.FunctionCall:SetLeftExpression (leftExpression)
			end
		end
	elseif leftDefinition and (leftDefinition:IsType () or leftDefinition:IsOverloadedClass ()) then
		return self:ConvertFunctionCallToConstructor (functionCall)
	else
		functionCall:SetType (GCompute.ErrorType ())
		if leftExpression:GetResolutionResult () then
			functionCall:AddErrorMessage ("Cannot call " .. leftExpression:ToString () .. " because it is not a function, its type is " .. leftType:ToString () .. ".")
		else
			leftExpression:AddErrorMessage ("Cannot find method " .. leftExpression:ToString () .. " " .. self:GetFormattedArgumentTypes (functionCall:GetArgumentList ()) .. ".")
		end
	end
end

function self:VisitLeftUnaryOperator (leftUnaryOperator)
	local operator = leftUnaryOperator:GetOperator ()
	local rightExpression = leftUnaryOperator:GetRightExpression ()
	
	local argumentList = GCompute.AST.ArgumentList ()
	argumentList:SetStartToken (rightExpression:GetStartToken ())
	argumentList:SetEndToken (rightExpression:GetEndToken ())
	
	local functionCall = self:ResolveOperatorCall (leftUnaryOperator, "operator" .. operator, rightExpression, argumentList)
	if functionCall then
		leftUnaryOperator:SetRightExpression (functionCall:GetArgument (1))
	end
end

function self:VisitMemberFunctionCall (memberFunctionCall)
	local leftExpression = memberFunctionCall:GetLeftExpression ()
	local leftType = leftExpression:GetType ()
	
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Member, leftExpression, memberFunctionCall:GetArgumentList ())
	
	-- Populate OverloadedFunctionResolver
	local typeArgumentList = memberFunctionCall:GetTypeArgumentList () and memberFunctionCall:GetTypeArgumentList ():ToTypeArgumentList ()
	overloadedFunctionResolver:AddMemberOverloads (leftType, memberFunctionCall:GetIdentifier ():GetName (), typeArgumentList)
	
	-- Resolve OverloadedFunctionResolver
	memberFunctionCall.FunctionCall = self:ResolveFunctionCall (memberFunctionCall, overloadedFunctionResolver, memberFunctionCall:GetIdentifier ():GetName (), typeArgumentList)
	if memberFunctionCall.FunctionCall then
		if memberFunctionCall.FunctionCall:IsMemberFunctionCall () then
			memberFunctionCall:SetLeftExpression (memberFunctionCall.FunctionCall:GetLeftExpression ())
		else
			memberFunctionCall.FunctionCall:SetLeftExpression (GCompute.AST.InstanceMemberAccess (leftExpression, memberFunctionCall:GetName (), memberFunctionCall:GetTypeArgumentList ():ToTypeArgumentList ()))
		end
	end
end

function self:VisitNew (new)
	local leftExpression = new:GetLeftExpression ()
	local leftDefinition = leftExpression:GetResolutionResult ()
	
	if not leftDefinition then
		local leftResolutionResults = leftExpression:GetResolutionResults ()
		if leftResolutionResults:GetFilteredResultCount () == 0 then
			leftExpression:AddErrorMessage (leftExpression:ToString () .. " is not a type.")
			return
		elseif leftResolutionResults:GetFilteredResultCount () > 1 then
			leftExpression:AddErrorMessage (leftExpression:ToString () .. " is ambiguous as a type name.")
			return
		end
	end
	
	-- leftDefinition could be (an alias to) a Type, ClassDefinition or OverloadedClassDefinition
	local unwrapped = leftDefinition:UnwrapAlias ()
	local type
	if unwrapped:IsClass () then
		type = leftDefinition
	elseif unwrapped:IsOverloadedClass () then
		type = unwrapped:GetDefaultClass ()
	elseif unwrapped:IsType () then
		type = leftDefinition
	end
	type = type and type:ToType ()
	
	if not type then
		local errorMessage = leftExpression:ToString () .. " is not a valid concrete type for use in a constructor call."
		if unwrapped:IsOverloadedClass () then
			errorMessage = errorMessage .. " Did you mean:"
			for class in unwrapped:GetEnumerator () do
				errorMessage = errorMessage .. "\n\t" .. class:GetShortName ()
			end
		end
		new:AddErrorMessage (errorMessage)
		return
	end
	new:SetType (type)
	
	-- Constructor resolution
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Static, nil, new:GetArgumentList ())
	
	-- Populate OverloadedFunctionResolver
	if type:GetNamespace () then
		for constructor in type:GetNamespace ():GetConstructorEnumerator () do
			overloadedFunctionResolver:AddOverload (constructor)
		end
	end
	
	-- Resolve OverloadedFunctionResolver
	new.FunctionCall = self:ResolveFunctionCall (new, overloadedFunctionResolver, leftDefinition:GetShortName ())
	new:SetNativelyAllocated (type:IsNativelyAllocated ())
	
	if new.FunctionCall then
		new.FunctionCall:SetLeftExpression (new:GetLeftExpression ())
		new.FunctionCall:SetHasPrependedArgument (not new:IsNativelyAllocated ())
	end
	
	if not new:IsNativelyAllocated () then
		self.CompilationUnit:Error ("<new-expression> type is not natively allocated! (non-natively allocated objects are unsupported right now).", leftExpression:GetLocation ())
	end
end

function self:ConvertFunctionCallToConstructor (functionCall)
	local new = GCompute.AST.New ()
	new:SetLeftExpression (functionCall:GetLeftExpression ())
	new:SetArgumentList (functionCall:GetArgumentList ())
	
	new:SetStartToken (functionCall:GetStartToken ())
	new:SetEndToken (functionCall:GetEndToken ())
	
	self:VisitExpression (new)
	return new
end

function self:ResolveAccessType (astNode)
	local resolutionResults = astNode:GetResolutionResults ()
	local result = resolutionResults:GetFilteredResultObject (1):UnwrapAlias ()
	
	if result:IsOverloadedMethod () then
		-- Let overloaded function resolution handle this.
	elseif result:IsOverloadedClass () or result:IsType () then
		astNode:SetType (GCompute.TypeSystem:GetType ())
	else
		astNode:SetType (GCompute.ReferenceType (result:GetType () or GCompute.ErrorType ()))
	end
end

--- Resolves an OverloadedFunctionResolver
-- @param astNode The node which will invoke the function call
-- @param overloadedFunctionResolver The OverloadedFunctionResolver to resolve
-- @param methodName The name of the method, used for error reporting
-- @param typeArgumentList The TypeArgumentList of the function call, used for error reporting
function self:ResolveFunctionCall (astNode, overloadedFunctionResolver, methodName, typeArgumentList)
	local functionCall = overloadedFunctionResolver:Resolve ()
	
	local suppressErrors = false
	if overloadedFunctionResolver:GetObject () and
	   overloadedFunctionResolver:GetObject ():GetType () and
	   overloadedFunctionResolver:GetObject ():GetType ():UnwrapReference ():IsErrorType () then
		suppressErrors = true
	end
	for argument in overloadedFunctionResolver:GetArgumentList ():GetEnumerator () do
		if argument:GetType () and argument:GetType ():UnwrapReference ():IsErrorType () then
			suppressErrors = true
			break
		end
	end
	if typeArgumentList then
		for typeArgument in typeArgumentList:GetEnumerator () do
			if typeArgument:UnwrapReference ():IsErrorType () then
				-- SimpleNameResolver should have reported the error already
				suppressErrors = true
				break
			end
		end
	end
	
	local errorMessage = nil
	
	if overloadedFunctionResolver:HasNoResults () then
		-- Build error message
		local overloadCount = overloadedFunctionResolver:GetOverloadCount ()
		
		errorMessage = overloadCount > 0 and "Cannot resolve method call " or "Cannot find method "
		if overloadedFunctionResolver:GetObject () then
			errorMessage = errorMessage .. overloadedFunctionResolver:GetObject ():GetType ():UnwrapReference ():GetFullName () .. ":"
		end
		errorMessage = errorMessage .. methodName
		if typeArgumentList and not typeArgumentList:IsEmpty () then
			errorMessage = errorMessage .. " " .. typeArgumentList:ToString ()
		end
		errorMessage = errorMessage .. " " .. self:GetFormattedArgumentTypes (overloadedFunctionResolver:GetArgumentList ()) .. "."
		
		if overloadCount > 0 then
			errorMessage = errorMessage .. " Methods found:"
			for overload in overloadedFunctionResolver:GetOverloadEnumerator () do
				if overload:IsMethod () or overload:IsASTNode () then
					errorMessage = errorMessage .. "\n\t" .. overload:ToString ()
				else
					errorMessage = errorMessage .. "\n\t" .. overload:GetFullName ()
				end
			end
		end
		
		astNode:SetType (GCompute.ErrorType ())
	elseif overloadedFunctionResolver:IsAmbiguous () then
		errorMessage = "Failed to resolve " .. astNode:ToString () .. ": " .. overloadedFunctionResolver:ToString ()
		astNode:SetType (GCompute.ErrorType ())
	else
		astNode:SetType (functionCall:GetFunctionType ():GetReturnType ())
		if astNode:GetType ():IsErrorType () then
			errorMessage = astNode:ToString () .. "'s type is <error-type> when it shouldn't be (compiler bug?)"
		end
	end
	
	if errorMessage and not suppressErrors then
		astNode:AddErrorMessage (errorMessage)
	end
	
	if functionCall then
		self:ResolveFunctionCallTypeCasts (functionCall)
	end
	return functionCall
end

function self:ResolveFunctionCallTypeCasts (functionCall)
	local functionType = functionCall:GetFunctionType ()
	local parameterList = functionType:GetParameterList ()
	local argumentList = functionCall:GetArgumentList ()
	
	local parameterIndex = 1
	if functionCall:IsMemberFunctionCall () then
		local argument = functionCall:GetLeftExpression ()
		local destinationType = parameterList:GetParameterType (parameterIndex)
		
		local astNode = self:ResolveTypeConversion (argument, destinationType)
		if astNode then
			functionCall:SetLeftExpression (astNode)
		end
		
		parameterIndex = parameterIndex + 1
	end
	for i = 1, argumentList:GetArgumentCount () do
		local argument = argumentList:GetArgument (i)
		local destinationType = parameterList:GetParameterType (parameterIndex)
		
		if not destinationType then
			-- vararg parameter, take last parameter's type
			destinationType = parameterList:GetParameterType (parameterList:GetParameterCount ())
		end
		
		local astNode = self:ResolveTypeConversion (argument, destinationType)
		if astNode then
			argumentList:SetArgument (i, astNode)
		end
		
		parameterIndex = parameterIndex + 1
	end
end

function self:ResolveArrayIndexAssignment (assignmentExpression)
	local arrayIndex = assignmentExpression:GetLeftExpression ()
	local arrayIndexAssignment = GCompute.AST.ArrayIndexAssignment ()
	arrayIndexAssignment:SetStartToken (assignmentExpression:GetStartToken ())
	arrayIndexAssignment:SetEndToken (assignmentExpression:GetEndToken ())
	
	arrayIndexAssignment:SetLeftExpression (arrayIndex:GetLeftExpression ())
	arrayIndexAssignment:SetArgumentList (arrayIndex:GetArgumentList ())
	arrayIndexAssignment:SetTypeArgumentList (arrayIndex:GetTypeArgumentList ())
	arrayIndexAssignment:SetRightExpression (assignmentExpression:GetRightExpression ())
	arrayIndexAssignment = self:VisitArrayIndexAssignment (arrayIndexAssignment) or arrayIndexAssignment
	return arrayIndexAssignment
end

function self:ResolveAssignment (astNode)			
	local assignmentPlan = GCompute.AssignmentPlan ()
	astNode.AssignmentPlan = assignmentPlan
	
	local left = astNode:Is ("VariableDeclaration") and astNode or astNode:GetLeftExpression ()
	local leftNodeType = left:GetNodeType ()
	
	local leftDefinition = nil
	local leftNamespace = nil
	local leftNamespaceType = nil
	
	local right = astNode:GetRightExpression ()
	local rightType = right:GetType ()
	
	if leftNodeType == "Identifier" then
		-- Either local, member
		leftDefinition = left.ResolutionResults:GetFilteredResultObject (1)
	elseif leftNodeType == "VariableDeclaration" then
		-- Either namespace member or local variable
		leftDefinition = left:GetVariableDefinition ()
	elseif leftNodeType == "StaticMemberAccess" then
		-- Global static variable
		leftDefinition = left.ResolutionResults:GetFilteredResultObject (1)
	elseif leftNodeType == "ArrayIndex" then
		return self:ResolveArrayIndexAssignment (astNode)
	else
		-- Either namespace member or member variable
		GCompute.Error ("ResolveAssignment : Unhandled node type on left (" .. leftNodeType .. ", " .. left:ToString () .. ").")
	end
	
	-- Assignment type inference
	if leftDefinition then
		if leftDefinition:IsVariable () or leftDefinition:IsProperty () then
			if leftDefinition:GetType ():IsInferredType () then
				leftDefinition:SetType (rightType:UnwrapReference ())
				left:SetType (rightType:UnwrapReference ())
			end
		end
	end
	
	local leftNamespace = leftDefinition and leftDefinition:GetDeclaringObject ()
	local leftNamespaceType = leftNamespace and leftNamespace:GetNamespace ():GetNamespaceType ()
	
	if leftNamespaceType == GCompute.NamespaceType.Global then
		assignmentPlan:SetAssignmentType (GCompute.AssignmentType.NamespaceMember)
		assignmentPlan:SetLeftRuntimeName (leftNamespace:GetUniqueNameMap ():GetObjectName (leftDefinition))
	elseif leftNamespaceType == GCompute.NamespaceType.Local or
	       leftNamespaceType == GCompute.NamespaceType.FunctionRoot then
		local mergedLocalScope = self:GetMergedLocalScope (leftDefinition)
		assignmentPlan:SetAssignmentType (GCompute.AssignmentType.Local)
		assignmentPlan:SetLeftRuntimeName (mergedLocalScope:GetRuntimeName (left))
	else
		astNode:AddErrorMessage ("TypeInfererTypeAssigner:ResolveAssignment : Cannot handle namespace type of " .. astNode:ToString () .."'s left hand side (" .. (GCompute.NamespaceType [leftNamespaceType] or tostring (leftNamespaceType)) .. ").")
	end
	
	if astNode:Is ("BinaryOperator") then
		local binaryAssignmentOperator = GCompute.AST.BinaryAssignmentOperator ()
		binaryAssignmentOperator:SetStartToken (astNode:GetStartToken ())
		binaryAssignmentOperator:SetEndToken (astNode:GetEndToken ())
		
		binaryAssignmentOperator:SetLeftExpression (astNode:GetLeftExpression ())
		
		if astNode:GetOperator ():sub (1, 1) == "=" then
			binaryAssignmentOperator:SetRightExpression (
				self:ResolveTypeConversion (
					astNode:GetRightExpression (),
					astNode:GetLeftExpression ():GetType ():UnwrapReference ()
				) or astNode:GetRightExpression ()
			)
			binaryAssignmentOperator:SetOperator (astNode:GetOperator ())
		else
			binaryAssignmentOperator:SetOperator ("=")
		
			local binaryOperator = GCompute.AST.BinaryOperator ()
			binaryOperator:SetStartToken (astNode:GetStartToken ())
			binaryOperator:SetEndToken (astNode:GetEndToken ())
			
			binaryOperator:SetLeftExpression (binaryAssignmentOperator:GetLeftExpression ())
			binaryOperator:SetRightExpression (astNode:GetRightExpression ())
			binaryOperator:SetOperator (astNode:GetOperator ():sub (1, 1))
			binaryAssignmentOperator:SetRightExpression (binaryOperator)
			
			self:VisitExpression (binaryOperator)
		end
		binaryAssignmentOperator:SetType (binaryAssignmentOperator:GetLeftExpression ():GetType ():UnwrapReference ())
		binaryAssignmentOperator.FunctionCall = astNode.FunctionCall
		binaryAssignmentOperator.AssignmentPlan = astNode.AssignmentPlan
		return binaryAssignmentOperator
	end
end

function self:ResolveOperatorCall (operatorExpression, methodName, object, argumentList, typeArgumentList)
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Operator, object, argumentList)
	
	overloadedFunctionResolver:AddOperatorOverloads (self.RootNamespaceSet, operatorExpression:GetParentDefinition (), object:GetType (), methodName, typeArgumentList)
	
	-- Resolve OverloadedFunctionResolver
	operatorExpression.FunctionCall = self:ResolveFunctionCall (operatorExpression, overloadedFunctionResolver, methodName, typeArgumentList)
	if operatorExpression.FunctionCall then
		if not operatorExpression.FunctionCall:IsMemberFunctionCall () then
			operatorExpression.FunctionCall:SetLeftExpression (self:CreateStaticMemberAccess (operatorExpression.FunctionCall:GetMethodDefinition ()))
		end
	end
	
	return operatorExpression.FunctionCall
end

function self:ResolveTypeConversion (astNode, destinationType)
	local originalSourceType      = astNode:GetType ()
	local originalDestinationType = destinationType
	
	if not originalSourceType then return end
	
	local sourceType = originalSourceType     :UnwrapAlias ()
	destinationType  = originalDestinationType:UnwrapAlias ()
	
	if sourceType:Equals (destinationType) then return nil, true end
	if sourceType:UnwrapReference ():Equals (destinationType) then return nil, true end
	
	if destinationType:IsReference () then
		astNode:AddErrorMessage ("Cannot convert " .. astNode:GetType ():GetFullName () .. " to a " .. destinationType:GetFullName ())
		return nil, false
	end
	
	sourceType      = sourceType     :UnwrapAliasAndReference ()
	destinationType = destinationType:UnwrapAliasAndReference ()
	
	local _, conversionMethod = sourceType:CanConvertTo (destinationType, GCompute.TypeConversionMethod.ImplicitConversion)
	if conversionMethod == GCompute.TypeConversionMethod.Downcast then
		-- Downcast
		if sourceType:IsNativelyAllocated () and destinationType:IsNativelyAllocated () then return nil, true end
		if sourceType:IsNativelyAllocated () then
			-- Box
			return GCompute.AST.Box (astNode, destinationType), true
		elseif destinationType:IsNativelyAllocated () then
			-- Unbox
			return GCompute.AST.Unbox (astNode, originalDestinationType:UnwrapAlias ()), true
		end
	elseif conversionMethod == GCompute.TypeConversionMethod.Constructor then
		-- Constructor call
		local new = GCompute.AST.New ()
		new:SetStartToken (astNode:GetStartToken ())
		new:SetEndToken (astNode:GetEndToken ())
		
		new:SetLeftExpression (self:CreateStaticMemberAccess (destinationType:GetDefinition ()))
		new:GetArgumentList ():AddArgument (astNode)
		new = self:VisitNew (new) or new
		return new, true
	elseif conversionMethod == GCompute.TypeConversionMethod.ImplicitCast then
		-- Implicit cast method call
		local implicitCast = GCompute.AST.ImplicitCast (astNode, destinationType)
		implicitCast:SetStartToken (astNode:GetStartToken ())
		implicitCast:SetEndToken (astNode:GetEndToken ())
		
		local argumentList = GCompute.AST.ArgumentList ()
		local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Member, astNode, argumentList)
		overloadedFunctionResolver:AddImplicitCastOverloads (self.RootNamespaceSet, sourceType, destinationType)
		implicitCast.FunctionCall = self:ResolveFunctionCall (implicitCast, overloadedFunctionResolver, "implicit operator " .. originalDestinationType:UnwrapReference ():GetFullName ())
		
		return implicitCast, true
	else
		print (GCompute.TypeConversionMethod [conversionMethod] .. ": " .. sourceType:GetFullName () .. " -> " .. destinationType:GetFullName ())
		local suppressErrors = sourceType:UnwrapReference ():IsErrorType () or destinationType:UnwrapReference ():IsErrorType ()
		
		if not suppressErrors then
			astNode:AddErrorMessage ("Cannot implicitly cast a " .. astNode:GetType ():GetFullName () .. " to a " .. destinationType:GetFullName ())
		end
	end
	return nil, false
end

function self:CreateStaticMemberAccess (definition)
	if not definition:GetDeclaringObject () then return nil end
	local typeArgumentList = nil
	if definition:IsClass () and not definition:GetTypeArgumentList ():IsEmpty () then
		typeArgumentList = definition:GetTypeArgumentList ()
	elseif definition:IsMethod () and not definition:GetTypeArgumentList ():IsEmpty () then
		typeArgumentList = definition:GetTypeArgumentList ()
	end
	return GCompute.AST.StaticMemberAccess (self:CreateStaticMemberAccess (definition:GetDeclaringObject ()), definition:GetName (), typeArgumentList)
		:SetResolutionResult (definition)
end

function self:GetMergedLocalScope (memberDefinition)
	local namespace = memberDefinition:GetDeclaringObject ()
	local mergedLocalScope = nil
	while not mergedLocalScope and namespace do
		while not namespace:GetMergedLocalScope () do
			namespace = namespace:GetDeclaringObject ()
		end
		
		if namespace:GetMergedLocalScope ():Contains (memberDefinition) then
			mergedLocalScope = namespace:GetMergedLocalScope ()
		else
			namespace = namespace:GetDeclaringObject ()
		end
	end
	if not namespace then
		self.CompilationUnit:Error ("Failed to find MergedLocalScope for " .. memberDefinition:ToString ())
	end
	return mergedLocalScope
end

function self:GetFormattedArgumentTypes (argumentList)
	local argumentTypes = "("
	for i = 1, argumentList:GetArgumentCount () do
		if i > 1 then
			argumentTypes = argumentTypes .. ", "
		end
		argumentTypes = argumentTypes .. argumentList:GetArgument (i):GetType ():GetFullName ()
	end
	argumentTypes = argumentTypes ..")"
	return argumentTypes
end