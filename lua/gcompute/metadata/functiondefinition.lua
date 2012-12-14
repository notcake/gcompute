local self = {}
GCompute.FunctionDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this function
-- @param parameterList A ParameterList describing the parameters the function takes or nil if the function takes no parameters
-- @param typeParameterList A TypeParameterList describing the type parameters the function takes or nil if the function is non-type-parametric
function self:ctor (name, parameterList, typeParameterList)
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	self.TypeArgumentList = GCompute.EmptyTypeArgumentList
	
	self.ParameterList = parameterList or GCompute.EmptyParameterList
	self.ReturnType = GCompute.DeferredObjectResolution ("void", GCompute.ResolutionObjectType.Type)
	
	if #self.ParameterList > 0 then
		self.ParameterList = GCompute.ParameterList (self.ParameterList)
	end
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	
	self.FunctionDeclaration = nil
	
	self.ParameterNamespace = GCompute.NamespaceDefinition (self:GetName ())
	self.ParameterNamespace:SetNamespaceType (GCompute.NamespaceType.FunctionRoot)
	self.ParameterNamespaceValid = false
	
	self.NativeString = nil
	self.NativeFunction = nil
	
	-- Type parameters
	self.TypeParametricFunctionDefinition = self
	self.TypeCurriedDefinitions = GCompute.WeakValueTable ()
	self.TypeCurryerFunction = GCompute.NullCallback
end

function self:BuildParameterNamespace ()
	if self.ParameterNamespaceValid then return end
	self.ParameterNamespaceValid = true
	
	self.ParameterNamespace:Clear ()
	self.ParameterNamespace:SetContainingNamespace (self:GetContainingNamespace ())
	self.ParameterNamespace:SetContainingFunction (self)
	
	for parameterType, parameterName, isVarArgs in self:GetParameterList ():GetEnumerator () do
		self.ParameterNamespace:AddMemberVariable (parameterName)
			:SetType (parameterType)
	end
	for i = 1, self:GetTypeParameterList ():GetParameterCount () do
		local argument = self:GetTypeArgumentList () and self:GetTypeArgumentList ():GetArgument (i) or nil
		if argument then
			self.ParameterNamespace:AddAlias (self:GetTypeParameterList ():GetParameterName (i), argument)
		else
			self.ParameterNamespace:AddTypeParameter (self:GetTypeParameterList ():GetParameterName (i))
				:SetDeclaringFunction (self)
				:SetTypeParameterPosition (i)
		end
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Definitions", self)
	self.ParameterNamespace:ComputeMemoryUsage (memoryUsageReport)
	
	return memoryUsageReport
end

function self:CreateRuntimeObject ()
	return self
end

function self:CreateTypeCurriedDefinition (typeArgumentList)
	if not self:HasUnboundLocalTypeParameters () then return self end
	
	if self.TypeArgumentList:GetArgumentCount () ~= 0 then
		-- This is not the root type parametric FunctionDefinition
		-- Append the given TypeArgumentList to our TypeArgumentList
		-- and ask the root type parametric FunctionDefinition to
		-- create the type curried FunctionDefinition for us
		local fullTypeArgumentList = self.TypeArgumentList:Clone ()
		for i = 1, typeArgumentList:GetArgumentCount () do
			fullTypeArgumentList:AddArgument (typeArgumentList:GetArgument (i))
		end
		fullTypeArgumentList:Truncate (self.TypeParameterList:GetParameterCount ())
		
		return self:GetTypeParametricFunctionDefinition ():CreateTypeCurriedDefinition (fullTypeArgumentList)
	end
	
	-- Check for it in the cache of type curried definitions
	local typeArgumentListId = typeArgumentList:ToString ()
	if self.TypeCurriedDefinitions [typeArgumentListId] and
	   self.TypeCurriedDefinitions [typeArgumentListId]:GetTypeArgumentList ():Equals (typeArgumentList) then
		return self.TypeCurriedDefinitions [typeArgumentListId]
	end
	
	local typeCurriedFunctionDefinition = GCompute.TypeCurriedFunctionDefinition (self:GetName (), self:GetParameterList (), self:GetTypeParameterList ())
	self.TypeCurriedDefinitions [typeArgumentListId] = typeCurriedFunctionDefinition
	typeCurriedFunctionDefinition:SetTypeArgumentList (typeArgumentList)
	typeCurriedFunctionDefinition:SetTypeParametricFunctionDefinition (self)
	typeCurriedFunctionDefinition:InitializeTypeCurriedFunctionDefinition ()
	return typeCurriedFunctionDefinition
end

--- Gets the FunctionDeclaration syntax tree node corresponding to this function
-- @return The FunctionDeclaration corresponding to this function
function self:GetFunctionDeclaration ()
	return self.FunctionDeclaration
end

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

function self:GetParameterNamespace ()
	return self.ParameterNamespace
end

--- Gets the return type of this function as a DeferredObjectResolution or Type
-- @return A DeferredObjectResolution or Type representing the return type of this function
function self:GetReturnType ()
	return self.ReturnType
