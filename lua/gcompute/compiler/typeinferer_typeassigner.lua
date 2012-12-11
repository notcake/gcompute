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
		
		if statement:GetType () then
			self.CompilationUnit:Debug ("Type of " .. statement:ToString () .. " is " .. statement:GetType ():GetFullName ())
		else
			self.CompilationUnit:Debug (statement:ToString () .. " has no type.")
		end
	end
end

local comparisonOperators =
{
	["=="] = true,
	["!="] = true,
	["<="] = true,
	[">="] = true
}

function self:VisitExpression (expression)
	local overrideExpression = nil

	if expression:GetType () then
		if expression:GetType ():IsDeferredObjectResolution () then
			-- There shouldn't be any DeferredObjectResolutions here!
			self.CompilationUnit:Error ("Pre-assigned type of " .. expression:ToString () .. " should not be a DeferredObjectResolution! (" .. expression:GetType ():ToString () .. ")")
		elseif expression:GetType ():IsTypeDefinition () then
			self.CompilationUnit:Debug ("Pre-assigned type of " .. expression:ToString () .. " is " .. expression:GetType ():GetFullName ())
		else
			self.CompilationUnit:Debug ("Pre-assigned type of " .. expression:ToString () .. " is " .. expression:GetType ():ToString ())
		end
		return
	end
	
	if expression:Is ("Identifier") then
		local variableReadPlan = GCompute.VariableReadPlan ()
		expression.VariableReadPlan = variableReadPlan
	
		if expression.ResolutionResults:GetFilteredResultCount () > 0 then
			local result = expression.ResolutionResults:GetFilteredResultObject (1)
			local resultNamespace = result:GetContainingNamespace ()
			local namespaceType = resultNamespace:GetNamespaceType ()
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
			expression:SetType (GCompute.NullType ())
			self.CompilationUnit:Error ("Cannot find \"" .. expression:ToString () .. "\".", expression:GetLocation ())
		end
	elseif expression:Is ("NameIndex") then
		if expression.ResolutionResults:GetFilteredResultCount () > 0 then
			local result = expression.ResolutionResults:GetFilteredResultObject (1)
			local resultNamespace = result:GetContainingNamespace ()
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
			expression:SetType (GCompute.NullType ())
			self.CompilationUnit:Error ("Cannot find \"" .. expression:ToString () .. "\".", expression:GetLocation ())
		end
	elseif expression:Is ("FunctionCall") then
		expression:SetType (GCompute.InferredType ())
		
		local leftExpression = expression:GetLeftExpression ()
		local leftType = leftExpression:GetType ():UnwrapReference ()
		if leftType:IsInferredType () then
		elseif leftType:IsFunctionType () then
			local leftValue = expression:GetLeftExpression ().ResolutionResults:GetFilteredResultObject (1)
			-- leftValue could be an OverloadedFunctionDefinition or a VariableDefinition
			
			local functionResolutionResult = GCompute.FunctionResolutionResult ()
			expression.FunctionResolutionResult = functionResolutionResult
			if leftValue:IsOverloadedFunctionDefinition () then
				functionResolutionResult:AddOverloads (leftValue)
			else
				functionResolutionResult:AddOverload (leftValue)
			end
			functionResolutionResult:FilterByArgumentTypes (expression:GetArgumentTypes ())
			
			if functionResolutionResult:IsEmpty () then
				self.CompilationUnit:Error ("Failed to resolve " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
				expression:SetType (GCompute.NullType ())
			elseif functionResolutionResult:IsAmbiguous () then
				self.CompilationUnit:Error ("Failed to resolve " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
				expression:SetType (GCompute.NullType ())
			else
				local objectDefinition = functionResolutionResult:GetFilteredOverload (1)
				self.CompilationUnit:Debug ("Resolving " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
				expression:SetType (objectDefinition:GetType ():GetReturnType ())
				
				local functionCallPlan = GCompute.FunctionCallPlan ()
				expression.FunctionCallPlan = functionCallPlan
				
				expression.FunctionCallPlan:SetFunctionName (functionName)
				if objectDefinition:IsFunction () then
					expression.FunctionCallPlan:SetFunctionDefinition (objectDefinition)
				end
				expression.FunctionCallPlan:SetArgumentCount (expression:GetArgumentList ():GetArgumentCount ())
			end
		elseif leftType:IsType () then
			return self:ConvertFunctionCallToConstructor (expression)
		else
			expression:SetType (GCompute.NullType ())
			self.CompilationUnit:Error ("Cannot perform a function call on " .. leftExpression:ToString () .. " because it is not a function (type was " .. leftType:ToString () .. ").", expression:GetLocation ())
		end
	elseif expression:Is ("MemberFunctionCall") then
		expression:SetType (GCompute.InferredType ())
		
		local leftExpression = expression:GetLeftExpression ()
		local leftType = leftExpression:GetType ()
		
		local functionResolutionResult = GCompute.FunctionResolutionResult ()
		expression.FunctionResolutionResult = functionResolutionResult
		functionResolutionResult:AddOverloadsFromType (leftType, expression:GetIdentifier ():GetName ())
		functionResolutionResult:FilterByArgumentTypes (expression:GetArgumentTypes ())
		
		if functionResolutionResult:IsEmpty () then
			self.CompilationUnit:Error ("Failed to resolve " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
			expression:SetType (GCompute.NullType ())
		elseif functionResolutionResult:IsAmbiguous () then
			self.CompilationUnit:Error ("Failed to resolve " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
			expression:SetType (GCompute.NullType ())
		else
			local functionDefinition = functionResolutionResult:GetFilteredOverload (1)
			self.CompilationUnit:Debug ("Resolving " .. expression:ToString () .. ": " .. functionResolutionResult:ToString ())
			expression:SetType (functionDefinition:GetReturnType ())
			
			local functionCallPlan = GCompute.FunctionCallPlan ()
			expression.FunctionCallPlan = functionCallPlan
			
			expression.FunctionCallPlan:SetFunctionName (functionName)
			expression.FunctionCallPlan:SetFunctionDefinition (functionDefinition)
			expression.FunctionCallPlan:SetArgumentCount (expression:GetArgumentList ():GetArgumentCount ())
		end
	elseif expression:Is ("BinaryOperator") then
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
		local operator = expression:GetOperator ()
		if operator:sub (-1, -1) ~= "=" or comparisonOperators [operator] then
			-- Pure binary operator
			self:ResolveOperatorCall (expression, "operator" .. operator, { expression:GetLeftExpression (), expression:GetRightExpression () })
		else
			-- Either binary operator, then assignment
			-- or pure assignment
			overrideExpression = self:ResolveAssignment (expression)
		end
	elseif expression:Is ("BooleanLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Boolean", GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("Number",  GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("StringLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredObjectResolution ("String",  GCompute.ResolutionObjectType.Type):Resolve ())
	elseif expression:Is ("FunctionType") then
		expression:SetType (GCompute.Types.Type)
	elseif expression:Is ("AnonymousFunction") then
		expression:SetType (expression:GetFunctionDefinition ():GetType ())
	else
		expression:SetType (GCompute.InferredType ())
	end
	
	expression = overrideExpression or expression
	if expression:GetType () then
		self.CompilationUnit:Debug ("Type of " .. expression:ToString () .. " is " .. expression:GetType ():GetFullName ())
	else
		self.CompilationUnit:Debug (expression:ToString () .. " has no type.")
	end
	
	return overrideExpression
end

function self:ConvertFunctionCallToConstructor (functionCall)
	local new = GCompute.AST.New ()
	new:SetLeftExpression (functionCall:GetLeftExpression ())
	
	new:SetStartToken (functionCall:GetStartToken ())
	new:SetEndToken (functionCall:GetEndToken ())
	
	new:SetType (functionCall:GetLeftExpression ():GetResolutionResults ():GetFilteredResultObject (1))
	return new
end

function self:ResolveAccessType (astNode)
	local resolutionResults = astNode:GetResolutionResults ()
	local result = resolutionResults:GetFilteredResultObject (1):UnwrapAlias ()
	local metadata = result:GetMetadata ()
	
	if metadata:GetMemberType () == GCompute.MemberTypes.Method then
		if result:GetFunctionCount () == 1 then
			astNode:SetType (result:GetFunction (1):GetType ())
		else
			-- overload resolution
			local inferredType = GCompute.InferredType ()
			astNode:SetType (inferredType)
			inferredType:ImportFunctionTypes (result)
		end
	elseif metadata:GetMemberType () == GCompute.MemberTypes.Type then
		astNode:SetType (GCompute.Types.Type)
	else
		astNode:SetType (GCompute.ReferenceType (result:GetType ()))
	end
end

function self:ResolveOperatorCall (astNode, functionName, arguments)
	local functionResolutionResult = GCompute.FunctionResolutionResult ()
	astNode.FunctionResolutionResult = functionResolutionResult
	
	-- Populate overloads list
	if self.GlobalNamespace:MemberExists (functionName) and
	   self.GlobalNamespace:GetMemberMetadata (functionName):GetMemberType () == GCompute.MemberTypes.Method then
		functionResolutionResult:AddOverloads (self.GlobalNamespace:GetMember (functionName))
	end
	
	functionResolutionResult:AddOverloadsFromType (arguments [1]:GetType (), functionName)
	
	-- Filter overloads list
	local argumentTypes = {}
	for k, argumentExpression in ipairs (arguments) do
		if not argumentExpression:GetType () then
			GCompute.Error ("Argument expression node (" .. argumentExpression:ToString () .. ") has not been assigned a type!")
		end
		argumentTypes [k] = argumentExpression:GetType () or GCompute.NullType ()
	end
	
	functionResolutionResult:FilterByArgumentTypes (argumentTypes)
	if functionResolutionResult:IsEmpty () then
		self.CompilationUnit:Error ("Failed to resolve " .. astNode:ToString () .. ": " .. functionResolutionResult:ToString ())
		astNode:SetType (GCompute.NullType ())
	elseif functionResolutionResult:IsAmbiguous () then
		self.CompilationUnit:Error ("Failed to resolve " .. astNode:ToString () .. ": " .. functionResolutionResult:ToString ())
		astNode:SetType (GCompute.NullType ())
	else
		local functionDefinition = functionResolutionResult:GetFilteredOverload (1)
		self.CompilationUnit:Debug ("Resolving " .. astNode:ToString () .. ": " .. functionResolutionResult:ToString ())
		astNode:SetType (functionDefinition:GetReturnType ())
		
		local functionCallPlan = GCompute.FunctionCallPlan ()
		astNode.FunctionCallPlan = functionCallPlan
		
		astNode.FunctionCallPlan:SetFunctionName (functionName)
		astNode.FunctionCallPlan:SetFunctionDefinition (functionDefinition)
		astNode.FunctionCallPlan:SetArgumentCount (#arguments)
	end
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
	else
		-- Either namespace member or member variable
		GCompute.Error ("ResolveAssignment : Unhandled node type on left (" .. leftNodeType .. ", " .. left:ToString () .. ").")
	end
	
	local leftNamespace = leftDefinition:GetContainingNamespace ()
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
		binaryAssignmentOperator.FunctionCallPlan = astNode.FunctionCallPlan
		binaryAssignmentOperator.AssignmentPlan = astNode.AssignmentPlan
		return binaryAssignmentOperator
	end
end

function self:GetMergedLocalScope (memberDefinition)
	local namespace = memberDefinition:GetContainingNamespace ()
	local mergedLocalScope = nil
	while not mergedLocalScope and namespace do
		while not namespace:GetMergedLocalScope () do
			namespace = namespace:GetContainingNamespace ()
		end
		
		if namespace:GetMergedLocalScope ():Contains (memberDefinition) then
			mergedLocalScope = namespace:GetMergedLocalScope ()
		else
			namespace = namespace:GetContainingNamespace ()
		end
	end
	if not namespace then
		self.CompilationUnit:Error ("Failed to find MergedLocalScope for " .. memberDefinition:ToString ())
	end
	return mergedLocalScope
end