local self = {}
GCompute.NameResolutionResults = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LocalResults = {}
	self.GlobalResults = {}
	self.MemberResults = {}
end

function self:AddGlobalResult (objectDefinition, objectMetadata)
	if #self.GlobalResults >= 100 then
		GCompute.Error ("Too many global name resolution results!")
		exit ()
		return
	end
	self.GlobalResults [#self.GlobalResults + 1] =
	{
		Result = objectDefinition,
		Metadata = objectMetadata
	}
end

function self:AddLocalResult (objectDefinition, objectMetadata)
	if #self.LocalResults >= 100 then
		GCompute.Error ("Too many local name resolution results!")
		exit ()
		return
	end
	self.LocalResults [#self.LocalResults + 1] =
	{
		Result = objectDefinition,
		Metadata = objectMetadata
	}
end

function self:AddMemberResult (objectDefinition, objectMetadata)
	if #self.MemberResults >= 100 then
		GCompute.Error ("Too many member name resolution results!")
		exit ()
		return
	end
	self.MemberResults [#self.MemberResults + 1] =
	{
		Result = objectDefinition,
		Metadata = objectMetadata
	}
end

function self:ClearLocalResults ()
	self.LocalResults = {}
end

function self:ClearGlobalResults ()
	self.GlobalResults = {}
end

function self:ClearMemberResults ()
	self.MemberResults = {}
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Name Resolution Results", self)
	memoryUsageReport:CreditTableStructure ("Name Resolution Results", self.LocalResults)
	memoryUsageReport:CreditTableStructure ("Name Resolution Results", self.GlobalResults)
	memoryUsageReport:CreditTableStructure ("Name Resolution Results", self.MemberResults)
	return memoryUsageReport
end

function self:FilterLocalResults ()
	for i = #self.LocalResults, 2, -1 do
		self.LocalResults [i] = nil
	end
end

function self:GetGlobalResult (index)
	return self.GlobalResults [index]
end

function self:GetGlobalResultCount ()
	return #self.GlobalResults
end

function self:GetLocalResult (index)
	return self.LocalResults [index]
end

function self:GetLocalResultCount ()
	return #self.LocalResults
end

function self:GetMemberResult (index)
	return self.MemberResults [index]
end

function self:GetMemberResultCount ()
	return #self.MemberResults
end

function self:GetResult (index)
	if index <= self:GetGlobalResultCount () then
		return self:GetGlobalResult (index)
	elseif index <= self:GetGlobalResultCount () + self:GetLocalResultCount () then
		return self:GetLocalResult (index - self:GetGlobalResultCount ())
	else
		return self:GetMemberResult (index - self:GetGlobalResultCount () - self:GetLocalResultCount ())
	end
end

function self:GetResultCount ()
	return self:GetGlobalResultCount () + self:GetLocalResultCount () + self:GetMemberResultCount ()
end

function self:ToString ()
	local results = "[Name Resolution Results]\n{"
	
	for i = 1, self:GetLocalResultCount () do
		results = results .. "\n    [Local] " .. self:GetLocalResult (i).Result:ToString ():gsub ("\n", "\n    ")
	end
	for i = 1, self:GetMemberResultCount () do
		results = results .. "\n    [Member] " .. self:GetMemberResult (i).Result:ToString ():gsub ("\n", "\n    ")
	end
	for i = 1, self:GetGlobalResultCount () do
		results = results .. "\n    [Global] " .. self:GetGlobalResult (i).Result:ToString ():gsub ("\n", "\n    ")
	end
	
	results = results .. "\n}"
	
	return results
end