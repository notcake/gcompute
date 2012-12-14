local self = {}
GCompute.TypeArgumentList = GCompute.MakeConstructor (self)

function self:ctor (arguments)
	self.ArgumentCount = 0
	self.Arguments = {}
	
	if arguments then
		for _, argument in ipairs (arguments) do
			self:AddArgument (argument)
		end
	end
end

function self:AddArgument (type)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = type
end

function self:Clone ()
	local typeArgumentList = GCompute.TypeArgumentList ()
	for i = 1, self.ArgumentCount do
		typeArgumentList:AddArgument (self.Arguments [i])
	end
	return typeArgumentList
end

function self:Equals (otherArgumentList)
	if self:GetArgumentCount () ~= otherArgumentList:GetArgumentCount () then return false end
	for i = 1, self.ArgumentCount do
		if not self.Arguments [i]:UnwrapAlias ():Equals (otherArgumentList:GetArgument (i)) then return false end
	end
	return true
end

function self:GetArgument (argumentId)
	return self.Arguments [argumentId]
end

function self:GetArgumentCount ()
	return self.ArgumentCount
end

function self:IsEmpty ()
	return self.ArgumentCount == 0
end

function self:SetArgument (argumentId, type)
	if argumentId > self.ArgumentCount then self.ArgumentCount = argumentId end
	self.Arguments [argumentId] = type
end

--- Returns a string representation of this type argument list
-- @return A string representation of this type argument list
function self:ToString ()
	local typeArgumentList = ""
	for i = 1, self:GetArgumentCount () do
		if typeArgumentList ~= "" then
			typeArgumentList = typeArgumentList .. ", "
		end
		typeArgumentList = typeArgumentList .. (self:GetArgument (i) and self:GetArgument (i):GetFullName () or "[Nothing]")
	end
	return "<" .. typeArgumentList .. ">"
end

function self:Truncate (argumentCount)
	self.ArgumentCount = argumentCount
	for i = argumentCount + 1, #self.Arguments do
		self.Arguments [i] = nil
	end
end