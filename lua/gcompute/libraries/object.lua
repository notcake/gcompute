local Global = GCompute.GlobalNamespace
local Object = Global:AddClass ("Object")
Object:GetClassType ():SetTop (true)
GCompute.TypeSystem:SetObject (Object)

Object:AddMethod ("GetHashCode")
	:SetReturnType ("int")
	:SetNativeFunction (
		function (self)
			return tonumber (util.CRC (self:GetHashCode ()))
		end
	)

Object:AddMethod ("GetType")
	:SetReturnType ("Type")
	:SetNativeFunction (
		function (self)
			return self:GetType ()
		end
	)

Object:AddMethod ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			return "{" .. self:GetType ():GetFullName () .. "}"
		end
	)

Object:AddMethod ("operator==", "Object other")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			if self:IsBox () and other:IsBox () then
				return self:GetBoxedValue () == other:GetBoxedValue ()
			end
			return self == other
		end
	)
	
Object:AddMethod ("operator!=", "Object other")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			if self:IsBox () and other:IsBox () then
				return self:GetBoxedValue () ~= other:GetBoxedValue ()
			end
			return self ~= other
		end
	)