local self = {}
GCompute.TypeCurriedClassDefinition = GCompute.MakeConstructor (self, GCompute.ClassDefinition)

function self:ctor (name, typeParameterList)
end

function self:InitializeTypeCurriedDefinition ()
	local typeParametricDefinition = self:GetTypeParametricDefinition ()
	
	local substitutionMap = GCompute.SubstitutionMap ()
	for i = 1, self.TypeArgumentList:GetArgumentCount () do
		local parameterName = self.TypeParameterList:GetParameterName (i)
		local typeParameter = typeParametricDefinition:GetNamespace ():GetMember (parameterName):ToType ()
		substitutionMap:Add (typeParameter, self.TypeArgumentList:GetArgument (i))
	end
	
	self:SetTypeCurryerFunction (typeParametricDefinition:GetTypeCurryerFunction ())
	if self:GetTypeCurryerFunction () then
		self:GetTypeCurryerFunction () (self, self:GetTypeArgumentList ())
	end
	
	-- TODO: Build base types
	-- TODO: Build namespace
end