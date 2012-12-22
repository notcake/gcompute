local self = {}
GCompute.OverloadedFunctionResolver = GCompute.MakeConstructor (self)

--[[
	OverloadedFunctionResolver
	
	Resolves overloaded functions.
	Performs type parameter inference.
	Based loosely on http://msdn.microsoft.com/en-us/library/aa691336%28v=vs.71%29.aspx.
	
	[Static Function Call] A.B ()
		B is a     static     member function         - Exclude self
		B is a non-static     member function         - Include self, possible virtual call
		B is a                member variable         - Exclude self
		B is a            non-member function         - Exclude self
		B is a            non-member variable         - Exclude self
	
	[Member Function Call] A:B ()
		B is a     static member function             - Exclude self
		B is a non-static member function             - Include self, possible virtual call
		B is a            member variable             - Include self, possible virtual call
	
	[Operator        Call] A + B or A[B] or A ()
		A.operator+ is a     static member function   - Include self
		A.operator+ is a non-static member function   - Include self, possible virtual call
		  operator+ is a            global function   - Include self
		A           is a                   function   - Exclude self
	
	Static function            --> Include self if operator
	Non-static member function --> Always include self, possible virtual call
	Operator call              --> Always include self, possible virtual call if non-static member function
]]

function self:ctor (functionResolutionType, objectOrArgumentList, argumentList)
	self.FunctionResolutionType = functionResolutionType
	
	if argumentList then
		self.Object       = objectOrArgumentList
		self.ArgumentList = argumentList
	else
		self.Object       = nil
		self.ArgumentList = objectOrArgumentList
	end
	
	self.Overloads = {}
	self.OverloadTypeArgumentLists = {}
	self.ApplicableOverloads = {}
	self.ApplicableOverloadTypeArgumentLists = {}
	self.ApplicableOverloadCallPlans = {}
	self.IncompatibleSet  = {}
	self.WorseOverloadSet = {}
	
	-- Result
	self.NoResults = false
	self.Ambiguous = false
end

function self:AddMemberOverloads (type, methodName, typeArgumentList)
	type = type and type:UnwrapReference ()
	if not type then return end

	local namespace = type:GetNamespace ()
	if namespace then
		-- Add matching members of the specified type
		local memberDefinition = namespace:GetMember (methodName)
		if not memberDefinition then
		elseif memberDefinition:IsOverloadedMethod () then
			self:AddOverloads (memberDefinition, typeArgumentList)
		elseif memberDefinition:IsMethod () then
			self:AddOverload (memberDefinition, typeArgumentList)
		end
	end
	
	-- Add matching members of the specified type's base types
	for baseType in type:GetBaseTypeEnumerator () do
		self:AddMemberOverloads (baseType, methodName, typeArgumentList)
	end
end

function self:AddOperatorOverloads (globalNamespace, objectType, methodName, typeArgumentList)
	local memberDefinition = globalNamespace and globalNamespace:GetMember (methodName) or nil
	if not memberDefinition then
	elseif memberDefinition:IsOverloadedMethod () then
		self:AddOverloads (memberDefinition, typeArgumentList)
	elseif memberDefinition:IsMethod () then
		self:AddOverload (memberDefinition, typeArgumentList)
	end
	
	self:AddMemberOverloads (objectType, methodName, typeArgumentList)
end

--- Adds a MethodDefinition or ObjectDefinition whose type is a FunctionType
-- @param objectDefinition The ObjectDefinition to be added
-- @param typeArgumentList The type parameters for the ObjectDefinition. If not provided, type parameters will attempt to be inferred
function self:AddOverload (objectDefinition, typeArgumentList)
	local nextOverloadId = #self.Overloads + 1
	self.Overloads [nextOverloadId] = objectDefinition
	self.OverloadTypeArgumentLists [nextOverloadId] = typeArgumentList
end

--- Adds the FunctionDefinitions in an OverloadedMethodDefinition
-- @param overloadedFunctionDefinition The OverloadedMethodDefinition
-- @param typeArgumentList The type parameters for the MethodDefinitions. If a MethodDefinition has no unbound type parameters, this is ignored
function self:AddOverloads (overloadedMethodDefinition, typeArgumentList)
	for methodDefinition in overloadedMethodDefinition:GetEnumerator () do
		self:AddOverload (methodDefinition, typeArgumentList)
	end
