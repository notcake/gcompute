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
		local typeDefinition = overloadedTypeDefinition:GetType (i)
		local typeParameterCount = typeDefinition:GetTypeParameterList ():GetParameterCount ()
		
		local mergedTypeDefinition = nil
		for _, existingTypeDefinition in ipairs (self.Types) do
			if existingTypeDefinition:GetTypeParameterList ():GetParameterCount () == typeParameterCount then
				mergedTypeDefinition = existingTypeDefinition
			end
		end
		if not mergedTypeDefinition then
			mergedTypeDefinition = GCompute.MergedTypeDefinition (self:GetName (), typeDefinition:GetTypeParameterList ())
			mergedTypeDefinition:SetContainingNamespace (self:GetContainingNamespace ())
			self.Types [#self.Types + 1] = mergedTypeDefinition
		end
		
		mergedTypeDefinition:AddSourceType (typeDefinition)
	end
end