local self = {}
GCompute.MergedOverloadedClassDefinition = GCompute.MakeConstructor (self, GCompute.OverloadedClassDefinition)

--- @param name The name of this type
function self:ctor (name)
	self.SourceOverloadedTypes = {}
end

--- Adds a source overloaded type from which types will be obtained
-- @param overloadedClassDefinition Source overloaded type definition from which types will be obtained
function self:AddSourceOverloadedType (overloadedClassDefinition)
	if not overloadedClassDefinition:IsOverloadedClass () then return end

	self.SourceOverloadedTypes [#self.SourceOverloadedTypes + 1] = overloadedClassDefinition
	
	for i = 1, overloadedClassDefinition:GetTypeCount () do
		local typeDefinition = overloadedClassDefinition:GetType (i)
		local typeParameterCount = typeDefinition:GetTypeParameterList ():GetParameterCount ()
		
		local mergedClassDefinition = nil
		for _, existingClassDefinition in ipairs (self.Types) do
			if existingClassDefinition:GetTypeParameterList ():GetParameterCount () == typeParameterCount then
				mergedClassDefinition = existingClassDefinition
			end
		end
		if not mergedClassDefinition then
			mergedClassDefinition = GCompute.MergedClassDefinition (self:GetName (), typeDefinition:GetTypeParameterList ())
			mergedClassDefinition:SetDeclaringNamespace (self:GetDeclaringNamespace ())
			self.Types [#self.Types + 1] = mergedClassDefinition
		end
		
		mergedClassDefinition:AddSourceType (typeDefinition)
	end
end