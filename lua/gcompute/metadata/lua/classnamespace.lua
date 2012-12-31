local self = {}
GCompute.Lua.ClassNamespace = GCompute.MakeConstructor (self, GCompute.Lua.TableNamespace)

function self:ctor (table)
end

-- Class Namespace
function self:AddConstructor (luaFunction)
	local constructorDefinition = luaFunction
	self:SetupMemberHierarchy (constructorDefinition)
	constructorDefinition:SetMemberStatic (true)
	
	self.Constructors [#self.Constructors + 1] = constructorDefinition
	
	return constructorDefinition
end

function self:IsClassNamespace ()
	return true
end