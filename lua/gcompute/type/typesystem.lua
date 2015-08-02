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
function self:Clone (clone, globalNamespace)
	clone = clone or self.__ictor ()
	
	clone:Copy (self, globalNamespace)
	
	return clone
end

function self:Copy (source, globalNamespace)
	self:SetGlobalNamespace (globalNamespace or source:GetGlobalNamespace ())
	
	if globalNamespace then
		self:SetBottom   (source.Bottom   and source.Bottom  :GetCorrespondingDefinition (globalNamespace) or nil)
		self:SetTop      (source.Top      and source.Top     :GetCorrespondingDefinition (globalNamespace) or nil)
		self:SetEnum     (source.Enum     and source.Enum    :GetCorrespondingDefinition (globalNamespace) or nil)
		self:SetFunction (source.Function and source.Function:GetCorrespondingDefinition (globalNamespace) or nil)
		self:SetType     (source.Type     and source.Type    :GetCorrespondingDefinition (globalNamespace) or nil)
	else
		self:SetBottom   (source.Bottom)
		self:SetTop      (source.Top)
		self:SetEnum     (source.Enum)
		self:SetFunction (source.Function)
		self:SetType     (source.Type)
	end
	
	return self
end

function self:CreateAliasedType (aliasDefinition, innerType)
	return GCompute.AliasedType (aliasDefinition, innerType)
		:SetGlobalNamespace (self.GlobalNamespace)
end

function self:CreateArrayType (elementType, rank)
	return GCompute.ArrayType (elementType, rank)
		:SetGlobalNamespace (self.GlobalNamespace)
end

function self:CreateClassType (classDefinition)
	return GCompute.ClassType (classDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
end

function self:CreateEnumType (enumDefinition)
	return GCompute.EnumType (enumDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
end

function self:CreateFunctionType (returnType, parameterList)
	return GCompute.FunctionType (returnType, parameterList)
		:SetGlobalNamespace (self.GlobalNamespace)
end

function self:CreateTypeParameter (typeParameterDefinition)
	return GCompute.TypeParameterType (typeParameterDefinition)
		:SetGlobalNamespace (self.GlobalNamespace)
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

GCompute.TypeSystem = GCompute.TypeSystem ()