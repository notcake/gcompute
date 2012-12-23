local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

local tickProcesses = {}

GCompute:AddEventListener ("ProcessStarted",
	function (_, process)
		local tls = process:GetMainThread ():GetThreadLocalStorage ()
		tls.Expression2 = tls.Expression2 or {}
		tls.Expression2.First = true
	end
)

GCompute:AddEventListener ("ProcessTerminated",
	function (_, process)
		tickProcesses [process] = nil
	end
)

GCompute:AddEventListener ("ThreadTerminated",
	function (_, process, thread)
		local tls = thread:GetThreadLocalStorage ()
		tls.Expression2.First = false
	end
)

Expression2:AddMethod ("first")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function ()
			local tls = executionContext:GetThreadLocalStorage ()
			return tls.Expression2.First or false
		end
	)

Expression2:AddMethod ("duped")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function ()
			local tls = executionContext:GetThreadLocalStorage ()
			return tls.Expression2.Duped or false
		end
	)

Expression2:AddMethod ("interval", "number milliseconds")
	:SetNativeFunction (
		function (executionInterval)
			executionContext:GetProcess ():AddHold ("Expression2.Interval")
			
			local tls = executionContext:GetThreadLocalStorage ()
			tls.Expression2.ExecutionInterval = executionInterval
		end
	)

Expression2:AddMethod ("perf")
	:SetReturnType ("number")
	:SetNativeFunction (
		function ()
			return 1
		end
	)

Expression2:AddMethod ("runOnTick", "number runOnTick")
	:SetNativeFunction (
		function (runOnTick)
			if runOnTick == 1 then
				tickProcesses [executionContext:GetProcess ()] = true
				executionContext:GetProcess ():AddHold ("Expression2.Tick")
			else
				tickProcesses [executionContext:GetProcess ()] = nil
				executionContext:GetProcess ():RemoveHold ("Expression2.Tick")
			end
		end
	)