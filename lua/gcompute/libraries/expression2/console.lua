local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

Expression2:AddMethod ("concmd", "string consoleCommand")
	:SetNativeFunction (
		function (consoleCommand)
			local ownerId = executionContext:GetProcess ():GetOwnerId ()
			if ownerId == GLib.GetLocalId () or CLIENT then
				LocalPlayer ():ConCommand (consoleCommand)
			else
				local owner = GCompute.Net.PlayerMonitor:GetUserEntity (ownerId)
				if owner and owner:IsValid () then
					owner:ConCommand (consoleCommand)
				end
			end
		end
	)