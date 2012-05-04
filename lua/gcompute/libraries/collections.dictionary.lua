local G = GCompute.GlobalScope
local Collections = G:AddNamespace ("Collections")

local Type = Collections:AddType ("Dictionary")
local Members = Type:GetMembers ()
local Function = nil
Type:AddArgument ("Type", "TKey")
Type:AddArgument ("Type", "TValue")

Function = Members:AddMemberFunction ("Dictionary", "void")
Function.Native = function (executionContext, self)
	self.Count = 0
	self.KeyValues = {}
end

Function = Members:AddMemberFunction ("Add", "void")
Function:AddArgument ("Key", "Key")
Function:AddArgument ("Value", "Value")
Function.Native = function (executionContext, self, key, value)
	if not self.KeyValues [key] then
		self.Count = self.Count + 1
	end
	self.KeyValues [key] = value
end

Function = Members:AddMemberFunction ("Clear", "void")
Function.Native = function (executionContext, self)
	self.Count = 0
	self.KeyValues = {}
end

Function = Members:AddMemberFunction ("ContainsKey", "Boolean")
Function:AddArgument ("Key", "Key")
Function.Native = function (executionContext, self, key)
	if self.KeyValues [key] then
		return true
	end
	return false
end