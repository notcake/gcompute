local Global = GCompute.GlobalNamespace
local Collections = Global:AddNamespace ("Collections")

local Dictionary = Collections:AddClass ("Dictionary", "TKey, TValue")
local Function = nil

Dictionary:AddMethod ("Dictionary")
	:SetNativeFunction (
		function (self)
			self.Count = 0
			self.KeyValues = {}
		end
	)

Dictionary:AddMethod ("Add", "TKey key, TValue value")
	:SetNativeFunction (
		function (self, key, value)
			if self.KeyValues [key] == nil then
				self.Count = self.Count + 1
			end
			self.KeyValues [key] = value
		end
	)

Dictionary:AddMethod ("Clear")
	:SetNativeFunction (
		function (self)
			self.Count = 0
			self.KeyValues = {}
		end
	)

Dictionary:AddMethod ("ContainsKey", "TKey key")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, key)
			return self.KeyValues [key] ~= nil
		end
	)