local self = {}
GCompute.TypeInfererTypeAssigner = GCompute.MakeConstructor (self, GCompute.ASTVisitor)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
	self.CompilationGroup = self.CompilationUnit and self.CompilationUnit:GetCompilationGroup ()
	self.GlobalNamespace = self.CompilationGroup and self.CompilationGroup:GetNamespaceDefinition ()
end

function self:VisitStatement (statement)
	if statement:Is ("VariableDeclaration") then
		if statement:GetRightExpression () then
			self:ResolveAssignment (statement)
		end
		
		-- Replacing Identifiers and NameIndexes with *Accesses causes the
		-- type of VariableDefinitions to be reset, so we have to set them
		-- again here.
		local typeResults = statement:GetTypeExpression ():GetResolutionResults ()
		statement:SetType (typeResults:GetFilteredResultObject (1))
		statement:GetVariableDefinition ():SetType (typeResults:GetFilteredResultObject (1))
		
		if not statement:GetType () then
			statement:AddErrorMessage (statement:ToString () .. " has no type.")
		elseif statement:GetType ():UnwrapAlias ():IsErrorType () then
			statement:AddErrorMessage ("Type of " .. statement:ToString () .. " is " .. statement:GetType ():GetFullName ())
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
				
				staticMemberAccess:SetLeftExpression (resultNamespace:CreateStaticMemberAccessNode ())
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
			self.CompilationUnit:Error ("Cannot find \"" .. expression:ToString () .. "\".", expression:GetLocation ())
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
			self.CompilationUnit:Error ("Cannot find \"" .. expression:ToString () .. "\".", expression:GetLocation ())
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
	elseif expression:Is ("BooleanLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Boolean", GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Number",  GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("StringLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("String",  GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("FunctionType") then
		expression:SetType (self.GlobalNamespace:GetTypeSystem ():GetType ())
	elseif expression:Is ("AnonymousFunction") then
		expression:SetType (expression:GetMethodDefinition ():GetType ())
	else
		expression:SetType (GCompute.ErrorType ())
	end
	
	expression = overrideExpression or expression
	if not expression:GetType () then
		expression:AddErrorMessage (expression:ToString () .. " has no type.")
	elseif expression:GetType ():UnwrapAlias ():IsErrorType () then
		expression:AddErrorMessage ("Type of " .. expression:ToString () .. " is " .. expression:GetType ():GetFullName ())
	end
	
	return overrideExpression
end

function self:VisitArrayIndex (arrayIndex)
	self:ResolveOperatorCall (arrayIndex, "operator[]", arrayIndex:GetLeftExpression (), arrayIndex:GetArgumentList (), arrayIndex:GetTypeArgumentList () and arrayIndex:GetTypeArgumentList ():ToTypeArgumentList ())
end

function self:VisitArrayIndexAssignment (arrayIndexAssignment)
	local argumentList = arrayIndexAssignment:GetArgumentList ():Clone ()
	argumentList:AddArgument (arrayIndexAssignment:GetRightExpression ())
	self:ResolveOperatorCall (arrayIndexAssignment, "operator[]", arrayIndexAssignment:GetLeftExpression (), argumentList, arrayIndexAssignment:GetTypeArgumentList () and arrayIndexAssignment:GetTypeArgumentList ():ToTypeArgumentList ())
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
		
		self:ResolveOperatorCall (binaryOperator, "operator" .. operator, binaryOperator:GetLeftExpression (), argumentList)
		if binaryOperator.FunctionCall then
			if binaryOperator.FunctionCall:IsMemberFunctionCall () then
				binaryOperator:SetLeftExpression (binaryOperator.FunctionCall:GetLeftExpression ())
				binaryOperator:SetRightExpression (binaryOperator.FunctionCall:GetArgumentList ():GetArgument (1))
			else
				binaryOperator:SetLeftExpression (binaryOperator.FunctionCall:GetArgumentList ():GetArgument (1))
				binaryOperator:SetRightExpression (binaryOperator.FunctionCall:GetArgumentList ():GetArgument (2))
			end
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
	
	local leftType = leftExpression:GetType ():UnwrapReference ()
	if leftType:IsInferredType () then
	elseif leftType:IsFunctionType () then
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
			self.CompilationUnit:Error ("Left hand side of function call is not a function! (" .. expression:GetLeftExpression ():ToString () .. ")")
		end
		
		-- Resolve OverloadedFunctionResolver
		functionCall.FunctionCall = self:ResolveFunctionCall (functionCall, overloadedFunctionResolver)
		if functionCall.FunctionCall then
			if not functionCall.FunctionCall:IsMemberFunctionCall () then
				functionCall.FunctionCall:SetLeftExpression (leftExpression)
			end
		end
	elseif leftDefinition and (leftDefinition:UnwrapAlias ():IsType () or leftDefinition:UnwrapAlias ():IsOverloadedClass ()) then
		return self:ConvertFunctionCallToConstructor (functionCall)
	else
		functionCall:SetType (GCompute.ErrorType ())
		self.CompilationUnit:Error ("Cannot perform a function call on " .. leftExpression:ToString () .. " because it is not a function (type was " .. leftType:ToString () .. ").", functionCall:GetLocation ())
	end
end

function self:VisitMemberFunctionCall (memberFunctionCall)
	local leftExpression = memberFunctionCall:GetLeftExpression ()
	local leftType = leftExpression:GetType ()
	
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Member, leftExpression, memberFunctionCall:GetArgumentList ())
	
	-- Populate OverloadedFunctionResolver
	overloadedFunctionResolver:AddMemberOverloads (leftType, memberFunctionCall:GetIdentifier ():GetName (), memberFunctionCall:GetTypeArgumentList () and memberFunctionCall:GetTypeArgumentList ():ToTypeArgumentList ())
	
	-- Resolve OverloadedFunctionResolver
	memberFunctionCall.FunctionCall = self:ResolveFunctionCall (memberFunctionCall, overloadedFunctionResolver)
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
	local leftResolutionResults = leftExpression:GetResolutionResults ()
	
	-- Need to resolve leftExpression as a type
	leftResolutionResults:FilterToConcreteTypes ()
	
	if leftResolutionResults:GetFilteredResultCount () == 0 then
		leftExpression:AddErrorMessage (leftExpression:ToString () .. " is not a type.")
		return
	elseif leftResolutionResults:GetFilteredResultCount () > 1 then
		leftExpression:AddErrorMessage (leftExpression:ToString () .. " is ambiguous as a type name.")
		return
	end
	local leftDefinition = leftExpression:GetResolutionResults ():GetFilteredResultObject (1)
	
	if not leftDefinition:UnwrapAlias ():IsType () or leftDefinition:UnwrapAlias ():IsOverloadedClass () then
		self.CompilationUnit:Error ("Left hand side of <new-expression> must be a type! (" .. leftExpression:ToString () .. " is not a type).", leftExpression:GetLocation ())
		return
	end
	
	-- leftDefinition is (an alias to) a Type, ClassDefinition or OverloadedClassDefinition
	local type = leftDefinition
	if type:IsOverloadedClass () and type:GetClassCount () == 1 then
		type = type:GetClass (1)
	end
	type = type:ToType ()
	new:SetType (type)
	
	-- Constructor resolution
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.OverloadedFunctionResolver.Static, nil, new:GetArgumentList ())
	
	-- Populate OverloadedFunctionResolver
	for constructor in leftDefinition:UnwrapAlias ():GetConstructorEnumerator () do
		overloadedFunctionResolver:AddOverload (constructor)
	end
	
	-- Resolve OverloadedFunctionResolver
	new.FunctionCall = self:ResolveFunctionCall (new, overloadedFunctionResolver)
	new:SetNativelyAllocated (leftDefinition:ToType ():IsNativelyAllocated ())
	
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
		if result:GetMethodCount () == 1 then
			astNode:SetType (result:GetMethod (1):GetType ())
		else
			-- overload resolution
			local inferredType = GCompute.InferredType ()
			astNode:SetType (inferredType)
			inferredType:ImportFunctionTypes (result)
		end
	elseif result:IsOverloadedClass () or result:IsType () then
		astNode:SetType (self.GlobalNamespace:GetTypeSystem ():GetType ())
	else
		astNode:SetType (GCompute.ReferenceType (result:GetType ()))
	end
