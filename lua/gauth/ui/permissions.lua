local self = {}

function self:Init ()
	self:SetTitle ("Permissions - ")

	self:SetSize (ScrW () * 0.3, ScrH () * 0.6)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.PermissionBlock = nil
	self.SelectedGroup = nil
	self.SelectedGroupId = nil
	self.SelectedPermissionBlock = nil
	
	self.Owner = vgui.Create ("DLabel", self)
	self.Owner:SetText ("Owner: ")
	self.OwnerIcon = vgui.Create ("GImage", self)
	self.OwnerName = vgui.Create ("DLabel", self)
	self.OwnerName:SetText ("Unknown")
	
	self.ChangeOwner = vgui.Create ("GButton", self)
	self.ChangeOwner:SetText ("Change")
	self.ChangeOwner:AddEventListener ("Click",
		function (_)
			local permissionBlock = self.PermissionBlock
			local dialog = GAuth.OpenUserSelectionDialog (
				function (userId)
					if not userId then return end
					permissionBlock:SetOwner (GAuth.GetLocalId (), userId)
				end
			)
			dialog:SetTitle ("Change owner...")
			dialog:SetSelectionMode (Gooey.SelectionMode.One)
		end
	)
	
	self.InheritOwner = vgui.Create ("GCheckbox", self)
	self.InheritOwner:SetText ("Inherit owner from parent")
	self.InheritPermissions = vgui.Create ("GCheckbox", self)
	self.InheritPermissions:SetText ("Inherit permissions from parent")
	
	self.InheritOwner:AddEventListener ("CheckStateChanged",
		function (_, checked)
			self.PermissionBlock:SetInheritOwner (GAuth.GetLocalId (), checked)
		end
	)
	
	self.InheritPermissions:AddEventListener ("CheckStateChanged",
		function (_, checked)
			self.PermissionBlock:SetInheritPermissions (GAuth.GetLocalId (), checked)
		end
	)
	
	self.Groups = vgui.Create ("GComboBox", self)
	self.Groups:SetSelectionMode (Gooey.SelectionMode.One)
	self.Groups:SetComparator (
		function (a, b)
			-- Sorted by permission block hierarchy,
			-- permission block headers go first
			if a == b then return false end
			if a.PermissionBlockIndex > b.PermissionBlockIndex then return true end
			if a.PermissionBlockIndex < b.PermissionBlockIndex then return false end
			if a.IsPermissionBlock then return true end
			if b.IsPermissionBlock then return false end
			return a:GetText ():lower () < b:GetText ():lower ()
		end
	)
	
	self.Groups.Menu = vgui.Create ("GMenu")
	self.Groups.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			self.Groups.Menu:FindItem ("Add"):SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
			if not targetItem or not targetItem.GroupId then
				self.Groups.Menu:FindItem ("Remove"):SetDisabled (true)
				return
			end
			self.Groups.Menu:SetTargetItem (targetItem.GroupId)
			local targetGroupId = targetItem.GroupId
			if targetItem.PermissionBlock ~= self.PermissionBlock then
				self.Groups.Menu:FindItem ("Remove"):SetDisabled (true)
			else
				self.Groups.Menu:FindItem ("Remove"):SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
			end
		end
	)
	self.Groups.Menu:AddOption ("Add",
		function ()
			local permissionBlock = self.PermissionBlock
			GAuth.OpenGroupSelectionDialog (
				function (group)
					if not group then return end
					permissionBlock:AddGroupEntry (GAuth.GetLocalId (), group:GetFullName ())
				end
			):SetTitle ("Add group...")
		end
	):SetIcon ("gui/g_silkicons/group_add")
	self.Groups.Menu:AddOption ("Remove",
		function (targetGroupId)
			if not targetGroupId then return end
			self.PermissionBlock:RemoveGroupEntry (GAuth.GetLocalId (), targetGroupId)
		end
	):SetIcon ("gui/g_silkicons/group_delete")
	
	self.Groups:AddEventListener ("SelectionChanged",
		function (_, item)			
			self.SelectedGroup = item and item.Group or nil
			self.SelectedGroupId = item and item.GroupId
			self.SelectedPermissionBlock = item and item.PermissionBlock
			self:CheckPermissions ()
			self:PopulatePermissions ()
		end
	)
	
	self.PermissionList = vgui.Create ("GListView", self)
	self.PermissionList:AddColumn ("Name")
	self.PermissionList:AddColumn ("Allow"):SetType ("Checkbox")
	self.PermissionList:AddColumn ("Deny"):SetType ("Checkbox")
	
	self.PermissionList:AddEventListener ("ItemChecked", function (_, line, i, checked)
		if not self.SelectedGroupId then return end
		if self.SelectedPermissionBlock ~= self.PermissionBlock then return end
		self.PermissionList:SuppressEvents (true)
		if checked then
			if i == 2 then
				line:SetCheckState (3, false)
				self.PermissionBlock:SetGroupPermission (GAuth.GetLocalId (), self.SelectedGroupId, line.ActionId, GAuth.Access.Allow)
			elseif i == 3 then
				line:SetCheckState (2, false)
				self.PermissionBlock:SetGroupPermission (GAuth.GetLocalId (), self.SelectedGroupId, line.ActionId, GAuth.Access.Deny)
			end
		else
			self.PermissionBlock:SetGroupPermission (GAuth.GetLocalId (), self.SelectedGroupId, line.ActionId, GAuth.Access.None)
		end
		self.PermissionList:SuppressEvents (false)
	end)
	
	self:PerformLayout ()
	
	GAuth:AddEventListener ("Unloaded", tostring (self), function ()
		self:Remove ()
	end)
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.PermissionList then
		local y = 30
		
		self.InheritOwner:SetPos (8, y)
		self.InheritOwner:SetSize (self:GetWide () - 16, 14)
		y = y + self.InheritOwner:GetTall () + 8
		
		self.InheritPermissions:SetPos (8, y)
		self.InheritPermissions:SetSize (self:GetWide () - 16, 14)
		y = y + self.InheritPermissions:GetTall () + 8
		
		self.ChangeOwner:SetSize (80, 24)
		self.ChangeOwner:SetPos (self:GetWide () - 8 - self.ChangeOwner:GetWide (), y)
		
		self.Owner:SizeToContents ()
		self.Owner:SetPos (8, y + (self.ChangeOwner:GetTall () - self.Owner:GetTall ()) * 0.5)
		self.OwnerIcon:SetSize (16, 16)
		self.OwnerIcon:SetPos (8 + self.Owner:GetWide (), y + (self.ChangeOwner:GetTall () - self.OwnerIcon:GetTall ()) * 0.5)
		self.OwnerName:SizeToContents ()
		self.OwnerName:SetPos (8 + self.Owner:GetWide () + self.OwnerIcon:GetWide () + 2, y + (self.ChangeOwner:GetTall () - self.OwnerName:GetTall ()) * 0.5)
		y = y + self.ChangeOwner:GetTall () + 8
		
		self.Groups:SetPos (8, y)
		self.Groups:SetSize (self:GetWide () - 16, self:GetTall () * 0.35)
		y = y + self.Groups:GetTall () + 8
		
		self.PermissionList:SetPos (8, y)
		self.PermissionList:SetSize (self:GetWide () - 16, self:GetTall () - y - 8)
	end
