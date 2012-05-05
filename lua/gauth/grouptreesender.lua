local self = {}
GAuth.GroupTreeSender = GAuth.MakeConstructor (self)

function self:ctor ()
end

function self:HookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:AddEventListener ("UserAdded", tostring (self),
			function (groupTreeNode, userId)
				if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
				GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserAdditionNotification (groupTreeNode, userId))
			end
		)
		
		groupTreeNode:AddEventListener ("UserRemoved", tostring (self),
			function (groupTreeNode, userId)
				if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
				GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserRemovalNotification (groupTreeNode, userId))
			end
		)
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:AddEventListener ("NodeAdded", tostring (self),
			function (groupTreeNode, childNode)
				self:HookNode (childNode)
			
				if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
				GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeAdditionNotification (groupTreeNode, childNode))
			end
		)
		
		groupTreeNode:AddEventListener ("NodeRemoved", tostring (self),
			function (groupTreeNode, childNode)
				if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
				GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeRemovalNotification (groupTreeNode, childNode))
			end
		)
	end
	
	groupTreeNode:AddEventListener ("Removed", tostring (self),
		function (_)
			self:UnhookNode (groupTreeNode)
		end
	)
end

function self:SendNode (destUserId, groupTreeNode)
	if groupTreeNode:IsGroup () then
	elseif groupTreeNode:IsGroupTree () then
		for _, childGroupTreeNode in groupTreeNode:GetChildEnumerator () do
			self:SendNode (destUserId, childGroupTreeNode)
		end
	end
end

function self:UnhookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:RemoveEventListener ("UserAdded", tostring (self))
		groupTreeNode:RemoveEventListener ("UserRemoved", tostring (self))
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:RemoveEventListener ("NodeAdded", tostring (self))
		groupTreeNode:RemoveEventListener ("NodeRemoved", tostring (self))
	end
	
	groupTreeNode:RemoveEventListener ("Removed", tostring (self))
end

GAuth.GroupTreeSender = GAuth.GroupTreeSender ()