end

function self:GetArgumentList ()
	return self.ArgumentList
end

function self:GetFunctionResolutionType ()
	return self.FunctionResolutionType
end

function self:HasNoResults ()
	return self.NoResults
end

function self:IsAmbiguous ()
	return self.Ambiguous
end

--- Performs overloaded function resolution and returns a FunctionCall or MemberFunctionCall
-- @return A FunctionCall or MemberFunctionCall
function self:Resolve ()
	self:IdentifyApplicableOverloads ()
	
	self.IncompatibleSet = {}
	
	for i = 1, #self.ApplicableOverloads do
		self.ApplicableOverloadCallPlans [i] = self:ResolveOverloadCallPlan (self.ApplicableOverloads [i], self.ApplicableOverloadTypeArgumentLists [i], self.ApplicableOverloadCallPlans [i])
		if self.ApplicableOverloadCallPlans [i].Incompatible then
			self.IncompatibleSet [self.ApplicableOverloads [i]] = true
		end
	end
	
	self.WorseOverloadSet = {}
	for i = 1, #self.ApplicableOverloads do
		if not self.IncompatibleSet [self.ApplicableOverloads [i]] then
			for j = i + 1, #self.ApplicableOverloads do
				if not self.IncompatibleSet [self.ApplicableOverloads [j]] and
				   self:IsBetterThan (self.ApplicableOverloadCallPlans [i], self.ApplicableOverloadCallPlans [j]) then
					self.WorseOverloadSet [self.ApplicableOverloads [j]] = true
				end
			end
		end
	end
	
	local bestOverloadIndex = nil
	for i = 1, #self.ApplicableOverloads do
		if not self.IncompatibleSet [self.ApplicableOverloads [i]] and
		   not self.WorseOverloadSet[self.ApplicableOverloads [i]] then
			-- Check for multiple suitable overloads
			if bestOverloadIndex then
				self.Ambiguous = true
				return nil
			end
			bestOverloadIndex = i
		end
	end
	
	-- Check for no suitable overloads
	if not bestOverloadIndex then
		self.NoResults = true
		return nil
	end
	
	local bestOverload = self.ApplicableOverloads [bestOverloadIndex]
	local bestOverloadCallPlan = self.ApplicableOverloadCallPlans [bestOverloadIndex]
	
	local functionCall
	local argumentListCloned = false
	local argumentList = self.ArgumentList
	if bestOverloadCallPlan.IncludeObject and not bestOverload:IsMemberStatic () then
		-- MemberFunctionCall
		functionCall = GCompute.MemberFunctionCall ()
		functionCall:SetLeftExpression (self.Object)
	else
		-- FunctionCall
		functionCall = GCompute.FunctionCall ()
		if self.Object then
			if not argumentListCloned then
				argumentList = argumentList:Clone ()
			end
			argumentList:InsertArgument (1, self.Object)
		end
	end
	functionCall:SetMethodName (bestOverload:IsObjectDefinition () and bestOverload:GetName ())
	functionCall:SetFunctionType (bestOverload:GetType ())
	if bestOverload:IsObjectDefinition () and bestOverload:IsMethod () then
		if bestOverloadCallPlan.TypeArgumentList then
			local typeCurriedMethodDefinition = bestOverload:CreateTypeCurriedDefinition (bestOverloadCallPlan.TypeArgumentList)
			functionCall:SetMethodDefinition (typeCurriedMethodDefinition)
			functionCall:SetFunctionType (typeCurriedMethodDefinition:GetType ())
		else
			functionCall:SetMethodDefinition (bestOverload)
		end
	end
	functionCall:SetArgumentList (self.ArgumentList)
	
	if bestOverloadCallPlan.TypeArgumentList then
		functionCall:SetTypeArgumentList (bestOverloadCallPlan.TypeArgumentList)
	end
	
	return functionCall
end