end

function self:Remove ()
	self.PermissionBlock:RemoveEventListener ("GroupEntryAdded", tostring (self))
	self.PermissionBlock:RemoveEventListener ("GroupEntryRemoved", tostring (self))
	self.PermissionBlock:RemoveEventListener ("GroupPermissionChanged", tostring (self))
	self.PermissionBlock:RemoveEventListener ("InheritOwnerChanged", tostring (self))
	self.PermissionBlock:RemoveEventListener ("InheritPermissionsChanged", tostring (self))
	self.PermissionBlock:RemoveEventListener ("OwnerChanged", tostring (self))

	GAuth:RemoveEventListener ("Unloaded", tostring (self))
	_R.Panel.Remove (self)
end

function self:SetPermissionBlock (permissionBlock)
	if self.PermissionBlock then return end

	self.PermissionBlock = permissionBlock
	self:SetTitle ("Permissions - " .. permissionBlock:GetDisplayName ())
	
	self:UpdateInheritOwner ()
	self:UpdateInheritPermissions ()
	self:CheckPermissions ()
	
	self:UpdateOwner ()
	self:PopulateGroupEntries ()
	
	-- Populate permissions
	self.PermissionList:Clear ()
	if self.PermissionBlock:GetPermissionDictionary () then
		for actionId in self.PermissionBlock:GetPermissionDictionary ():GetPermissionEnumerator () do
			local line = self.PermissionList:AddLine (actionId)
			line.ActionId = actionId
		end
		self.PermissionList:Sort ()
	end
	
	-- Events
	self.PermissionBlock:AddEventListener ("GroupEntryAdded", tostring (self),
		function (_, groupId)
			self:AddGroup (groupId, self.PermissionBlock, 1)
			self.Groups:Sort ()
		end
	)
	
	self.PermissionBlock:AddEventListener ("GroupEntryRemoved", tostring (self),
		function (permissionBlock, groupId)
			for _, item in pairs (self.Groups:GetItems ()) do
				if item.GroupId == groupId and
					item.PermissionBlock == permissionBlock then
					self.Groups:RemoveItem (item)
					return
				end
			end
			
			self:CheckPermissions ()
		end
	)
	
	self.PermissionBlock:AddEventListener ("GroupPermissionChanged", tostring (self),
		function (permissionBlock, groupId, actionId, access)
			self:CheckPermissions ()
			self:PopulatePermissions ()
		end
	)
	
	self.PermissionBlock:AddEventListener ("InheritOwnerChanged", tostring (self),
		function (permissionBlock, groupId, actionId, access)
			self:CheckPermissions ()
			self:PopulatePermissions ()
			self:UpdateInheritOwner ()
			self:UpdateOwner ()
		end
	)
	
	self.PermissionBlock:AddEventListener ("InheritPermissionsChanged", tostring (self),
		function (permissionBlock, groupId, actionId, access)
			self:CheckPermissions ()
			self:PopulateGroupEntries ()
			self:PopulatePermissions ()
			self:UpdateInheritPermissions ()
		end
	)
	
	self.PermissionBlock:AddEventListener ("OwnerChanged", tostring (self),
		function (permissionBlock, groupId, actionId, access)
			self:CheckPermissions ()
			self:PopulatePermissions ()
			self:UpdateOwner ()
		end
	)
