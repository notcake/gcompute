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

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	for argument in source:GetEnumerator () do
		self:AddArgument (argument)
	end
	
	return self
end

function self:AddArgument (type)
	if type:IsObjectDefinition () then
		GCompute.Error ("TypeArgumentList:AddArgument : type should be a Type, not an ObjectDefinition.")
	end
	
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [self.ArgumentCount] = type
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

function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Arguments)
end

function self:GetFullName ()
	return self:GetName ("GetFullName")
end

function self:GetRelativeName (referenceDefinition)
	return self:GetName ("GetRelativeName", referenceDefinition)
end

function self:IsEmpty ()
	return self.ArgumentCount == 0
end

function self:SetArgument (argumentId, type)
	if type:IsObjectDefinition () then
		GCompute.Error ("TypeArgumentList:SetArgument : type should be a Type, not an ObjectDefinition.")
	end
	
	if argumentId > self.ArgumentCount then self.ArgumentCount = argumentId end
	self.Arguments [argumentId] = type
end

--- Returns a string representation of this type argument list
-- @return A string representation of this type argument list
function self:ToString ()
	return self:GetFullName ()
end

function self:Truncate (argumentCount)
	self.ArgumentCount = argumentCount
	for i = argumentCount + 1, #self.Arguments do
		self.Arguments [i] = nil
	end
end

-- Internal, do not call
function self:GetName (functionName, ...)
	local typeArgumentList = ""
	for i = 1, self:GetArgumentCount () do
		if typeArgumentList ~= "" then
			typeArgumentList = typeArgumentList .. ", "
		end
		local argument = self:GetArgument (i)
		typeArgumentList = typeArgumentList .. (argument and argument [functionName] (argument, ...) or "[Nothing]")
	end
	return "<" .. typeArgumentList .. ">"
end