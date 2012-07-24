local self = {}
GCompute.MergedOverloadedTypeDefinition = GCompute.MakeConstructor (self, GCompute.OverloadedTypeDefinition)

--- @param name The name of this type
function self:ctor (name)
	self.SourceOverloadedTypes = {}
end

--- Adds a source overloaded type from which types will be obtained
-- @param overloadedTypeDefinition Source overloaded type definition from which types will be obtained
function self:AddSourceOverloadedType (overloadedTypeDefinition)
	if not overloadedTypeDefinition:IsOverloadedTypeDefinition () then return end

	self.SourceOverloadedTypes [#self.SourceOverloadedTypes + 1] = overloadedTypeDefinition
	
	for i = 1, overloadedTypeDefinition:GetTypeCount () do
		self.Types [#self.Types + 1] = overloadedTypeDefinition:GetType (i)
	end
end