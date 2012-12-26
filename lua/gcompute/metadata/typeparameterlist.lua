local self = {}
GCompute.TypeParameterList = GCompute.MakeConstructor (self)

function GCompute.ToTypeParameterList (typeParameterList)
	typeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	if type (typeParameterList) == "string" then
		local originalTypeParameterList = typeParameterList
		typeParameterList = GCompute.TypeParser (typeParameterList):TypeParameterList ()
		local messages = typeParameterList:GetMessages ()
		if messages then
			ErrorNoHalt ("In \"" .. originalTypeParameterList .. "\":\n" .. messages:ToString () .. "\n")
		end
		typeParameterList = typeParameterList:ToTypeParameterList ()
	elseif #typeParameterList > 0 then
		typeParameterList = GCompute.TypeParameterList (typeParameterList)
	end
	return typeParameterList
end

function self:ctor (parameters)
	self.ParameterCount = 0
	self.ParameterNames = {}
	self.ParameterDocumentation = {}
	
	if parameters then
		for _, parameter in ipairs (parameters) do
			self:AddParameter (parameter)
		end
	end
end

--- Adds a parameter to the list
-- @param parameterName The name of the parameter
-- @return The id of the newly added parameter
function self:AddParameter (parameterName)
	self.ParameterCount = self.ParameterCount + 1
	self.ParameterNames [self.ParameterCount] = parameterName
	
	return self.ParameterCount
end

--- Returns whether a TypeParameterList is equal to this one
-- @param typeParameterList The TypeParameterList to be checked for equality to this one
function self:Equals (typeParameterList)
	typeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	
	if self == typeParameterList then return true end
	if self.ParameterCount ~= typeParameterList.ParameterCount then return false end
	
	for i = 1, self.ParameterCount do
		if self.ParameterNames [i] ~= typeParameterList.ParameterNames [i] then
			return false
		end
	end
	return true
end

--- Returns an iterator function for this type parameter list
-- @return An iterator function for this type parameter list
function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.ParameterNames [i]
	end
end

--- Gets the number of parameters in this type parameter list
-- @return The number of parameters in this type parameter list
function self:GetParameterCount ()
	return self.ParameterCount
end

--- Gets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @return The documentation string for the parameter
function self:GetParameterDocumentation (parameterId)
	return self.ParameterDocumentation [parameterId]
end

-- Returns the name of the given parameter
-- @param parameterId The id of the parameter
-- @return The name of the parameter or nil if it is unnamed
function self:GetParameterName (parameterId)
	return self.ParameterNames [parameterId]
end

--- Returns a boolean indicating whether this type parameter list is empty
-- @return A boolean indicating whether this type parameter list is empty
function self:IsEmpty ()
	return self.ParameterCount == 0
end

--- Sets the documentation string for the given parameter
-- @param parameterId The id of the parameter
-- @param documentation The documentation string for the parameter
function self:SetParameterDocumentation (parameterId, documentation)
	self.ParameterDocumentation [parameterId] = documentation
end

-- Sets the name of the given parameter
-- @param parameterId The id of the parameter
-- @param parameterName The new name of the parameter
function self:SetParameterName (parameterId, parameterName)
	self.ParameterNames [parameterId] = parameterName
end

--- Returns a string representation of this type parameter list
-- @return A string representation of this type parameter list
function self:ToString ()
	local typeParameterList = ""
	for i = 1, self:GetParameterCount () do
		if typeParameterList ~= "" then
			typeParameterList = typeParameterList .. ", "
		end
		local parameterName = self:GetParameterName (i) or "[Unnamed]"
		typeParameterList = typeParameterList .. parameterName
	end
	return "<" .. typeParameterList .. ">"
end