local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

local lastSpoke = ents.GetByIndex (-1)
local lastSaid  = ""

local chatProcesses = {}

GCompute:AddEventListener ("ProcessTerminated",
	function (_, process)
		chatProcesses [process] = nil
	end
)

hook.Add (SERVER and "PlayerSay" or "OnPlayerChat", "GCompute.Expression2.Chat",
	function (ply, message, teamChat)
		lastSpoke = ply or ents.GetByIndex (-1)
		lastSaid = message
		
		for process, _ in pairs (chatProcesses) do
			local thread = process:CreateThread ()
			local tls = thread:GetThreadLocalStorage ()
			thread:SetName ("Expression2.Chat")
			thread:SetFunction (
				function ()
					tls.Expression2.ChatClk = true
					process:GetRootNamespace ():GetConstructor () ()
					tls.Expression2.ChatClk = false
				end
			)
			thread:Start ()
			thread:RunSome ()
			
			if tls.Expression2.HideChat then
				return SERVER and "" or true
			end
		end
	end
)

Expression2:AddMethod ("runOnChat", "number runOnChat")
	:SetNativeFunction (
		function (runOnChat)
			if runOnChat == 1 then
				chatProcesses [executionContext:GetProcess ()] = true
				executionContext:GetProcess ():AddHold ("Expression2.Chat")
			else
				chatProcesses [executionContext:GetProcess ()] = nil
				executionContext:GetProcess ():RemoveHold ("Expression2.Chat")
			end
		end
	)

Expression2:AddMethod ("chatClk")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function ()
			local tls = executionContext:GetThreadLocalStorage ()
			return tls.Expression2.ChatClk or false
		end
	)

Expression2:AddMethod ("lastSaid")
	:SetReturnType ("string")
	:SetNativeFunction (
		function ()
			return lastSaid
		end
	)

Expression2:AddMethod ("lastSpoke")
	:SetReturnType ("player")
	:SetNativeFunction (
		function ()
			return lastSpoke
		end
	)