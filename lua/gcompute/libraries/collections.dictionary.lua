local Global = GCompute.GlobalNamespace
local Collections = Global:AddNamespace ("Collections")

local Dictionary = Collections:AddType ("Dictionary", { "TKey", "TValue" })
local Function = nil

Dictionary:AddFunction ("Dictionary")
	:SetNativeFunction (
		function (self)
			self.Count = 0
			self.KeyValues = {}
		end
	)

Dictionary:AddFunction ("Add", { { "TKey", "key" } , { "TValue", "value" } })
	:SetNativeFunction (
		function (self, key, value)
			if not self.KeyValues [key] then
				self.Count = self.Count + 1
			end
			self.KeyValues [key] = value
		end
	)

Dictionary:AddFunction ("Clear")
	:SetNativeFunction (
		function (self)
			self.Count = 0
			self.KeyValues = {}
		end
	)

Dictionary:AddFunction ("ContainsKey", { { "TKey", "key" } })
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, key)
			if self.KeyValues [key] then
				return true
			end
			return false
		end
	)