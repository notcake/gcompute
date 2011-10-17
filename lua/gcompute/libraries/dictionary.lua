local G = GCompute.GlobalScope

local Type = nil
local Function = nil
Type = G:AddType ("Dictionary")
Type:AddArgument ("Key")
Type:AddArgument ("Value")

Function = Type:AddMemberFunction ("Dictionary", "void")
Function.Native = function (ExecutionContext, self)
	self.Count = 0
	self.KeyValues = {}
end

Function = Type:AddMemberFunction ("Add", "void")
Function:AddArgument ("Key", "Key")
Function:AddArgument ("Value", "Value")
Function.Native = function (ExecutionContext, self, Key, Value)
	if not self.KeyValues [Key] then
		self.Count = self.Count + 1
	end
	if not Value then
		self.Count = self.Count - 1
	end
	self.KeyValues [Key] = Value
end

Function = Type:AddMemberFunction ("Clear", "void")
Function.Native = function (ExecutionContext, self)
	self.Count = 0
	self.KeyValues = {}
end

Function = Type:AddMemberFunction ("ContainsKey", "Boolean")
Function:AddArgument ("Key", "Key")
Function.Native = function (ExecutionContext, self, Key)
	if self.KeyValues [Key] then
		return true
	end
	return false
end