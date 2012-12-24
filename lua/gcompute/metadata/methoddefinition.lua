local self = {}
GCompute.MethodDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this method
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function takes no parameters
-- @param typeParameterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
function self:ctor (name, parameterList, typeParameterList)
	-- Children
	self.Namespace = GCompute.Namespace ()
	self.Namespace:SetDefinition (self)
	self.Namespace:SetNamespaceType (GCompute.NamespaceType.FunctionRoot)
	self.NamespaceValid = false
	
	-- Method
	self.ReturnType = GCompute.DeferredObjectResolution ("void", GCompute.ResolutionObjectType.Type)
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	
	if type (self.ParameterList) == "string" then
		self.ParameterList = GCompute.TypeParser (self.ParameterList):ParameterList ()
		local messages = self.ParameterList:GetMessages ()
		if messages then
			ErrorNoHalt ("In \"" .. parameterList .. "\":\n" .. messages:ToString () .. "\n")
		end
		self.ParameterList = self.ParameterList:ToParameterList ()
	elseif #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
	
	-- AST
	self.FunctionDeclaration = nil
	self.BlockStatement      = nil
	
	self.NativeString = nil
	self.NativeFunction = nil
	
	-- Type Parameters
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	self.TypeArgumentList = GCompute.EmptyTypeArgumentList
	
	self.TypeParametricMethodDefinition = self
	self.TypeCurriedDefinitions         = GCompute.WeakValueTable ()
	self.TypeCurryerFunction            = GCompute.NullCallback
	
	-- Runtime
	self.MergedLocalScope = nil
end

-- Hierarchy
--- Gets the short name of this function
-- @return The short name of this function
function self:GetShortName ()
	if self:GetTypeParameterList ():IsEmpty () then
		return self:GetName () or "[Unnamed]"
	elseif self:GetTypeArgumentList ():IsEmpty () then
		return (self:GetName () or "[Unnamed]") .. " " .. self:GetTypeParameterList ():ToString ()
	else
		return (self:GetName () or "[Unnamed]") .. " " .. self:GetTypeArgumentList ():ToString ()
	end
end

-- Children
function self:GetNamespace ()
	if not self.NamespaceValid then
		self:BuildNamespace ()
	end
	return self.Namespace
end

-- Method
--- Gets the native implementation of this function
-- @return The native implementation of this function
function self:GetNativeFunction ()
	return self.NativeFunction
end

--- Gets the native inline code for this function
-- @return The native inline code for this function
function self:GetNativeString ()
	return self.NativeString
end

function self:GetParameterCount ()
	return self.ParameterList:GetParameterCount ()
end

--- Gets the parameter list of this function
-- @return The parameter list of this function
function self:GetParameterList ()
	return self.ParameterList
end

function self:GetParameterName (index)
	return self.ParameterList:GetParameterName (index)
end

--- Gets the return type of this function as a DeferredObjectResolution or Type
-- @return A DeferredObjectResolution or Type representing the return type of this function
function self:GetReturnType ()
	return self.ReturnType
end

--- Gets whether this function is a member function
-- @return A boolean indicating whether this function is a member function
function self:IsMemberFunction ()
	if not self:GetDeclaringType () then return false end
	if self:IsMemberStatic () then return false end
	return true
end

--- Sets the native implementation of this function
-- @param nativeFunction The native implementation of this function
function self:SetNativeFunction (nativeFunction)
	self.NativeFunction = nativeFunction
	return self
end

--- Sets the native inline code for this function
-- @param nativeString The native inline code for this function
function self:SetNativeString (nativeString)
	self.NativeString = nativeString
	return self
end

--- Sets the return type of this function
-- @param returnType The return type as a string or DeferredObjectResolution or Type
function self:SetReturnType (returnType)
	self.ReturnType = GCompute.ToDeferredTypeResolution (returnType, self:GetGlobalNamespace (), self)
	return self
end

-- AST
function self:GetBlockStatement ()
	return self.BlockStatement
end

--- Gets the FunctionDeclaration syntax tree node corresponding to this function
-- @return The FunctionDeclaration corresponding to this function
function self:GetFunctionDeclaration ()
	return self.FunctionDeclaration
end

function self:SetBlockStatement (blockStatement)
	self.BlockStatement = blockStatement
end

