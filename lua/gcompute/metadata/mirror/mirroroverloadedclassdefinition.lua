local self = {}
GCompute.MirrorOverloadedClassDefinition = GCompute.MakeConstructor (self, GCompute.OverloadedClassDefinition)

--- @param name The name of this class
function self:ctor (name)
	self.SourceOverloadedClasses = {}
end

--- Adds a source overloaded class from which types will be obtained
-- @param overloadedClassDefinition Source overloaded class definition from which classes will be obtained
function self:AddSourceOverloadedClass (overloadedClassDefinition)
	if not overloadedClassDefinition:IsOverloadedClass () then return end

	self.SourceOverloadedClasses [#self.SourceOverloadedClasses + 1] = overloadedClassDefinition
	
	for class in overloadedClassDefinition:GetEnumerator () do
		local typeParameterCount = class:GetTypeParameterList ():GetParameterCount ()
		
		local mirrorClass = nil
		
		-- Look for an existing class with the same number of type parameters
		for existingClass in self:GetEnumerator () do
			if existingClass:GetTypeParameterList ():GetParameterCount () == typeParameterCount then
				mirrorClass = existingClass
			end
		end
		
		-- Create a new class definition if an existing one cannot be found
		if not mirrorClass then
			mirrorClass = GCompute.MirrorClassDefinition (self:GetName (), class:GetTypeParameterList ())
			self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (mirrorClass)
			mirrorClass:SetDeclaringNamespace (self:GetDeclaringNamespace ())
			self.Classes [#self.Classes + 1] = mirrorClass
		end
		
		mirrorClass:AddSourceClass (class)
	end
end