--- Returns a string representation of this OverloadedFunctionResolver
-- @return A string representation of this OverloadedFunctionResolver
function self:ToString ()
	local overloadedFunctionResolver = "[Overloaded Function Resolver]\n"
	overloadedFunctionResolver = overloadedFunctionResolver .. "{\n"
	
	if self.Object then
		overloadedFunctionResolver = overloadedFunctionResolver .. "    Arguments: " .. (self.Object:GetType () and self.Object:GetType ():GetFullName () or "<error-type>") .. ":" .. self.ArgumentList:ToTypeString () .. "\n"
	else
		overloadedFunctionResolver = overloadedFunctionResolver .. "    Arguments: " .. self.ArgumentList:ToTypeString () .. "\n"
	end
	
	overloadedFunctionResolver = overloadedFunctionResolver .. "\n"
	
	local applicableOverloadSet = {}
	for k, objectDefinition in ipairs (self.ApplicableOverloads) do
		applicableOverloadSet [objectDefinition] = true
		local status = "Better"
		if self.IncompatibleSet [objectDefinition] then status = "Incompatible"
		elseif self.WorseOverloadSet [objectDefinition] then status = "Applicable"
		end
		overloadedFunctionResolver = overloadedFunctionResolver .. "    [" .. status .. (self.ApplicableOverloadTypeArgumentLists [k] and (" " .. self.ApplicableOverloadTypeArgumentLists [k]:ToString ()) or "") .. "] " .. objectDefinition:ToString () .. "\n"
	end
	
	for k, objectDefinition in ipairs (self.Overloads) do
		if not applicableOverloadSet [objectDefinition] then
			overloadedFunctionResolver = overloadedFunctionResolver .. "    [Unapplicable" .. (self.OverloadTypeArgumentLists [k] and (" " .. self.OverloadTypeArgumentLists [k]:ToString ()) or "") .. "] " .. objectDefinition:ToString () .. "\n"
		end
	end
	
	overloadedFunctionResolver = overloadedFunctionResolver .. "}"
	return overloadedFunctionResolver
end

-- Internal, do not call
function self:IdentifyApplicableOverloads ()
	self.ApplicableOverloads = {}
	self.ApplicableOverloadTypeArgumentLists = {}
	self.ApplicableOverloadCallPlans = {}
	
	for i = 1, #self.Overloads do
		local overload = self.Overloads [i]
		
		local includeObject = self.Object and self:ShouldIncludeObjectInCall (overload) or false
		local functionType = overload:GetType ()
		
		if functionType:IsFunctionType () and
		   functionType:GetParameterList ():MatchesArgumentCount (self.ArgumentList:GetArgumentCount () + (includeObject and 1 or 0)) then
			local nextApplicableOverloadId = #self.ApplicableOverloads + 1
			self.ApplicableOverloads [nextApplicableOverloadId] = self.Overloads [i]
			self.ApplicableOverloadTypeArgumentLists [nextApplicableOverloadId] = self.OverloadTypeArgumentLists [i]
			self.ApplicableOverloadCallPlans [nextApplicableOverloadId] = { IncludeObject = includeObject }
		end
	end
end

function self:IsBetterThan (leftCallPlan, rightCallPlan)
	if leftCallPlan.DowncastCount + leftCallPlan.ImplicitCastCount < rightCallPlan.DowncastCount + rightCallPlan.ImplicitCastCount then return true end
	if leftCallPlan.ImplicitCastCount < rightCallPlan.ImplicitCastCount then return true end
	return false
end

