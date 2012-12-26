local self = {}
GCompute.EmptyTypeParameterList = GCompute.MakeConstructor (self, GCompute.TypeParameterList)

function self:ctor ()
end

function self:AddParameter (name)
	GCompute.Error ("EmptyTypeParameterList:AddParameter : This function should not be called.")
end

function self:SetParameterDocumentation (parameterId, documentation)
	GCompute.Error ("EmptyTypeParameterList:SetParameterDocumentation : This function should not be called.")
end

function self:SetParameterName (parameterId, parameterName)
	GCompute.Error ("EmptyTypeParameterList:SetParameterName : This function should not be called.")
end

GCompute.EmptyTypeParameterList = GCompute.EmptyTypeParameterList ()