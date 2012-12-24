local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

local GTable = Expression2:AddClass ("gtable")
GTable:SetNullable (false)
GTable:SetNativelyAllocated (true)

Expression2:AddMethod ("gTable", "string name")
	:SetReturnType ("gtable")
	:SetNativeFunction (
		function (name)
			return GCompute.Expression2.GTableManager:GetGTable (
				executionContext:GetProcess ():GetOwnerId (),
				name
			)
		end
	)

Expression2:AddMethod ("gTable", "string name, bool shared")
	:SetReturnType ("gtable")
	:SetNativeFunction (
		function (name, shared)
			return GCompute.Expression2.GTableManager:GetGTable (
				shared and GLib.GetEveryoneId () or executionContext:GetProcess ():GetOwnerId (),
				name
			)
		end
	)

GCompute.Expression2.AddContainerIndexer (GTable, "string")