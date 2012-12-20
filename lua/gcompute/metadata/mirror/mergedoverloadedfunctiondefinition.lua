local self = {}
GCompute.MergedOverloadedFunctionDefinition = GCompute.MakeConstructor (self, GCompute.OverloadedFunctionDefinition)

--- @param name The name of this function
function self:ctor (name)
	self.SourceOverloadedFunctions = {}
end

--- Adds a source overloaded function from which functions will be obtained
-- @param overloadedFunctionDefinition Source overloaded function definition from which functions will be obtained
function self:AddSourceOverloadedFunction (overloadedFunctionDefinition)
	self.SourceOverloadedFunctions [#self.SourceOverloadedFunctions + 1] = overloadedFunctionDefinition
	
	for i = 1, overloadedFunctionDefinition:GetFunctionCount () do
		self.Functions [#self.Functions + 1] = overloadedFunctionDefinition:GetFunction (i)
	end
end