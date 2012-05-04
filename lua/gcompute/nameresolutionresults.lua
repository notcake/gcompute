local self = {}
GCompute.NameResolutionResults = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Results = {}
end

function self:AddResult (result)
	if #self.Results > 99 then
		GCompute.Error ("Too many name resolution results!")
		error ("")
		return
	end

	self.Results [#self.Results + 1] = result
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Results [i]
	end
end

function self:GetResult (index)
	return self.Results [index]
end

function self:GetResultCount ()
	return #self.Results
end

function self:ToString ()
	local results = "{"
	
	for i = 1, self:GetResultCount () do
		results = results .. "\n    " .. self:GetResult (i):ToString ()
	end
	
	results = results .. "\n}"
	
	return results
end