end

function self:ResolveFunctionCall (astNode, overloadedFunctionResolver)
	local functionCall = overloadedFunctionResolver:Resolve ()
	
	if overloadedFunctionResolver:HasNoResults () then
		astNode:AddErrorMessage ("Failed to resolve " .. astNode:ToString () .. ": " .. overloadedFunctionResolver:ToString ())
		astNode:SetType (GCompute.ErrorType ())
	elseif overloadedFunctionResolver:IsAmbiguous () then
		astNode:AddErrorMessage ("Failed to resolve " .. astNode:ToString () .. ": " .. overloadedFunctionResolver:ToString ())
		astNode:SetType (GCompute.ErrorType ())
	else
		self.CompilationUnit:Debug ("Resolving " .. astNode:ToString () .. ": " .. overloadedFunctionResolver:ToString ())
		astNode:SetType (functionCall:GetFunctionType ():GetReturnType ())
	end
	
	if functionCall then
		self:ResolveFunctionCallTypeCasts (functionCall)
	end
	return functionCall
end

function self:ResolveFunctionCallTypeCasts (functionCall)
	local functionType = functionCall:GetFunctionType ()
	local parameterList = functionType:GetParameterList ()
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
		
		if left:IsAuto () then
			left:SetType (rightType:UnwrapReference ())
		end
	elseif leftNodeType == "StaticMemberAccess" then
		-- Global static variable
		leftDefinition = left.ResolutionResults:GetFilteredResultObject (1)
	elseif leftNodeType == "ArrayIndex" then
		return self:ResolveArrayIndexAssignment (astNode)
	else
		-- Either namespace member or member variable
		GCompute.Error ("ResolveAssignment : Unhandled node type on left (" .. leftNodeType .. ", " .. left:ToString () .. ").")
	end
	
	local leftNamespace = leftDefinition:GetDeclaringObject ()
	local leftNamespaceType = leftNamespace:GetNamespaceType ()
	
	if leftNamespaceType == GCompute.NamespaceType.Global then
		assignmentPlan:SetAssignmentType (GCompute.AssignmentType.NamespaceMember)
		assignmentPlan:SetLeftRuntimeName (leftNamespace:GetUniqueNameMap ():GetObjectName (leftDefinition))
	elseif leftNamespaceType == GCompute.NamespaceType.Local then
		local mergedLocalScope = self:GetMergedLocalScope (leftDefinition)
		assignmentPlan:SetAssignmentType (GCompute.AssignmentType.Local)
		assignmentPlan:SetLeftRuntimeName (mergedLocalScope:GetRuntimeName (left))
	else
		self.CompilationUnit:Error ("TypeInfererTypeAssigner:ResolveAssignment : Cannot handle namespace type of " .. astNode:ToString () .."'s left hand side (" .. GCompute.NamespaceType [leftNamespaceType] .. ").")
	end
	
	if astNode:Is ("BinaryOperator") then
		local binaryAssignmentOperator = GCompute.AST.BinaryAssignmentOperator ()
		binaryAssignmentOperator:SetLeftExpression (astNode:GetLeftExpression ())
		
		if astNode:GetOperator ():sub (1, 1) == "=" then
			binaryAssignmentOperator:SetRightExpression (astNode:GetRightExpression ())
			binaryAssignmentOperator:SetOperator (astNode:GetOperator ())
		else
			binaryAssignmentOperator:SetOperator ("=")
		
			local binaryOperator = GCompute.AST.BinaryOperator ()
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

