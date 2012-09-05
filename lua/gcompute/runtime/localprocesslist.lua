local self = {}
GCompute.LocalProcessList = GCompute.MakeConstructor (self, GCompute.ProcessList)

function self:ctor ()
	hook.Add ("Think", "GCompute.Run",
		function ()
			local startTime = SysTime ()
			for _, process in self:GetEnumerator () do
				for _, thread in process:GetThreadEnumerator () do
					thread:RunSome ()
					if SysTime () - startTime > 0.005 then return end
				end
			end
		end
	)
	
	GCompute:AddEventListener ("Unloaded",
		function ()
			hook.Remove ("Think", "GCompute.Run")
		end
	)
end

GCompute.LocalProcessList = GCompute.LocalProcessList ()