--- Sets the FunctionDeclaration syntax tree node corresponding to this function
-- @param functionDeclaration The FunctionDeclaration corresponding to this function
function self:SetFunctionDeclaration (functionDeclaration)
	self.FunctionDeclaration = functionDeclaration
	self:SetBlockStatement (self.FunctionDeclaration and self.FunctionDeclaration:GetBody ())
end

-- Type Parameters
function self:CreateTypeCurriedDefinition (typeArgumentList)
	if not self:HasUnboundLocalTypeParameters () then return self end
	
	if self.TypeArgumentList:GetArgumentCount () ~= 0 then
		-- This is not the root type parametric MethodDefinition
		-- Append the given TypeArgumentList to our TypeArgumentList
		-- and ask the root type parametric MethodDefinition to
		-- create the type curried MethodDefinition for us
		local fullTypeArgumentList = self.TypeArgumentList:Clone ()
		for i = 1, typeArgumentList:GetArgumentCount () do
			fullTypeArgumentList:AddArgument (typeArgumentList:GetArgument (i))
		end
		fullTypeArgumentList:Truncate (self.TypeParameterList:GetParameterCount ())
		
		return self:GetTypeParametricMethodDefinition ():CreateTypeCurriedDefinition (fullTypeArgumentList)
	end
	
	-- Check for it in the cache of type curried definitions
	local typeArgumentListId = typeArgumentList:ToString ()
	if self.TypeCurriedDefinitions [typeArgumentListId] and
	   self.TypeCurriedDefinitions [typeArgumentListId]:GetTypeArgumentList ():Equals (typeArgumentList) then
		return self.TypeCurriedDefinitions [typeArgumentListId]
	end
	
	local typeCurriedDefinition = GCompute.TypeCurriedMethodDefinition (self:GetName (), self:GetParameterList (), self:GetTypeParameterList ())
	self.TypeCurriedDefinitions [typeArgumentListId] = typeCurriedDefinition
	self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (typeCurriedDefinition)
	typeCurriedDefinition:SetTypeArgumentList (typeArgumentList)
	typeCurriedDefinition:SetTypeParametricMethodDefinition (self)
	typeCurriedDefinition:InitializeTypeCurriedMethodDefinition ()
	
	return typeCurriedDefinition
end

--- Gets the type argument list of this function
-- @return The type argument list of this function
function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:GetTypeCurryerFunction ()
	return self.TypeCurryerFunction
end

--- Gets the type parameter list of this function
-- @return The type parameter list of this function
function self:GetTypeParameterList ()
	return self.TypeParameterList
end

function self:GetTypeParametricMethodDefinition ()
	return self.TypeParametricMethodDefinition
end

--- Gets the number of unbound local type parameters of this MethodDefinition
-- @return The number of unbound local type parameters of this MethodDefinition
function self:GetUnboundLocalTypeParameterCount ()
	if self.TypeParameterList:IsEmpty () then return 0 end
	if self.TypeParameterList:GetParameterCount () <= self.TypeArgumentList:GetArgumentCount () then return 0 end
	return self.TypeParameterList:GetParameterCount () - self.TypeArgumentList:GetArgumentCount ()
end

--- Returns true if this MethodDefinition has unbound local type parameters
-- @return A boolean indicating whether this MethodDefinition has unbound local type parameters
function self:HasUnboundLocalTypeParameters ()
	if self.TypeParameterList:IsEmpty () then return false end
	return self.TypeParameterList:GetParameterCount () > self.TypeArgumentList:GetArgumentCount ()
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
end

function self:SetTypeCurryerFunction (typeCurryerFunction)
	self.TypeCurryerFunction = typeCurryerFunction
end

function self:SetTypeParametricMethodDefinition (typeParametricMethodDefinition)
	self.TypeParametricMethodDefinition = typeParametricMethodDefinition
end

-- Runtime
function self:GetMergedLocalScope ()
	return self.MergedLocalScope
end

function self:SetMergedLocalScope (mergedLocalScope)
	self.MergedLocalScope = mergedLocalScope
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Definitions", self)
	self.Namespace:ComputeMemoryUsage (memoryUsageReport)
	
	if self.MergedLocalScope then
		self.MergedLocalScope:ComputeMemoryUsage (memoryUsageReport)
	end
	
	for _, typeCurriedDefinition in pairs (self.TypeCurriedDefinitions) do
		typeCurriedDefinition:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:CreateRuntimeObject ()
	return self
end