function self:ResolveOperatorCall (astNode, methodName, object, argumentList, typeArgumentList)
	local overloadedFunctionResolver = GCompute.OverloadedFunctionResolver (GCompute.FunctionResolutionType.Operator, object, argumentList)
	
	overloadedFunctionResolver:AddOperatorOverloads (self.GlobalNamespace, object:GetType (), methodName, typeArgumentList)
	
	-- Resolve OverloadedFunctionResolver
	astNode.FunctionCall = self:ResolveFunctionCall (astNode, overloadedFunctionResolver)
	if astNode.FunctionCall then
		if not astNode.FunctionCall:IsMemberFunctionCall () then
			astNode.FunctionCall:SetLeftExpression (astNode.FunctionCall:GetMethodDefinition ():CreateStaticMemberAccessNode ())
		end
	end
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
	
	if destinationType:IsBaseTypeOf (sourceType) then
		-- Downcast
		if sourceType:IsNativelyAllocated () and destinationType:IsNativelyAllocated () then return nil, true end
		if sourceType:IsNativelyAllocated () then
			-- Box
			print ("ResolveTypeConversion: Box " .. sourceType:GetFullName () .. " -> " .. destinationType:GetFullName ())
			return GCompute.AST.Box (astNode, destinationType), true
		elseif destinationType:IsNativelyAllocated () then
			-- Unbox
			print ("ResolveTypeConversion: Unbox " .. sourceType:GetFullName () .. " -> " .. destinationType:GetFullName ())
			return GCompute.AST.Unbox (astNode, originalDestinationType:UnwrapAlias ()), true
		end
	end
	print ("ResolveTypeConversion: " .. sourceType:GetFullName () .. " -> " .. destinationType:GetFullName ())
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