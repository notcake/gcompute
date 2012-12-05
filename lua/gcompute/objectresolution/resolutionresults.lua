local self = {}
GCompute.ResolutionResults = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Results         = {}
	self.FilteredResults = {}
end

function self:AddResult (resolutionResult)
	if #self.Results >= 100 then
		GCompute.Error ("Too many resolution results!")
		return
	end
	self.Results [#self.Results + 1] = resolutionResult
	self.FilteredResults [#self.FilteredResults + 1] = resolutionResult
end

function self:Clear ()
	self.Results         = {}
	self.FilteredResults = {}
end

function self:ClearFilter ()
	self.FilteredResults = {}
	for i = 1, #self.Results do
		self.FilteredResults [i] = self.Results [i]
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Resolution Results", self)
	memoryUsageReport:CreditTableStructure ("Resolution Results", self.Results)
	return memoryUsageReport
end

function self:GetFilteredResultCount ()
	return #self.FilteredResults
end

function self:GetResultCount ()
	return #self.Results
end

function self:ToString ()
	local results = "[Resolution Results]\n{"
	for i = 1, #self.Results do
		results = results .. "\n    " .. self.Results [i]:ToString ():gsub ("\n", "\n    ")
	end
	results = results .. "\n}"
	
	return results
end