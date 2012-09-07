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
		if expression:GetType ():IsDeferredNameResolution () then
			-- There shouldn't be any DeferredNameResolutions here!
			self.CompilationUnit:Error ("Pre-assigned type of " .. expression:ToString () .. " should not be a DeferredNameResolution! (" .. expression:GetType ():ToString () .. ")")
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
	
		if expression.ResolutionResults:GetResult (1) then
			local result = expression.ResolutionResults:GetResult (1).Result
			local metadata = expression.ResolutionResults:GetResult (1).Metadata
			local resultNamespace = result:GetContainingNamespace ()
			local namespaceType = resultNamespace:GetNamespaceType ()
			if namespaceType == GCompute.NamespaceType.Global then
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.NamespaceMember)
				variableReadPlan:SetRuntimeName (resultNamespace:GetRuntimeName (result))
			elseif namespaceType == GCompute.NamespaceType.Local or
			       namespaceType == GCompute.NamespaceType.FunctionRoot then
				local mergedLocalScope = self:GetMergedLocalScope (result)
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				variableReadPlan:SetRuntimeName (mergedLocalScope:GetRuntimeName (result))
			else
				variableReadPlan:SetVariableReadType (GCompute.VariableReadType.Local)
				self.CompilationUnit:Error ("TypeInfererTypeAssigner:VisitExpression : Identifier : Cannot handle namespace type of " .. expression:ToString () .." (" .. GCompute.NamespaceType [namespaceType] .. ").")
			end
			
			if metadata:GetMemberType () == GCompute.MemberTypes.Method then
				if result:GetFunctionCount () == 1 then
					expression:SetType (result:GetFunction (1):GetType ())
				else
					-- overload resolution
					local inferredType = GCompute.InferredType ()
					expression:SetType (inferredType)
					inferredType:ImportFunctionTypes (result)
				end
			elseif metadata:GetMemberType () == GCompute.MemberTypes.Type then
				expression:SetType (GCompute.DeferredNameResolution ("Type"):Resolve ())
			else
				expression:SetType (GCompute.ReferenceType (result:GetType ()))
			end
		else
			expression:SetType (GCompute.NullType ())
			self.CompilationUnit:Error ("Cannot find \"" .. expression:ToString () .. "\".", expression:GetLocation ())
		end
	elseif expression:Is ("FunctionCall") then
		expression:SetType (GCompute.InferredType ())
		
		local leftExpression = expression:GetLeftExpression ()
		local leftType = leftExpression:GetType ()
		if leftType:IsInferredType () then
		elseif leftType:IsFunctionType () then
			local overloadedFunctionDefinition = expression:GetLeftExpression ().ResolutionResults:GetResult (1).Result
			
			local functionResolutionResult = GCompute.FunctionResolutionResult ()
			expression.FunctionResolutionResult = functionResolutionResult
			functionResolutionResult:AddOverloads (overloadedFunctionDefinition)
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
				expression.FunctionCallPlan:SetArgumentCount (expression:GetArgumentCount ())
			end
		else
			expression:SetType (GCompute.NullType ())
			self.CompilationUnit:Error ("Cannot perform a function call on " .. leftExpression:ToString () .. " because it is not a function.", expression:GetLocation ())
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
			expression.FunctionCallPlan:SetArgumentCount (expression:GetArgumentCount ())
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
		expression:SetType (expression:GetType () or GCompute.DeferredNameResolution ("Boolean"):Resolve ())
	elseif expression:Is ("NumericLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredNameResolution ("Number"):Resolve ())
	elseif expression:Is ("StringLiteral") then
		expression:SetType (expression:GetType () or GCompute.DeferredNameResolution ("String"):Resolve ())
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
		-- Either local, member or global
		leftDefinition = left.ResolutionResults:GetResult (1).Result
	elseif leftNodeType == "VariableDeclaration" then
		-- Either namespace member or local variable
		leftDefinition = left:GetVariableDefinition ()
		
		if left:IsAuto () then
			left:SetType (rightType:UnwrapReference ())
		end
	else
		-- Either namespace member or member variable
		GCompute.Error ("ResolveAssignment : I don't even.")
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
	while not mergedLocalScope do
		while not namespace:GetMergedLocalScope () do
			namespace = namespace:GetContainingNamespace ()
		end
		
		if namespace:GetMergedLocalScope ():Contains (memberDefinition) then
			mergedLocalScope = namespace:GetMergedLocalScope ()
		else
			namespace = namespace:GetContainingNamespace ()
		end
	end
	return mergedLocalScope
end