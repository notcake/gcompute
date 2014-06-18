local self = {}
GCompute.ClassType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (classDefinition)
	self.Definition = classDefinition
	self.Namespace  = classDefinition:GetNamespace ()
	
	self.BaseTypes  = {}
end

function self:SetNamespace (namespace)
	self.Namespace = namespace
end

-- Type
local forwardedFunctions =
{
	"CanConstructFrom",
	"CanExplicitCastTo",
	"CanImplicitCastTo",
	"CreateDefaultValue",
	"GetFullName",
	"GetRelativeName",
	"IsConcreteType"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		return self.Definition [functionName] (self.Definition, ...)
	end
end

--- Adds a base type to this class
-- @param baseType The base type to be added, as a string, DeferredObjectResolution or Type
function self:AddBaseType (baseType)
	baseType = GCompute.ToDeferredTypeResolution (baseType, self:GetDefinition ())
	
	-- Check for cycles, duplicate base types
	if not baseType:IsDeferredObjectResolution () then
		baseType = baseType:ToType ()
		if baseType:Equals (self) then
			GCompute.Error ("ClassType:AddBaseType : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because they are the same type.")
			return
		elseif baseType:IsBaseType (self) then
			GCompute.Error ("ClassType:AddBaseType : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because " .. baseType:GetFullName () .. " inherits from " .. self:GetFullName () .. ".")
			return
		elseif self:IsBaseType (baseType) then
			GCompute.Error ("ClassType:AddBaseType : " .. baseType:GetFullName () .. " is already a base type of " .. self:GetFullName () .. ".")
			return
		elseif baseType:GetDefinition () then
			self:GetDefinition ():GetUniqueNameMap ():AddChainedNameMap (baseType:GetDefinition ():GetUniqueNameMap ())
		end
	end
	
	self.BaseTypes [#self.BaseTypes + 1] = baseType
end

function self:Equals (otherType)
	if self == otherType then return true end
	return self:GetFullName () == otherType:UnwrapAlias ():GetFullName ()
end

function self:GetBaseType (index)
	if #self.BaseTypes == 0 then
		if index == 1 and not self:IsTop () and not self:IsBottom () then
			return GCompute.TypeSystem:GetObject ()
		end
		return nil
	end
	return self.BaseTypes [index]
end

function self:GetBaseTypeCount ()
	if #self.BaseTypes ~= 0 then return #self.BaseTypes end
	if self:IsTop () or self:IsBottom () then return 0 end
	return 1
end

function self:GetCorrespondingDefinition (globalNamespace)
	if self:GetGlobalNamespace () == globalNamespace then return self end
	local correspondingDefinition = self:GetDefinition ():GetCorrespondingDefinition (globalNamespace)
	if not correspondingDefinition then return nil end
	return correspondingDefinition:GetClassType ()
end

function self:ResolveTypes (objectResolver, compilerMessageSink)
	for k, baseType in ipairs (self.BaseTypes) do
		if baseType:IsDeferredObjectResolution () then
			-- Set the local namespace to our definition, 
			-- for resolution of type parameters
			if self:GetDefinition () then
				baseType:SetLocalNamespace (self:GetDefinition ())
			end
			
			baseType:Resolve (objectResolver)
			if baseType:IsFailedResolution () then
				GCompute.Error ("ClassType:ResolveTypes : Failed to resolve base type of " .. self:GetFullName () .. " : " .. baseType:GetFullName ())
				baseType:GetAST ():GetMessages ():PipeToCompilerMessageSink (GCompute.DefaultCompilerMessageSink)
				self.BaseTypes [k] = GCompute.ErrorType ()
			else
				baseType = baseType:GetObject ():ToType ()
				if baseType:Equals (self) then
					GCompute.Error ("ClassType:ResolveTypes : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because they are the same type.")
				elseif baseType:IsBaseType (self) then
					GCompute.Error ("ClassType:ResolveTypes : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because " .. baseType:GetFullName () .. " inherits from " .. self:GetFullName () .. ".")
				elseif self:IsBaseType (baseType) then
					GCompute.Error ("ClassType:ResolveTypes : " .. baseType:GetFullName () .. " is already a base type of " .. self:GetFullName () .. ".")
				else
					self.BaseTypes [k] = baseType
					if baseType:GetDefinition () then
						self:GetDefinition ():GetUniqueNameMap ():AddChainedNameMap (baseType:GetDefinition ():GetUniqueNameMap ())
					end
				end
			end
		end
	end
end