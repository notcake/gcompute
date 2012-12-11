local self = {}
GCompute.TypeArgumentListList = GCompute.MakeConstructor (self)

function self:ctor ()
	self.ArgumentListCount = 0
	self.ArgumentLists = {}
end

function self:AddArgumentList (arguments)
	self.ArgumentListCount = self.ArgumentListCount + 1
	self.ArgumentLists [self.ArgumentListCount] = GCompute.TypeArgumentList (arguments)
end

function self:GetArgument (argumentListId, argumentId)
	return self.ArgumentLists [argumentListId]:GetArgument (argumentId)
end

function self:GetArgumentCount (argumentListId)
	return self.ArgumentLists [argumentListId]:GetArgumentCount ()
end

function self:GetArgumentList (argumentListId)
	return self.ArgumentLists [argumentListId]
end

function self:GetArgumentListCount ()
	return self.ArgumentListCount
end

function self:IsEmpty ()
	return self.ArgumentListCount == 0
end

function self:SetArgument (argumentListId, argumentId, type)
	self.ArgumentLists [argumentListId]:SetArgument (argumentId, type)
end

function self:ToString ()
	local typeArgumentListList = "<\n"
	for i = 1, self:GetArgumentListCount () do
		typeArgumentListList = typeArgumentListList .. "    " .. self.ArgumentLists [i]:ToString () .. "\n"
	end
	typeArgumentListList = typeArgumentListList .. ">"
	return typeArgumentListList
end