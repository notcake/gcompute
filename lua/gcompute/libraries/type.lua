local Global = GCompute.GlobalNamespace
local Type = Global:AddClass ("Type")
Type:SetNativelyAllocated (true)
GCompute.TypeSystem:SetType (Type)

Type:AddMethod ("ToString")
	:SetNativeFunction (
		function (type)
			return type:GetFullName ()
		end
	)