local self = {}
GCompute.Expression2.GTableManager = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Owners = {}
	self:CreateNamespace (GLib.GetEveryoneId ())
	
	GCompute:AddEventListener ("ProcessStarted",
		function (_, process)
			local ownerId = process:GetOwnerId ()
			self:CreateNamespace (ownerId)
			self.Owners [ownerId].ProcessCount = self.Owners [ownerId].ProcessCount + 1
		end
	)
	
	GCompute:AddEventListener ("ProcessTerminated",
		function (_, process)
			local ownerId = process:GetOwnerId ()
			if not self.Owners [ownerId] then return end
			self.Owners [ownerId].ProcessCount = self.Owners [ownerId].ProcessCount - 1
			self:CheckOwner (ownerId)
		end
	)
	
	GCompute.PlayerMonitor:AddEventListener ("PlayerDisconnected", "Expression2.GTableManager",
		function (_, userId)
			self:CheckOwner (userId)
		end
	)
end

function self:GetGTable (ownerId, name)
	self:CreateNamespace (ownerId)
	self.Owners [ownerId] [name] = self.Owners [ownerId] [name] or GCompute.Expression2.CreateContainer ()
	return self.Owners [ownerId] [name]
end

-- Internal, do not call
function self:CheckOwner (ownerId)
	if ownerId == GLib.GetEveryoneId () then return end
	if not self.Owners [ownerId] then return end
	if self.Owners [ownerId].ProcessCount > 0 then return end
	if GCompute.PlayerMonitor:GetUserEntity (ownerId) then return end
	
	self.Owners [ownerId] = nil
end

function self:CreateNamespace (ownerId)
	if self.Owners [ownerId] then return end
	
	self.Owners [ownerId] =
	{
		ProcessCount = 0
	}
end

GCompute.Expression2.GTableManager = GCompute.Expression2.GTableManager ()