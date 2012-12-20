local self = {}
self.__Type = "ParameterList"
GCompute.AST.ParameterList = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.ParameterCount = 0
	self.ParameterTypes = {}
	self.ParameterNames = {}
end

function self:AddParameter (parameterType, parameterName)
	self.ParameterCount = self.ParameterCount + 1
	self:SetParameterType (self.ParameterCount, parameterType)
	self.ParameterNames [self.ParameterCount] = parameterName
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	for i = 1, self:GetParameterCount () do
		memoryUsageReport:CreditString ("Syntax Trees", self:GetParameterName (i))
		if self:GetParameterType (i) then
			self:GetParameterType (i):ComputeMemoryUsage (memoryUsageReport, "Syntax Trees")
		end
	end
	
	return memoryUsageReport
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		while not self.ParameterTypes [i] do
			if i >= self.ParameterCount then break end
			i = i + 1
		end
		return self.ParameterTypes [i]
	end
end

--- Returns an iterator function for this parameter list
-- @return An iterator function for this parameter list
function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.ParameterTypes [i], self.ParameterNames [i]
	end
end

function self:GetParameterCount ()
	return self.ParameterCount
end

function self:GetParameterName (parameterId)
	return self.ParameterNames [parameterId]
end

function self:GetParameterType (parameterId)
	return self.ParameterTypes [parameterId]
end

function self:IsEmpty ()
	return self.ParameterCount == 0
end

function self:SetParameterName (parameterId, parameterName)
	self.ParameterNames [parameterId] = parameterName
end

function self:SetParameterType (parameterId, parameterType)
	self.ParameterTypes [parameterId] = parameterType
	if parameterType then parameterType:SetParent (self) end
end

-- Converts this AST.ParameterList to a ParameterList.
function self:ToParameterList ()
	local parameterList = GCompute.ParameterList ()
	for parameterType, parameterName in self:GetEnumerator () do
		-- resolvedObject should always be a Type or ClassDefinition (which is a Type) or OverloadedClassDefinition here.
		local resolvedObject = parameterType and parameterType.ResolutionResults:GetFilteredResultObject (1)
		if resolvedObject and resolvedObject:UnwrapAlias ():IsOverloadedClass () then
			resolvedObject = resolvedObject:GetType (1):UnwrapAlias ()
		end
		parameterList:AddParameter (resolvedObject or parameterType, parameterName)
	end
	return parameterList
end

function self:ToString ()
	local parameterList = ""
	for i = 1, self.ParameterCount do
		if parameterList ~= "" then
			parameterList = parameterList .. ", "
		end
		local parameterType = self.ParameterTypes [i]
		local parameterName = self.ParameterNames [i]
		parameterType = parameterType and parameterType:ToString () or "[Unknown Type]"
		parameterList = parameterList .. parameterType
		if parameterName then
			parameterList = parameterList .. " " .. parameterName
		end
	end
	return "(" .. parameterList .. ")"
end

function self:Visit (astVisitor, ...)
	for i = 1, self:GetParameterCount () do
		local parameterType = self:GetParameterType (i)
		if parameterType then
			self:SetParameterType (i, parameterType:Visit (astVisitor, ...) or parameterType)
		end
	end
	
	local astOverride = astVisitor:VisitParameterList (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
end