function self:GetCorrespondingDefinition (globalNamespace)
	if not self:GetDeclaringObject () then return nil end
	
	local declaringObject = self:GetDeclaringObject ():GetCorrespondingDefinition (globalNamespace)
	local memberDefinition = declaringObject:GetNamespace ():GetMember (self:GetName ())
	if memberDefinition:IsOverloadedMethod () then
		local typeParameterCount = self:GetTypeParameterList ():GetParameterCount ()
		for method in memberDefinition:GetEnumerator () do
			if method:GetTypeParameterList ():GetParameterCount () == typeParameterCount and
			   method:GetParameterList ():Equals (self:GetParameterList ()) then
				return method
			end
		end
		GCompute.Error ("MethodDefinition:GetCorrespondingDefinition : Corresponding ClassDefinition not found.")
		return nil
	elseif memberDefinition:IsMethod () then
		return memberDefinition
	else
		GCompute.Error ("MethodDefinition:GetCorrespondingDefinition : Corresponding ObjectDefinition is not a ClassDefinition.")
		return nil
	end
end

function self:GetDisplayText ()
	return self:GetReturnType ():GetRelativeName (self) .. " " .. self:GetShortName () .. " " .. self:GetParameterList ():GetRelativeName (self)
end

--- Gets the type of this function
-- @return A FunctionType representing the type of this function
function self:GetType ()
	if self:IsMemberFunction () and not self:IsMemberStatic () then
		local parameterList = GCompute.ParameterList ()
		parameterList:AddParameter (self:GetDeclaringType (), "this")
		parameterList:AddParameters (self:GetParameterList ())
		return GCompute.FunctionType (self:GetReturnType (), parameterList)
	else
		return GCompute.FunctionType (self:GetReturnType (), self:GetParameterList ())
	end
end

function self:IsMethod ()
	return true
end

--- Resolves the return type and paremeter types of this function
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	self:BuildNamespace ()
	
	local returnType = self:GetReturnType ()
	if returnType and returnType:IsDeferredObjectResolution () then
		returnType:Resolve ()
		if returnType:IsFailedResolution () then
			returnType:GetAST ():GetMessages ():PipeToErrorReporter (errorReporter)
			self:SetReturnType (GCompute.ErrorType ())
		else
			self:SetReturnType (returnType:GetObject ())
		end
	end
	self:GetParameterList ():ResolveTypes (globalNamespace, self, errorReporter)
	self:GetNamespace ():ResolveTypes (globalNamespace, errorReporter)
	
	for _, typeCurriedDefinition in pairs (self.TypeCurriedDefinitions) do
		typeCurriedDefinition:ResolveTypes (globalNamespace, errorReporter)
	end
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local methodDefinition = self.ReturnType and self.ReturnType:GetRelativeName (self) or "[Unknown Type]"
	if self:IsMemberFunction () and not self:IsMemberStatic () then
		methodDefinition = methodDefinition .. " " .. self:GetDeclaringObject ():GetRelativeName (self) .. ":" .. self:GetName ()
	else
		methodDefinition = methodDefinition .. " " .. self:GetName ()
	end
	if not self:GetTypeParameterList ():IsEmpty () then
		if self:GetTypeArgumentList ():IsEmpty () then
			methodDefinition = methodDefinition .. " " .. self:GetTypeParameterList ():ToString ()
		else
			methodDefinition = methodDefinition .. " " .. self:GetTypeArgumentList ():GetRelativeName (self)
		end
	end
	methodDefinition = methodDefinition .. " " .. self:GetParameterList ():GetRelativeName (self)
	return methodDefinition
end

-- Internal, do not call
function self:BuildNamespace ()
	if self.NamespaceValid then return end
	self.NamespaceValid = true
	
	self.Namespace:Clear ()
	
	for i = 1, self:GetParameterList ():GetParameterCount () do
		self.Namespace:AddVariable (self:GetParameterList ():GetParameterName (i) or ("<anonymous-" .. i .. ">"))
			:SetType (self:GetParameterList ():GetParameterType (i))
	end
	for i = 1, self:GetTypeParameterList ():GetParameterCount () do
		local argument = self:GetTypeArgumentList () and self:GetTypeArgumentList ():GetArgument (i) or nil
		if argument then
			self.Namespace:AddAlias (self:GetTypeParameterList ():GetParameterName (i), argument)
		else
			self.Namespace:AddTypeParameter (self:GetTypeParameterList ():GetParameterName (i))
				:SetTypeParameterPosition (i)
		end
	end
end

function self:InvalidateNamespace ()
	self.NamespaceValid = false
end