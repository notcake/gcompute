local self = {}
GAuth.GroupTreeSender = GAuth.MakeConstructor (self)

function self:ctor ()
	self.PermissionBlockNetworker = GAuth.PermissionBlockNetworker ()
	self.PermissionBlockNetworker:AddEventListener ("Request",      tostring (self), self.Request)
	self.PermissionBlockNetworker:AddEventListener ("Notification", tostring (self), self.Notification)

	-- Make a closure for the NodeAdded and Removed event handler
	self.NodeAdded = function (groupTreeNode, childNode)
		self:HookNode (childNode)
	
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeAdditionNotification (groupTreeNode, childNode))
	end
	
	self.HostChanged = function (groupTreeNode, hostId)
		self.PermissionBlockNetworker:UnhookBlock (groupTreeNode)
		if groupTreeNode:IsHostedLocally () then
			self.PermissionBlockNetworker:HookBlock (groupTreeNode:GetPermissionBlock ())
		else
			self.PermissionBlockNetworker:HookRemoteBlock (groupTreeNode:GetPermissionBlock ())
		end
	end
	
	self.Removed = function (groupTreeNode)
		self:UnhookNode (groupTreeNode)
	end
end

function self:HookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:AddEventListener ("UserAdded",   tostring (self), self.UserAdded)		
		groupTreeNode:AddEventListener ("UserRemoved", tostring (self), self.UserRemoved)
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:AddEventListener ("NodeAdded",   tostring (self), self.NodeAdded)
		groupTreeNode:AddEventListener ("NodeRemoved", tostring (self), self.NodeRemoved)
	end
	
	groupTreeNode:AddEventListener ("HostChanged", tostring (self), self.HostChanged)
	groupTreeNode:AddEventListener ("Removed",     tostring (self), self.Removed)
	
	if groupTreeNode:IsHostedLocally () then
		self.PermissionBlockNetworker:HookBlock (groupTreeNode:GetPermissionBlock ())
	else
		self.PermissionBlockNetworker:HookRemoteBlock (groupTreeNode:GetPermissionBlock ())
	end
end

function self:SendNode (destUserId, groupTreeNode)
	local send = true
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then send = false end
	if groupTreeNode:GetHost () == destUserId then send = false end
	
	if send then
		for _, notification in ipairs (self.PermissionBlockNetworker:SerializeBlock (groupTreeNode:GetPermissionBlock ())) do
			GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.NodePermissionBlockNotification (groupTreeNode:GetFullName (), notification))
		end
	end
	
	if groupTreeNode:IsGroup () then
		if send then
			for userId in groupTreeNode:GetUserEnumerator () do
				GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.UserAdditionNotification (groupTreeNode, userId))
			end
		end
	elseif groupTreeNode:IsGroupTree () then
		for _, childNode in groupTreeNode:GetChildEnumerator () do
			if send then
				GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.NodeAdditionNotification (groupTreeNode, childNode))
			end
			self:SendNode (destUserId, childNode)
		end
	end
end

function self:UnhookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:RemoveEventListener ("UserAdded",   tostring (self))
		groupTreeNode:RemoveEventListener ("UserRemoved", tostring (self))
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:RemoveEventListener ("NodeAdded",   tostring (self))
		groupTreeNode:RemoveEventListener ("NodeRemoved", tostring (self))
	end
	
	groupTreeNode:RemoveEventListener ("HostChanged", tostring (self))
	groupTreeNode:RemoveEventListener ("Removed",     tostring (self))
	
	self.PermissionBlockNetworker:UnhookBlock (groupTreeNode:GetPermissionBlock ())
end

-- Events
self.NodeAdded = GAuth.NullCallback -- Needs to be a closure to access self:Hook ()

function self.NodeRemoved (groupTreeNode, childNode)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeRemovalNotification (groupTreeNode, childNode))
end

function self.UserAdded (groupTreeNode, userId)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserAdditionNotification (groupTreeNode, userId))
end
		
function self.UserRemoved (groupTreeNode, userId)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserRemovalNotification (groupTreeNode, userId))
end

-- These needs to be closures in order to access self.PermissionBlockNetworker
-- and self:UnhookNode ()
self.HostChanged = GAuth.NullCallback
self.Removed     = GAuth.NullCallback

-- PermissionBlockNetworker events
function self.Notification (_, permissionBlock, notification)
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodePermissionBlockNotification (permissionBlock:GetName (), notification))
end

function self.Request (_, permissionBlock, request)
	local groupId = permissionBlock:GetName ()
	local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
	if not groupTreeNode then return end
	if groupTreeNode:IsPredicted () then return end
	
	GAuth.EndPointManager:GetEndPoint (groupTreeNode:GetHost ()):StartSession (GAuth.Protocol.NodePermissionBlockRequest (groupTreeNode, request))
	
	return true
end

GAuth.GroupTreeSender = GAuth.GroupTreeSender ()