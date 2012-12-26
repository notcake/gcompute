local self = {}
GCompute.NamespaceSet = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Namespaces   = {}
	self.NamespaceSet = {}
end

function self:AddNamespace (namespaceDefinition)
	if self.NamespaceSet [namespaceDefinition] then return self end
	
	self.Namespaces [#self.Namespaces + 1] = namespaceDefinition
	self.NamespaceSet [namespaceDefinition] = true
	
	return self
end

function self:ContainsNamespace (namespaceDefinition)
	return self.NamespaceSet [namespaceDefinition] or false
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Namespaces [i]
	end
end

function self:GetNamespace (index)
	return self.Namespaces [index]
end

function self:GetNamespaceCount ()
	return #self.Namespaces
end

function self:GetTranslatedEnumerator (referenceDefinition)
	if not referenceDefinition then
		-- This means the root namespace
		return self:GetEnumerator ()
	end
	
	local i = 0
	return function ()
		local translated = nil
		
		repeat
			i = i + 1
			translated = referenceDefinition:GetCorrespondingDefinition (self.Namespaces [i])
		until translated or not self.Namespaces [i]
		
		if not self.Namespaces [i] then return nil end
		
		return translated
	end
end

function self:RemoveNamespace (namespaceDefinition)
	if not self.NamespaceSet [namespaceDefinition] then return end
	
	for k, v in ipairs (self.Namespaces) do
		if v == namespaceDefinition then
			table.remove (self.Namespaces, k)
			break
		end
	end
	
	self.NamespaceSet [namespaceDefinition] = nil
end

function self:ToString ()
	local namespaceSet = "[Namespace Set (" .. #self.Namespaces .. ")]"
	for namespace in self:GetEnumerator () do
		namespaceSet = namespaceSet .. "\n\t" .. namespace:GetFullName () .. " (" .. namespace:GetModule ():GetFullName () .. ", " .. namespace:GetModule ():GetOwnerId () .. ")"
	end
	return namespaceSet
end