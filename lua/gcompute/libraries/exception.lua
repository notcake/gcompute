local Global = GCompute.GlobalNamespace
local Exception = Global:AddClass ("Exception")

Exception:AddConstructor ()
	:SetNativeFunction (
		function (self)
			self._.StackTrace = GCompute.StackTrace ()
		end
	)

Exception:AddProperty ("StackTrace", "string")
	:AddGetter ()
		:SetNativeFunction (
			function (self)
				return self._.StackTrace
			end
		)