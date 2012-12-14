local self = {}
GCompute.EmptyTypeArgumentList = GCompute.MakeConstructor (self, GCompute.TypeArgumentList)

function self:ctor ()
end

function self:AddArgument (type)
	GCompute.Error ("EmptyTypeArgumentList:AddArgument : This function should not be called.")
end

function self:SetArgument (argumentId, type)
	GCompute.Error ("EmptyTypeArgumentList:SetArgument : This function should not be called.")
end

GCompute.EmptyTypeArgumentList = GCompute.EmptyTypeArgumentList ()