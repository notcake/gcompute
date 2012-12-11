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

GCompute.EmptyTypeArgumentList = GCompute.TypeArgumentList ()