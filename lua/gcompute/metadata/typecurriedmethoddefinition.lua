local self = {}
GCompute.TypeCurriedMethodDefinition = GCompute.MakeConstructor (self, GCompute.MethodDefinition)

function self:ctor ()
end

function self:InitializeTypeCurriedMethodDefinition ()
	local typeParametricMethodDefinition = self:GetTypeParametricMethodDefinition ()
	
	local substitutionMap = GCompute.SubstitutionMap ()
	for i = 1, self.TypeArgumentList:GetArgumentCount () do
		local parameterName = self.TypeParameterList:GetParameterName (i)
		local typeParameter = typeParametricMethodDefinition:GetNamespace ():GetMember (parameterName):ToType ()
		substitutionMap:Add (typeParameter, self.TypeArgumentList:GetArgument (i))
	end
	
	self.ParameterList = typeParametricMethodDefinition:GetParameterList ():SubstituteTypeParameters (substitutionMap)
	
	self.ReturnType = typeParametricMethodDefinition:GetReturnType ()
	self.ReturnType = self.ReturnType:SubstituteTypeParameters (substitutionMap) or self.ReturnType
	
	self:SetNativeString (typeParametricMethodDefinition:GetNativeString ())
	self:SetNativeFunction (typeParametricMethodDefinition:GetNativeFunction ())
	self:SetTypeCurryerFunction (typeParametricMethodDefinition:GetTypeCurryerFunction ())
	if self:GetTypeCurryerFunction () then
		self:GetTypeCurryerFunction () (self, self:GetTypeArgumentList ())
	end
	
	self:BuildNamespace ()
end