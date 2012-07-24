local self = {}
Pass = GCompute.MakeConstructor (self)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
end

function self:Process (blockStatement, callback)
	local namespace = blockStatement:GetNamespace () or GCompute.NamespaceDefinition ()
	blockStatement:SetNamespace (namespace)

	for _, variableEntry in ipairs (self.CompilationUnit:GetExtraData ("inputs") or {}) do
		if variableEntry.Type then
			variableEntry.Type:SetLocalNamespace (namespace)
		end
		namespace:AddMemberVariable (variableEntry.Name, variableEntry.Type or GCompute.InferredType ())
	end
	for _, variableEntry in ipairs (self.CompilationUnit:GetExtraData ("outputs") or {}) do
		if variableEntry.Type then
			variableEntry.Type:SetLocalNamespace (namespace)
		end
		namespace:AddMemberVariable (variableEntry.Name, variableEntry.Type or GCompute.InferredType ())
	end
	for _, variableEntry in ipairs (self.CompilationUnit:GetExtraData ("persist") or {}) do
		if variableEntry.Type then
			variableEntry.Type:SetLocalNamespace (namespace)
		end
		namespace:AddMemberVariable (variableEntry.Name, variableEntry.Type or GCompute.InferredType ())
	end
	callback ()
end