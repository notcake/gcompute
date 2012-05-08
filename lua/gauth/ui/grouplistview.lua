local self = {}

--[[
	Events
	
	UserSelected (userId)
		Fired when a user is selected from the list.
]]

function self:Init ()
	self.Group = nil

	self.Menu = vgui.Create ("GMenu")
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			local targetItem = self:GetSelectedUsers ()
			self.Menu:SetTargetItem (targetItem)
			self.Menu:FindItem ("Permissions"):SetDisabled (not self.Group)
			
			if self.Group and self.Group:IsGroup () then
				local permissionBlock = self.Group:GetPermissionBlock ()
				self.Menu:FindItem ("Add User"):SetDisabled (not self.Group or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Add User"))
				self.Menu:FindItem ("Remove User"):SetDisabled (#targetItem == 0 or not permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Remove User"))
			else
				self.Menu:FindItem ("Add User"):SetDisabled (true)
				self.Menu:FindItem ("Remove User"):SetDisabled (true)
			end
		end
	)
	self.Menu:AddOption ("Add User",
		function ()
			if not self.Group then return end
			local group = self.Group
			GAuth.OpenUserSelectionDialog (
				function (userIds)
					if not userIds then return end
					for _, userId in ipairs (userIds) do
						group:AddUser (GAuth.GetLocalId (), userId)
					end
				end
			):SetTitle ("Add user...")
		end
	):SetIcon ("gui/g_silkicons/user_add")
	self.Menu:AddOption ("Remove User",
		function (targetUserIds)
			if not self.Group then return end
			if not targetUserIds then return end
			if #targetUserIds == 0 then return end
			for _, userId in ipairs (targetUserIds) do
				self.Group:RemoveUser (GAuth.GetLocalId (), userId)
			end
		end
	):SetIcon ("gui/g_silkicons/user_delete")
	self.Menu:AddSeparator ()
	self.Menu:AddOption ("Permissions",
		function ()
			if not self.Group then return end
			GAuth.OpenPermissions (self.Group:GetPermissionBlock ())
		end
	):SetIcon ("gui/g_silkicons/key")
end

function self:GetSelectedUsers ()
	local selectedUsers = {}
	for _, item in ipairs (self.SelectionController:GetSelectedItems ()) do
		selectedUsers [#selectedUsers + 1] = item.UserId
	end
	return selectedUsers
end

function self:SetGroup (group)
	self:Clear ()
	if self.Group then
		self.Group:RemoveEventListener ("UserAdded", tostring (self))
		self.Group:RemoveEventListener ("UserRemoved", tostring (self))
		self.Group = nil
	end
	if not group then return end
	if not group:IsGroup () then return end
	self.Group = group
	for userId in self.Group:GetUserEnumerator () do
		local comboBoxItem = self:AddItem (GAuth.GetUserDisplayName (userId), userId)
		comboBoxItem:SetIcon (GAuth.GetUserIcon (userId))
		comboBoxItem.UserId = userId
	end
	self:Sort ()
	
	self.Group:AddEventListener ("UserAdded", tostring (self),
		function (_, userId)
			local comboBoxItem = self:AddItem (GAuth.GetUserDisplayName (userId), userId)
			comboBoxItem:SetIcon (GAuth.GetUserIcon (userId))
			comboBoxItem.UserId = userId
			self:Sort ()
		end
	)
	
	self.Group:AddEventListener ("UserRemoved", tostring (self),
		function (_, userId)
			for _, item in pairs (self:GetItems ()) do
				if item.UserId == userId then
					self:RemoveItem (item)
					return
				end
			end
		end
	)
end

vgui.Register ("GAuthGroupListView", self, "GComboBox")