end

-- Internal, do not call
function self:AddGroup (groupId, permissionBlock, permissionBlockIndex)
	local group = GAuth.ResolveGroup (groupId)
	local item = self.Groups:AddItem (group and group:GetFullDisplayName () or groupId)
	item:SetIcon (group and group:GetIcon () or "gui/g_silkicons/group")
	item:SetIndent (16)
	item.Group = group
	item.GroupId = groupId
	item.PermissionBlock = permissionBlock
	item.PermissionBlockIndex = permissionBlockIndex
	item.IsPermissionBlock = false
	item.IsGroup = true
end

function self:CheckPermissions ()
	self.InheritOwner:SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Set Owner"))
	self.InheritPermissions:SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
	self.ChangeOwner:SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Set Owner"))
	
	if not self.SelectedGroupId or self.SelectedPermissionBlock ~= self.PermissionBlock then
		self.PermissionList:SetDisabled (true)
	else
		self.PermissionList:SetDisabled (not self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
	end
end

function self:PopulateGroupEntries ()
	-- Prepare parent block list
	local permissionBlocks = {}
	local parentBlock = self.PermissionBlock
	while parentBlock do
		permissionBlocks [#permissionBlocks + 1] = parentBlock
		parentBlock = parentBlock:InheritsPermissions () and parentBlock:GetParent ()
	end
	
	local selectedGroupId = self.SelectedGroupId
	local selectedPermissionBlock = self.SelectedPermissionBlock
	
	-- Populate group entries
	self.Groups:Clear ()
	local groups = {}
	for i = 1, #permissionBlocks do
		local permissionBlock = permissionBlocks [i]
		local groupCount = 0
		for groupId in permissionBlock:GetGroupEntryEnumerator () do
			self:AddGroup (groupId, permissionBlock, i)
			groupCount = groupCount + 1
		end
		
		if groupCount > 0 or i == 1 then
			local item = self.Groups:AddItem (permissionBlock:GetDisplayName ())
			if item:GetText () == "" then item:SetText ("[root]") end
			item:SetIcon ("gui/g_silkicons/key")
			item:SetCanSelect (false)
			item.PermissionBlock = permissionBlock
			item.PermissionBlockIndex = i
			item.IsPermissionBlock = true
			item.IsGroup = false
		end
	end
	self.Groups:Sort ()
	
	for _, item in pairs (self.Groups:GetItems ()) do
		if item.GroupId == selectedGroupId and
			item.PermissionBlock == selectedPermissionBlock then
			item:Select ()
			break
		end
	end
end

function self:PopulatePermissions ()
	self.PermissionList:SuppressEvents (true)
	for _, permissionLine in pairs (self.PermissionList:GetItems ()) do
		if self.SelectedGroupId then
			local access = self.SelectedPermissionBlock:GetGroupPermission (self.SelectedGroupId, permissionLine.ActionId)
			if access == GAuth.Access.Allow then
				permissionLine:SetCheckState (2, true)
			elseif access == GAuth.Access.Deny then
				permissionLine:SetCheckState (3, true)
			end
		else
			-- group deselected
			permissionLine:SetCheckState (2, false)
			permissionLine:SetCheckState (3, false)
		end
	end
	self.PermissionList:SuppressEvents (false)
end

function self:UpdateInheritOwner ()
	self.InheritOwner:SuppressEvents (true)
	self.InheritOwner:SetValue (self.PermissionBlock:InheritsOwner ())
	self.InheritOwner:SuppressEvents (false)
end

function self:UpdateInheritPermissions ()
	self.InheritPermissions:SuppressEvents (true)
	self.InheritPermissions:SetValue (self.PermissionBlock:InheritsPermissions ())
	self.InheritPermissions:SuppressEvents (false)
end

function self:UpdateOwner ()
	local ownerId = self.PermissionBlock:GetOwner ()
	local ownerName = GAuth.PlayerMonitor:GetUserName (ownerId)
	self.OwnerIcon:SetImage (GAuth.GetUserIcon (ownerId))
	if ownerName ~= ownerId then
		self.OwnerName:SetText (ownerName .. " (" .. ownerId .. ")")
	else
		self.OwnerName:SetText (ownerName)
	end
	self.OwnerName:SizeToContents ()
end

vgui.Register ("GAuthPermissions", self, "DFrame")

function GAuth.OpenPermissions (permissionBlock)
	local dialog = vgui.Create ("GAuthPermissions")
	dialog:SetPermissionBlock (permissionBlock)
	dialog:SetVisible (true)
	
	return dialog
end