end

--- Gets the short name of this function
-- @return The short name of this function
function self:GetShortName ()
	if self:GetTypeParameterList ():IsEmpty () then
		return self:GetName () or "[Unnamed]"
	else
		return (self:GetName () or "[Unnamed]") .. " " .. self:GetTypeParameterList ():ToString ()
	end
end

--- Gets the type of this function
-- @return A FunctionType representing the type of this function
function self:GetType ()
	if self:IsMemberFunction () then
		local parameterList = GCompute.ParameterList ()
		parameterList:AddParameter (self:GetContainingNamespace (), "self")
		parameterList:AddParameters (self:GetParameterList ())
		return GCompute.FunctionType (self:GetReturnType (), parameterList)
	else
		return GCompute.FunctionType (self:GetReturnType (), self:GetParameterList ())
	end
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

function self:GetTypeParametricFunctionDefinition ()
	return self.TypeParametricFunctionDefinition
end

--- Gets the number of unbound local type parameters of this FunctionDefinition
-- @return The number of unbound local type parameters of this FunctionDefinition
function self:GetUnboundLocalTypeParameterCount ()
	if self.TypeParameterList:IsEmpty () then return 0 end
	if self.TypeParameterList:GetParameterCount () <= self.TypeArgumentList:GetArgumentCount () then return 0 end
	return self.TypeParameterList:GetParameterCount () - self.TypeArgumentList:GetArgumentCount ()
end

--- Returns true if this FunctionDefinition has unbound local type parameters
-- @return A boolean indicating whether this FunctionDefinition has unbound local type parameters
function self:HasUnboundLocalTypeParameters ()
	if self.TypeParameterList:IsEmpty () then return false end
	return self.TypeParameterList:GetParameterCount () > self.TypeArgumentList:GetArgumentCount ()
end

function self:InvalidateParameterNamespace ()
	self.ParameterNamespaceValid = false
end

function self:IsFunction ()
	return true
end

--- Gets whether this function is a member function
-- @return A boolean indicating whether this function is a member function
function self:IsMemberFunction ()
	if not self:GetContainingNamespace () then return false end
	if self:IsMemberStatic () then return false end
	return self:GetContainingNamespace ():IsType ()
end

--- Resolves the return type and paremeter types of this function
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	self:BuildParameterNamespace ()
	
	local returnType = self:GetReturnType ()
	if returnType and returnType:IsDeferredObjectResolution () then
		returnType:Resolve ()
		if returnType:IsFailedResolution () then
			returnType:GetAST ():GetMessages ():PipeToErrorReporter (errorReporter)
		else
			self:SetReturnType (returnType:GetObject ())
		end
	end
	self:GetParameterList ():ResolveTypes (globalNamespace, self:GetParameterNamespace (), errorReporter)
	self:GetParameterNamespace ():ResolveTypes (globalNamespace, errorReporter)
end

--- Sets the FunctionDeclaration syntax tree node corresponding to this function
-- @param functionDeclaration The FunctionDeclaration corresponding to this function
function self:SetFunctionDeclaration (functionDeclaration)
	self.FunctionDeclaration = functionDeclaration
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
	if returnType == nil then
		self.ReturnType = nil
	elseif type (returnType) == "string" then
		self.ReturnType = GCompute.DeferredObjectResolution (returnType, GCompute.ResolutionObjectType.Type, nil, self:GetParameterNamespace ())
	elseif returnType:IsDeferredObjectResolution () then
		self.ReturnType = returnType
		self.ReturnType:SetLocalNamespace (self.ReturnType:GetLocalNamespace () or self:GetParameterNamespace ())
	elseif returnType:UnwrapAlias ():IsType () then
		self.ReturnType = returnType
	else
		GCompute.Error ("FunctionDefinition:SetReturnType : returnType was not a string, DeferredObjectResolution or Type (" .. returnType:ToString () .. ")")
	end
	return self
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
end

function self:SetTypeCurryerFunction (typeCurryerFunction)
	self.TypeCurryerFunction = typeCurryerFunction
end

function self:SetTypeParametricFunctionDefinition (typeParametricFunctionDefinition)
	self.TypeParametricFunctionDefinition = typeParametricFunctionDefinition
end

--- Returns a string representation of this function
-- @return A string representation of this function
function self:ToString ()
	local functionDefinition = self.ReturnType and self.ReturnType:GetFullName () or "[Unknown Type]"
	if self:IsMemberFunction () then
		functionDefinition = functionDefinition .. " " .. self:GetContainingNamespace ():GetFullName () .. ":" .. self:GetName ()
	else
		functionDefinition = functionDefinition .. " " .. self:GetName ()
	end
	if not self:GetTypeParameterList ():IsEmpty () then
		functionDefinition = functionDefinition .. " " .. self:GetTypeParameterList ():ToString ()
	end
	functionDefinition = functionDefinition .. " " .. self:GetParameterList ():ToString ()
	return functionDefinition
end