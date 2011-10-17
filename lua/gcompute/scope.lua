local Scope = {}
Scope.__index = Scope
GCompute._Scope = Scope

function GCompute.Scope ()
	local Object = {}
	setmetatable (Object, Scope)
	Object:ctor ()
	return Object
end

function Scope:ctor ()
	self.Types = {}	
	self.Members = {}
	self.Metadata = {}
	self.Commands = {}
	self.NextAnonymousTypeIndex = 1
end

function Scope:AddAnonymousType ()
	local Type = self:AddType ("*AnonymousType" .. tostring (self.NextAnonymousTypeIndex))
	self.NextAnonymousTypeIndex = self.NextAnonymousTypeIndex + 1
	return Type
end

function Scope:AddCommand (Node)
	self.Commands [#self.Commands + 1] = Node
end

function Scope:AddFunction (Name, ReturnType, ...)
	if not self.Members [Name] then
		self.Members [Name] = GCompute.FunctionList (Name)
		self.Metadata [Name] = {
			Type = "function"
		}
	end
	return self.Members [Name]:AddFunction (ReturnType, ...)
end

function Scope:AddMemberFunction (Name, ReturnType, ...)
	if not self.Members [Name] then
		self.Members [Name] = GCompute.FunctionList (Name)
		self.Metadata [Name] = {
			Type = "function"
		}
	end
	return self.Members [Name]:AddMemberFunction (ReturnType, ...)
end

function Scope:AddMemberVariable (Type, Name, Value)
	self.Members [Name] = Value
	self.Metadata [Name] = {
		Type = Type
	}
end

function Scope:AddType (Name)
	if self.Types [Name] then
		return self.Types [Name]
	end
	local Type = GCompute.Type (Name)
	self.Types [Name] = GCompute.Type (Name)
	
	return Type
end

function Scope:Execute (ExecutionContext)
	for i = 1, #self.Commands do
		local Command = self.Commands [i]
	end
end

function Scope:GetItem (Name)
	if self.Types [Name] then
		return self.Types [Name], "Type"
	end
	if self.Members [Name] then
		return self.Members [Name], self.Metadata [Name].Type
	end
	return nil, nil
end

function Scope:IsType (Name)
	if self.Types [Name] then
		return true
	end
	return false
end

function Scope:SetModifiers (Name, Modifiers)
	for _, Modifier in ipairs (Modifiers) do
		self.Metadata [Name] [Modifier:lower()] = true
	end
end