local self = {}
GCompute.TypeSystem = GCompute.MakeConstructor (self)

function self:ctor ()
	self.GlobalNamespace = nil
	
	self.Top    = nil
	self.Bottom = nil
	
	self.Enum     = nil
	self.Function = nil
	self.Type     = nil
end

-- System
function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:SetGlobalNamespace (globalNamespace)
	self.GlobalNamespace = globalNamespace
	return self
end

-- Type System
function self:Clone (globalNamespace)
	local typeSystem = GCompute.TypeSystem ()
	typeSystem:SetGlobalNamespace (globalNamespace or self.GlobalNamespace)
	if globalNamespace then
		globalNamespace:SetTypeSystem (typeSystem)
		typeSystem:SetBottom   (self.Bottom   and self.Bottom  :GetCorrespondingDefinition (globalNamespace, typeSystem) or nil)
		typeSystem:SetTop      (self.Top      and self.Top     :GetCorrespondingDefinition (globalNamespace, typeSystem) or nil)
		typeSystem:SetEnum     (self.Enum     and self.Enum    :GetCorrespondingDefinition (globalNamespace, typeSystem) or nil)
		typeSystem:SetFunction (self.Function and self.Function:GetCorrespondingDefinition (globalNamespace, typeSystem) or nil)
		typeSystem:SetType     (self.Type     and self.Type    :GetCorrespondingDefinition (globalNamespace, typeSystem) or nil)
	else
		typeSystem:SetBottom   (self.Bottom)
		typeSystem:SetTop      (self.Top)
		typeSystem:SetEnum     (self.Enum)
		typeSystem:SetFunction (self.Function)
		typeSystem:SetType     (self.Type)
	end
	return typeSystem
end

function self:CreateAliasedType (aliasDefinition, innerType)
	return GCompute.AliasedType (aliasDefinition, innerType)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:CreateArrayType (elementType, rank)
	return GCompute.ArrayType (elementType, rank)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:CreateClassType (classDefinition)
	return GCompute.ClassType (classDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:CreateEnumType (enumDefinition)
	return GCompute.EnumType (enumDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:CreateFunctionType (returnType, parameterList)
	return GCompute.FunctionType (returnType, parameterList)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:CreateTypeParameter (typeParameterDefinition)
	return GCompute.TypeParameterType (typeParameterDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
		:SetTypeSystem (self)
end

function self:GetBottom ()
	return self.Bottom
end
self.GetVoid = self.GetBottom

function self:GetEnum ()
	return self.Enum
end

function self:GetFunction ()
	return self.Function
end

function self:GetTop ()
	return self.Top
end
self.GetObject = self.GetTop

function self:GetType ()
	return self.Type
end

function self:GetVoid ()
	return self.Void
end

function self:SetBottom (type)
	type = type and type:ToType ()
	self.Bottom = type
end
self.SetVoid = self.SetBottom

function self:SetEnum (type)
	type = type and type:ToType ()
	self.Enum = type
end

function self:SetFunction (type)
	type = type and type:ToType ()
	self.Function = type
end

function self:SetTop (type)
	type = type and type:ToType ()
	self.Top = type
end
self.SetObject = self.SetTop

function self:SetType (type)
	type = type and type:ToType ()
	self.Type = type
end

function self:ToString ()
	local typeSystem = "[Type System]\n{\n"
	typeSystem = typeSystem .. "    Bottom   = " .. (self.Bottom   and self.Bottom  :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Top      = " .. (self.Top      and self.Top     :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Enum     = " .. (self.Enum     and self.Enum    :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Function = " .. (self.Function and self.Function:GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "    Type     = " .. (self.Type     and self.Type    :GetFullName () or "[Nothing]") .. "\n"
	typeSystem = typeSystem .. "}"
	
	return typeSystem
end