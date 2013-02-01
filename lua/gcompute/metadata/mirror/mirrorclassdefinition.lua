local self = {}
GCompute.MirrorClassDefinition = GCompute.MakeConstructor (self, GCompute.ClassDefinition)

function self:ctor (name, typeParameterList)
	self.Namespace = GCompute.MirrorNamespace ()
	self.Namespace:SetDefinition (self)
	-- Namespace hierarchy data will get set later automatically
	
	-- Update our ClassType's Namespace.
	self:GetClassType ():SetNamespace (self.Namespace)
	
	self.SourceClasses = {}
end

function self:AddSourceClass (classDefinition)
	if not classDefinition:IsClass () then return end
	
	self.SourceClasses [#self.SourceClasses + 1] = classDefinition
	
	local sourceType = classDefinition:GetClassType ()
	local thisType   = self:GetClassType ()
	
	-- Copy type properties
	if not sourceType:IsNullable          () then thisType:SetNullable          (false) end
	if     sourceType:IsNativelyAllocated () then thisType:SetNativelyAllocated (true ) end
	if     sourceType:IsPrimitive         () then thisType:SetPrimitive         (true ) end
	
	self.DefaultValueCreator = self.DefaultValueCreator or classDefinition:GetDefaultValueCreator ()
	
	-- Copy base types
	for baseType in sourceType:GetBaseTypeEnumerator () do
		if not baseType:IsTop () then
			local correspondingType = baseType:GetCorrespondingDefinition (self:GetGlobalNamespace ())
			thisType:AddBaseType (correspondingType)
		end
	end
	
	self.Namespace:AddSourceNamespace (classDefinition:GetNamespace ())
	
	-- We need to force creation of mirros of all methods so that
	-- function tables get built correctly later
	for name, member in classDefinition:GetNamespace ():GetEnumerator () do
		if member:IsOverloadedMethod () or member:IsMethod () then
			self.Namespace:GetMember (name)
		end
	end
end

function self:IsMirrorClassDefinition ()
	return true
end