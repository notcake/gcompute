local self = {}
GCompute.TypeCurriedFunctionDefinition = GCompute.MakeConstructor (self, GCompute.FunctionDefinition)

function self:ctor ()
end

function self:InitializeTypeCurriedFunctionDefinition ()
	local typeParametricFunctionDefinition = self:GetTypeParametricFunctionDefinition ()
	
	local substitutionMap = GCompute.SubstitutionMap ()
	for i = 1, self.TypeArgumentList:GetArgumentCount () do
		local parameterName = self.TypeParameterList:GetParameterName (i)
		local typeParameter = typeParametricFunctionDefinition:GetParameterNamespace ():GetMember (parameterName)
		substitutionMap:Add (typeParameter, self.TypeArgumentList:GetArgument (i))
	end
	
	self.ParameterList = typeParametricFunctionDefinition:GetParameterList ():SubstituteTypeParameters (substitutionMap)
	
	self.ReturnType = typeParametricFunctionDefinition:GetReturnType ()
	self.ReturnType = self.ReturnType:SubstituteTypeParameters (substitutionMap) or self.ReturnType
	
	self:SetNativeString (typeParametricFunctionDefinition:GetNativeString ())
	self:SetNativeFunction (typeParametricFunctionDefinition:GetNativeFunction ())
	self:SetTypeCurryerFunction (typeParametricFunctionDefinition:GetTypeCurryerFunction ())
	if self:GetTypeCurryerFunction () then
		self:GetTypeCurryerFunction () (self, self:GetTypeArgumentList ())
	end
	
	self:BuildParameterNamespace ()
end