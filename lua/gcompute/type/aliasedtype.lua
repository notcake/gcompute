local self = {}
GCompute.AliasedType = GCompute.MakeConstructor (self, GCompute.Type)

local blacklist =
{
	["GetGlobalNamespace"] = true,
	["GetTypeSystem"]      = true,
	["SetGlobalNamespace"] = true,
	["SetTypeSystem"]      = true
}

for functionName, v in pairs (GCompute.GetMetaTable (GCompute.Type)) do
	if type (v) == "function" and not blacklist [functionName] then
		self [functionName] = function (self, ...)
			return self.InnerType [functionName] (self.InnerType, ...)
		end
	end
end

function self:ctor (aliasDefinition, innerType)
	self.Alias      = aliasDefinition
	self.InnerType  = innerType
	
	self.Definition = innerType:GetDefinition ()
	self.Namespace  = innerType:GetNamespace ()
end

function self:GetFullName ()
	return self.Alias:GetFullName ()
end

function self:GetRelativeName (referenceDefinition)
	return self.Alias:GetRelativeName (referenceDefinition)
end

function self:ToString ()
	return self:GetFullName ()
end

function self:ToType ()
	return self
end

function self:UnwrapAlias ()
	return self.InnerType:UnwrapAlias ()
end