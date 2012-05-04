local Scope = {}
GCompute.Scope = GCompute.MakeConstructor (Scope)

function Scope:ctor ()
	self.Name = nil

	self.GlobalScope = nil
	self.ParentScope = nil

	self.Members = {}
	self.Metadata = {}
	self.NextAnonymousTypeIndex = 1
	self.VariableCount = 0
	
	self.OptimizedBlock = nil
end

function Scope:AddAnonymousType ()
	local Type = self:AddType ("*AnonymousType" .. tostring (self.NextAnonymousTypeIndex))
	self.NextAnonymousTypeIndex = self.NextAnonymousTypeIndex + 1
	return Type
end

function Scope:AddFunction (name, returnType, ...)
	if not self.Members [name] then
		self.Members [name] = GCompute.FunctionList (name)
		self.Metadata [name] = {
			Type = GCompute.TypeReference ("Function")
		}
		self.Members [name]:SetParentScope (self)
		self.Metadata [name].Type:SetResolutionScope (self:GetGlobalScope ())
	end
	self.VariableCount = self.VariableCount + 1
	return self.Members [name]:AddFunction (returnType, ...)
end

function Scope:AddMemberFunction (name, returnType)
	if not self.Members [name] then
		self.Members [name] = GCompute.FunctionList (name)
		self.Metadata [name] = {
			Type = GCompute.TypeReference ("Function")
		}
		self.Members [name]:SetParentScope (self)
		self.Metadata [name].Type:SetResolutionScope (self:GetGlobalScope ())
	end
	self.VariableCount = self.VariableCount + 1
	return self.Members [name]:AddMemberFunction (returnType)
end

function Scope:AddMemberVariable (typeName, name, value)
	if self.Members [name] then
		GCompute.Error ("Unable to create member variable " .. name .. ": " .. name .. " already exists in this scope.")
		return
	end
	
	self.Members [name] = value
	self.Metadata [name] =
		{
			Type = GCompute.TypeReference (typeName)
		}
	self.Metadata [name].Type:SetResolutionScope (self)
	
	self.VariableCount = self.VariableCount + 1
end

function Scope:AddNamespace (name)
	if self.Members [name] then
		if self.Metadata [name].Type:ToString () == "_G.Namespace" then
			return self.Members [name]
		else
			GCompute.Error ("Unable to create Namespace " .. name .. ": " .. name .. " already exists in this scope.")
			return
		end
	end
	
	self.Members [name] = GCompute.Scope ()
	self.Metadata [name] =
		{
			Type = GCompute.TypeReference ("Namespace")
		}
	self.Members [name]:SetGlobalScope (self:GetGlobalScope ())
	self.Members [name]:SetParentScope (self)
	self.Metadata [name].Type:SetResolutionScope (self:GetGlobalScope ())
	
	return self.Members [name]
end

function Scope:AddType (name)
	if self.Members [name] then
		GCompute.Error ("Unable to create Type " .. name .. ": " .. name .. " already exists in this scope.")
		return nil
	end
	
	self.Members [name] = GCompute.ParametricType (name)
	self.Metadata [name] =
		{
			Type = GCompute.TypeReference ("Type")
		}
	self.Members [name]:SetResolutionScope (self)
	self.Metadata [name].Type:SetResolutionScope (self:GetGlobalScope ())
	
	return self.Members [name]
end

function Scope:AddTypeReference (name, referencedType)
	if self.Members [name] then
		GCompute.Error ("Unable to create TypeReference " .. name .. ": " .. name .. " already exists in this scope.")
		return nil
	end
	
	self.Members [name] = GCompute.TypeReference (referencedType)
	self.Metadata [name] =
		{
			Type = GCompute.TypeReference ("Type")
		}
	self.Members [name]:SetResolutionScope (self)
	self.Metadata [name].Type:SetResolutionScope (self:GetGlobalScope ())
	
	self.Members [name]:ResolveType ()
	
	return self.Members [name]
end

function Scope:CreateInstance ()
	local Scope = GCompute.Scope ()
	Scope:SetGlobalScope (self:GetGlobalScope ())
	
	for name, metadata in pairs (self.Metadata) do
		Scope:AddMemberVariable (metadata.Type, name, self.Members [name])
	end
	
	return Scope
end

function Scope:GetFullName ()
	local fullName = ""
	if self.ParentScope then
		fullName = self.ParentScope:GetFullName () .. "."
	end
	fullName = fullName .. self:GetShortName ()
	return fullName
end

function Scope:GetGlobalScope ()
	return self.GlobalScope
end

--[[
	Scope:GetMember (string memberName)
		Returns: memberValue, Type memberType
		     or: nil, nil
]]
function Scope:GetMember (memberName)
	if self.Metadata [memberName] then
		return self.Members [memberName], self.Metadata [memberName].Type
	end
	return nil, nil
end

--[[
	Scope:GetMemberReference (string memberName)
		Returns: memberValue, Reference (self, memberName)
		     or: nil, nil
		
		Member references are cached.
]]
function Scope:GetMemberReference (memberName)
	if self.Metadata [memberName] then
		if not self.Metadata [memberName].Reference then
			self.Metadata [memberName].Reference = GCompute.Reference (self, memberName)
		end
		return self.Members [memberName], self.Metadata [memberName].Reference
	end
	return nil, nil
end

--[[
	Scope:GetMember Type(string memberName)
		Returns: Type memberType
		     or: nil
]]
function Scope:GetMemberType (memberName)
	if self.Metadata [memberName] then
		return self.Metadata [memberName].Type
	end
	return nil
end

function Scope:GetParentScope ()
	return self.ParentScope
end

function Scope:GetShortName ()
	if self.GlobalScope == self then return "_G" end
	return self.Name or "[Unnamed Scope]"
end

function Scope:HasVariables ()
	return self.VariableCount > 0
end

function Scope:IsGlobalScope ()
	return self.GlobalScope == self
end

function Scope:SetGlobalScope (globalScope)
	if self.GlobalScope and self.GlobalScope ~= globalScope then GCompute.Error ("Global scope already set!") end
	
	self.GlobalScope = globalScope
end

function Scope:SetMember (name, value)
	self.Members [name] = value
end

function Scope:SetMemberType (name, typeName)
	self.Metadata [name].Type = GCompute.TypeReference (typeName)
	self.Metadata [name].Type:SetResolutionScope (self)
end

function Scope:SetModifiers (name, modifiers)
	for _, Modifier in ipairs (modifiers) do
		self.Metadata [name] [Modifier:lower()] = true
	end
end

function Scope:SetName (name)
	self.Name = name
end

function Scope:SetParentScope (parentScope)
	if self.ParentScope and self.ParentScope ~= parentScope then GCompute.Error ("Parent scope already set!") end

	self.ParentScope = parentScope
end

function Scope:ToString ()
	local members = ""
	for name, metadata in pairs (self.Metadata) do
		local memberType = "[unknown]"
		local value = self.Members [name]
		if metadata.Type then
			memberType = metadata.Type:ToString ()
		end
		if memberType == "_G.Type" then
			value = value:ToDefinitionString ()
		elseif type (value) == "table" then
			if value.ToString then
				value = value:ToString ()
			end
		end
		value = tostring (value):gsub ("\n", "\n    ")
		members = members .. "\n    " .. memberType .. " " .. name .. " = " .. value
	end
	return "{" .. members .. "\n}"
end