function self:ResolveOverloadCallPlan (objectDefinition, typeArgumentList, overloadCallPlan)
	-- objectDefinition may be an ObjectDefinition or an AST node whose type is a function
	
	overloadCallPlan.Incompatible = false
	overloadCallPlan.TypeConversions = {}
	overloadCallPlan.DestinationTypes = {}
	
	-- Generate type parameter substitution map
	local typeParameterMap = {}
	local typeParameterList = GCompute.EmptyTypeParameterList
	
	if objectDefinition:IsObjectDefinition () and objectDefinition:IsMethod () then
		typeParameterList = objectDefinition:GetTypeParameterList ()
	end
	
	typeArgumentList = typeArgumentList or GCompute.EmptyTypeArgumentList
	for i = 1, typeArgumentList:GetArgumentCount () do
		local typeParameter = objectDefinition:GetNamespace ():GetMember (typeParameterList:GetParameterName (i))
		typeParameterMap [typeParameter] = typeArgumentList:GetArgument (i)
	end
	
	local inferredTypeArgumentList = nil
	
	local functionType = objectDefinition:GetType ()
	local parameterList = functionType:GetParameterList ()
	
	local argumentTypes = self.ArgumentList:GetArgumentTypes ()
	if overloadCallPlan.IncludeObject then
		table.insert (argumentTypes, 1, self.Object:GetType ())
	end
	
	-- Work out type conversion methods for each argument
	for i = 1, #argumentTypes do
		local destinationType = parameterList:GetParameterType (#overloadCallPlan.TypeConversions + 1) or parameterList:GetParameterType (parameterList:GetParameterCount ())
		destinationType = typeParameterMap [destinationType] or destinationType
		
		-- Check for type parameters and attempt to infer them
		if destinationType:IsTypeParameter () and destinationType:GetDefinition ():GetDeclaringMethod () == objectDefinition then
			if not inferredTypeArgumentList then
				-- Create the inferred TypeArgumentList since it doesn't already exist
				inferredTypeArgumentList = typeArgumentList:Clone ()
				
				-- Populate the inferred TypeArgumentList's empty arguments with ErrorTypes
				for j = 1, typeParameterList:GetParameterCount () do
					inferredTypeArgumentList:SetArgument (j, inferredTypeArgumentList:GetArgument (i) or GCompute.ErrorType ())
				end
			end
			
			-- Set the inferred type argument, unwrapping references
			local inferredTypeArgument = argumentTypes [i]:UnwrapReference ()
			inferredTypeArgumentList:SetArgument (destinationType:GetTypeParameterPosition (), inferredTypeArgument)
			typeParameterMap [destinationType] = inferredTypeArgument
			destinationType = inferredTypeArgument
		end
		
		local _, typeConversionMethod = argumentTypes [i]:UnwrapAlias ():CanConvertTo (destinationType, GCompute.TypeConversionMethod.ImplicitConversion)
		overloadCallPlan.DestinationTypes [#overloadCallPlan.DestinationTypes + 1] = parameterList:GetParameterType (#overloadCallPlan.TypeConversions + 1)
		overloadCallPlan.TypeConversions [#overloadCallPlan.TypeConversions + 1] = typeConversionMethod
	end
	
	if not typeParameterList:IsEmpty () then
		overloadCallPlan.TypeArgumentList = inferredTypeArgumentList or typeArgumentList
	end
	overloadCallPlan.DowncastCount = 0
	overloadCallPlan.ImplicitCastCount = 0
	for i = (overloadCallPlan.IncludeObject and 2 or 1), #overloadCallPlan.TypeConversions do
		local typeConversionMethod = overloadCallPlan.TypeConversions [i]
		overloadCallPlan.Incompatible = overloadCallPlan.Incompatible or typeConversionMethod == GCompute.TypeConversionMethod.None
		if typeConversionMethod == GCompute.TypeConversionMethod.None then
			overloadCallPlan.Incompatible = true
		elseif typeConversionMethod == GCompute.TypeConversionMethod.Identity then
		elseif typeConversionMethod == GCompute.TypeConversionMethod.Downcast then
			overloadCallPlan.DowncastCount = overloadCallPlan.DowncastCount + 1
		else
			overloadCallPlan.ImplicitCastCount = overloadCallPlan.ImplicitCastCount + 1
		end
	end
	
	overloadCallPlan.ReturnType = functionType:GetReturnType ()
	overloadCallPlan.ReturnType = typeParameterMap [overloadCallPlan.ReturnType] or overloadCallPlan.ReturnType
	return overloadCallPlan
end

function self:ShouldIncludeObjectInCall (objectDefinition)
	if self.FunctionResolutionType == GCompute.FunctionResolutionType.Operator then return true end
	if objectDefinition:IsMethod () and objectDefinition:IsMemberFunction () and not objectDefinition:IsMemberStatic () then return true end
	if self.FunctionResolutionType == GCompute.FunctionResolutionType.Member and not objectDefinition:IsMethod () then return true end
	return false
end