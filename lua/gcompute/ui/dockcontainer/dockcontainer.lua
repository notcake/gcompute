local PANEL = {}

--[[
	Events:
		ActiveViewChanged (View oldView, View view)
			Fired on the root container when the selected view has changed.
		ContainerSplit (DockContainer splitDockContainer, DockContainer container, DockContainer emptyContainer)
			Fired on the root container when a container has been split.
		ViewCloseRequested (View view)
			Fired on the root container when the user attempts to close a view.
		ViewDropped (View view, DockContainer originalContainer, DockContainer container)
			Fired on the root container when the user moves a view from one DockContainer to another.
		ViewMoved (View view)
			Fired on the root container when a view has been placed in a new tab or DockContainer.
		ViewRegistered (View view)
			Fired on the root container when a view has been registered.
		ViewRemoved (DockContainer container, View view, ViewRemovalReason viewRemovalReason)
			Fired on the root container when a view has been displaced from a tab or DockContainer.
		ViewUnregistered (View view)
			Fired on the root container when a view has been unregistered.
]]

function PANEL:Init ()
	self.DockContainerType = GCompute.DockContainer.DockContainerType.None
	self.ParentDockContainer = nil
	
	self.Child = nil
	
	-- Root
	self.ActiveView = nil
	self.SkipActiveViewThink = 0
	
	-- TabControl
	self.LocalViewSet   = {}
	self.LocalViewsById = {}
	self.LocalViewCount = 0
	
	self.VisibleViewCount = 0
	self.VisibleViewCountValid = false
	
	-- Drag and drop
	self.DragDropController = GCompute.DockContainer.DragDropController (self)
	self.DragDropController:SetDropTargetEnabled (true)
end

function PANEL:AddView (view)
	if not view then return end
	if self.LocalViewSet [view] then return end
	
	if next (self.LocalViewSet) and self.DockContainerType == GCompute.DockContainer.DockContainerType.View then
		self:SetContainerType (GCompute.DockContainer.DockContainerType.TabControl)
	end
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.None then
		self:SetContainerType (GCompute.DockContainer.DockContainerType.View)
	end
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.TabControl and
	   self.DockContainerType ~= GCompute.DockContainer.DockContainerType.View then
		GCompute.Error ("DockContainer:AddView : This DockContainer is not in tabcontrol or view mode!")
		return
	end
	
	local originalDockContainer = view:GetContainer ():GetDockContainer ()
	if originalDockContainer then
		originalDockContainer:RemoveView (view, GCompute.ViewRemovalReason.Rearrangement)
	end
	
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		self:RegisterLocalView (view)
		
		local tab = self.Child:AddTab (view:GetTitle ())
		tab.View = view
		tab:SetCloseButtonVisible (true)
		tab:SetContents (view:GetContainer ())
		
		tab:SetIcon (view:GetIcon ())
		tab:SetText (view:GetTitle ())
		tab:SetToolTipText (view:GetToolTipText ())
		
		view:GetContainer ():SetTab (tab)
	else
		if self:GetView () then
			GCompute.Error ("DockContainer:AddView : This DockContainer in view mode already has a view!")
		end
		
		self:RegisterLocalView (view)
		view:GetContainer ():SetParent (self)
		self.Child = view:GetContainer ()
	end
	view:GetContainer ():SetDockContainer (self)
	view:GetContainer ():SetVisible (true)
	self:HookView (view)
	
	local rootDockContainer = self:GetRootDockContainer ()
	if originalDockContainer then
		rootDockContainer:DispatchEvent ("ViewRemoved", originalDockContainer, view, GCompute.ViewRemovalReason.Rearrangement)
	end
	rootDockContainer:DispatchEvent ("ViewMoved", view)
end

function PANEL:GetActiveView ()
	if not self:IsRootDockContainer () then
		return self:GetRootDockContainer ():GetActiveView ()
	end
	
	return self.ActiveView
end

function PANEL:GetContainerType ()
	return self.DockContainerType
end

function PANEL:GetLargestContainer ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		return self
	end
	
	local panel1 = self:GetPanel1 ():GetLargestContainer ()
	local panel2 = self:GetPanel2 ():GetLargestContainer ()
	if panel1:GetWide () * panel1:GetTall () > panel2:GetWide () * panel2:GetTall () then
		return panel1
	end
	return panel2
end

function PANEL:GetLargestView ()
	local largestContainer = self:GetLargestContainer ()
	if not largestContainer then return nil end
	
	if largestContainer:GetContainerType () == GCompute.DockContainer.DockContainerType.TabControl then
		if not largestContainer.Child then return nil end
		return largestContainer.Child:GetSelectedTab () and largestContainer.Child:GetSelectedTab ().View or nil
	elseif largestContainer:GetContainerType () == GCompute.DockContainer.DockContainerType.View then
		return largestContainer:GetView ()
	end
	return nil
end

function PANEL:GetLocalViewCount ()
	return self.LocalViewCount
end

function PANEL:GetLocalViewEnumerator ()
	local next, tbl, key = pairs (self.LocalViewSet)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function PANEL:GetParentDockContainer ()
	return self.ParentDockContainer
end

function PANEL:GetCreateSplit (dockingSide, fraction)
	local dockContainer = self:GetSplit (dockingSide)
	if not dockContainer then
		dockContainer = self:Split (dockingSide, fraction)
	end
	return dockContainer
end

function PANEL:GetPath ()
	if self:IsRootDockContainer () then return "root" end
	local path = self:GetParentDockContainer ():GetPath () .. "/"
	if self:GetParentDockContainer ():GetOrientation () == Gooey.Orientation.Vertical then
		if self:IsPanel1 () then path = path .. "Left"
		elseif self:IsPanel2 () then path = path .. "Right"
		else path = path .. "Error" end
	else
		if self:IsPanel1 () then path = path .. "Top"
		elseif self:IsPanel2 () then path = path .. "Bottom"
		else path = path .. "Error" end
	end
	return path
end

function PANEL:GetSplit (dockingSide)
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
		local queryOrientation = Gooey.Orientation.Horizontal
		if dockingSide == GCompute.DockContainer.DockingSide.Left or
		   dockingSide == GCompute.DockContainer.DockingSide.Right then
			queryOrientation = Gooey.Orientation.Vertical
		end
		
		if self:GetOrientation () == queryOrientation then
			local childDockContainer
			if dockingSide == GCompute.DockContainer.DockingSide.Top or
			   dockingSide == GCompute.DockContainer.DockingSide.Left then
				childDockContainer = self:GetPanel1 ()
			else
				childDockContainer = self:GetPanel2 ()
			end
			local firstChoice, secondChoice = childDockContainer:GetSplit (dockingSide)
			return secondChoice or firstChoice
		else
			return nil, self:GetPanel1 ():GetLargestContainer ()
		end
	end
	return nil, self
end

function PANEL:GetRootDockContainer ()
	if self:IsRootDockContainer () then return self end
	return self:GetParentDockContainer ():GetRootDockContainer ()
end

function PANEL:IsPanel1 ()
	if self:IsRootDockContainer () then return false end
	return self:GetParentDockContainer ():GetPanel1 () == self
end

function PANEL:IsPanel2 ()
	if self:IsRootDockContainer () then return false end
	return self:GetParentDockContainer ():GetPanel2 () == self
end

function PANEL:IsRootDockContainer ()
	return self.ParentDockContainer == nil
end

function PANEL:Merge (childDockContainer)
	if not childDockContainer then return end
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:Merge : This DockContainer is not in splitcontainer mode.")
		return
	end
	if childDockContainer:GetParentDockContainer () ~= self then
		GCompute.Error ("DockContainer:Merge : The specified DockContainer is not a direct child of this DockContainer.")
		return
	end
	
	local splitContainer = self.Child
	local otherDockContainer = self:GetPanel1 ()
	if otherDockContainer == childDockContainer then
		otherDockContainer = self:GetPanel2 ()
	end
	
	self.DockContainerType = childDockContainer.DockContainerType
	self.DragDropController:SetDropTargetEnabled (self:IsRootDockContainer () or childDockContainer.DragDropController:IsDropTargetEnabled ())
	self.Child          = childDockContainer.Child
	self.LocalViewSet   = childDockContainer.LocalViewSet
	self.LocalViewsById = childDockContainer.LocalViewsById
	self.LocalViewCount = childDockContainer.LocalViewCount
	
	if self.Child then
		self.Child:SetParent (self)
		if self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
			self:GetPanel1 ():SetParentDockContainer (self)
			self:GetPanel2 ():SetParentDockContainer (self)
		end
	end
	
	self:HookTabControl ()
	childDockContainer:UnhookTabControl ()
	
	for view, _ in pairs (self.LocalViewSet) do
		self:HookView (view)
		childDockContainer:UnhookView (view)
		view:GetContainer ():SetDockContainer (self)
	end
	
	childDockContainer.Child = nil
	childDockContainer.LocalViewSet   = {}
	childDockContainer.LocalViewsById = {}
	childDockContainer.LocalViewCount = 0
	
	childDockContainerType = GCompute.DockContainer.DockContainerType.None
	childDockContainer:Remove ()
	otherDockContainer:Remove ()
	splitContainer:Remove ()
	
	self:PerformLayoutRecursive ()
end

function PANEL:Paint (w, h)
end

function PANEL:PerformLayout ()
	if self.Child then
		self.Child:SetPos (0, 0)
		self.Child:SetSize (self:GetSize ())
	end
end

function PANEL:PerformLayoutRecursive ()
	self:PerformLayout ()
	if not self.Child then return end
	
	self.Child:PerformLayout ()
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
		self:GetPanel1 ():PerformLayoutRecursive ()
		self:GetPanel2 ():PerformLayoutRecursive ()
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		local selectedTab = self.Child:GetSelectedTab ()
		local contents = selectedTab and selectedTab:GetContents () or nil
		if contents and contents:IsValid () then
			contents:PerformLayout ()
			if contents.GetContents then
				contents = contents:GetContents ()
				contents = contents and contents:IsValid () and contents or nil
			else
				contents = nil
			end
			
			-- Check if contents are valid and have a PerformLayout function.
			-- Some non-lua panel types do not have a PerformLayout function.
			if contents and
			   contents:IsValid () and
			   type (contents.PerformLayout) == "function" then
				contents:PerformLayout ()
			end
		end
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.View then
		local container = self:GetView () and self:GetView ():GetContainer ()
		local contents = container and container:GetContents () or nil
		if contents and
		   contents:IsValid () and
		   type (contents.PerformLayout) == "function" then
			contents:PerformLayout ()
		end
	end
end

function PANEL:RegisterLocalView (view)
	if not view then return end
	if self.LocalViewSet [view] then return end
	
	self.LocalViewSet [view] = true
	self.LocalViewsById [view:GetId ()] = view
	self.LocalViewCount = self.LocalViewCount + 1
end

function PANEL:RemoveView (view, viewRemovalReason)
	if not view then return end
	
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.TabControl and
	   self.DockContainerType ~= GCompute.DockContainer.DockContainerType.View then
		GCompute.Error ("DockContainer:RemoveView : This DockContainer is not in tabcontrol or view mode!")
	end
	
	if not self.LocalViewSet [view] then return end
	self:UnregisterLocalView (view)
	
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		if view:GetContainer ():GetTab () then
			view:GetContainer ():GetTab ().View = nil
			view:GetContainer ():GetTab ():SetContents (nil)
			view:GetContainer ():GetTab ():Remove ()
			view:GetContainer ():SetTab (nil)
		end
	else
		self.Child = nil
	end
	view:GetContainer ():SetParent (nil)
	view:GetContainer ():SetDockContainer (nil)
	view:GetContainer ():SetVisible (false)
	self:UnhookView (view)
	
	if self:GetActiveView () == view then
		self:SetActiveView (nil)
	end
	
	if viewRemovalReason == GCompute.ViewRemovalReason.Rearrangement then
		-- Called from AddView, AddView will fire the ViewRemoved event when
		-- it has finished.
		return
	end
	self:GetRootDockContainer ():DispatchEvent ("ViewRemoved", self, view, viewRemovalReason or GCompute.ViewRemovalReason.Removal)
end

function PANEL:SetActiveView (view)
	if not self:IsRootDockContainer () then
		self:GetRootDockContainer ():SetActiveView (view)
		return
	end
	
	if self.ActiveView == view then return end
	
	local oldSelectedView = self.ActiveView
	self.ActiveView = view
	
	self.SkipActiveViewThink = 2
	
	self:DispatchEvent ("ActiveViewChanged", oldActiveView, view)
end

function PANEL:SetContainerType (dockContainerType)
	if not GCompute.DockContainer.DockContainerType [dockContainerType] then
		GCompute.Error ("DockContainer:SetContainerType : Container type " .. dockContainerType .. " is not valid!")
		return
	end
	if self.DockContainerType == dockContainerType then return end
	
	local firstView = next (self.LocalViewSet)
	if dockContainerType ~= GCompute.DockContainer.DockContainerType.TabControl and
	   dockContainerType ~= GCompute.DockContainer.DockContainerType.View then
		firstView = nil
	end
	for view, _ in pairs (self.LocalViewSet) do
		self:RemoveView (view, view == firstView and GCompute.ViewRemovalReason.Conversion or GCompute.ViewRemovalReason.Removal)
	end
	
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		self:UnhookTabControl ()
	end
	
	if self.Child then
		self.Child:Remove ()
		self.Child = nil
	end
	
	self.DockContainerType = dockContainerType
	self.DragDropController:SetDropTargetEnabled (self:IsRootDockContainer ())
	
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.None then
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.View then
		self:AddView (firstView)
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		self.Child = vgui.Create ("GTabControl", self)
		self:HookTabControl ()
		self:AddView (firstView)
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
		self.Child = vgui.Create ("GSplitContainer", self)
		self.Child:SetPanel1 (vgui.Create ("GComputeDockContainer"))
		self.Child:SetPanel2 (vgui.Create ("GComputeDockContainer"))
		self.Child:GetPanel1 ():SetParentDockContainer (self)
		self.Child:GetPanel2 ():SetParentDockContainer (self)
	end
end

function PANEL:SetParentDockContainer (parentDockContainer)
	self.ParentDockContainer = parentDockContainer
end

function PANEL:Split (dockingSide, fraction)
	local childDockContainer = vgui.Create ("GComputeDockContainer")
	
	childDockContainer.DockContainerType = self.DockContainerType
	childDockContainer.DragDropController:SetDropTargetEnabled (self.DragDropController:IsDropTargetEnabled ())
	childDockContainer.Child = self.Child
	childDockContainer.LocalViewSet   = self.LocalViewSet
	childDockContainer.LocalViewsById = self.LocalViewsById
	childDockContainer.LocalViewCount = self.LocalViewCount
	
	if childDockContainer.Child then
		childDockContainer.Child:SetParent (childDockContainer)
		if childDockContainer.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
			childDockContainer:GetPanel1 ():SetParentDockContainer (childDockContainer)
			childDockContainer:GetPanel2 ():SetParentDockContainer (childDockContainer)
		end
	end
	
	childDockContainer:HookTabControl ()
	self:UnhookTabControl ()
	
	for view, _ in pairs (self.LocalViewSet) do
		childDockContainer:HookView (view)
		self:UnhookView (view)
		view:GetContainer ():SetDockContainer (childDockContainer)
	end
	
	self.Child = nil
	self.LocalViewSet   = {}
	self.LocalViewsById = {}
	self.LocalViewCount = 0
	
	self.DockContainerType = GCompute.DockContainer.DockContainerType.SplitContainer
	self.DragDropController:SetDropTargetEnabled (self:IsRootDockContainer ())
	
	self.Child = vgui.Create ("GSplitContainer", self)
	
	if dockingSide == GCompute.DockContainer.DockingSide.Top or
	   dockingSide == GCompute.DockContainer.DockingSide.Bottom then
		self:SetOrientation (Gooey.Orientation.Horizontal)
	else
		self:SetOrientation (Gooey.Orientation.Vertical)
	end
	
	local otherDockContainer = vgui.Create ("GComputeDockContainer")
	if dockingSide == GCompute.DockContainer.DockingSide.Top or
	   dockingSide == GCompute.DockContainer.DockingSide.Left then
		self.Child:SetPanel1 (otherDockContainer)
		self.Child:SetPanel2 (childDockContainer)
		self.Child:SetSplitterFraction (1 - (fraction or 0.75))
	else
		self.Child:SetPanel1 (childDockContainer)
		self.Child:SetPanel2 (otherDockContainer)
		self.Child:SetSplitterFraction (fraction or 0.75)
	end
	
	self.Child:GetPanel1 ():SetParentDockContainer (self)
	self.Child:GetPanel2 ():SetParentDockContainer (self)
	
	self:PerformLayoutRecursive ()
	if childDockContainer.Child and childDockContainer.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		GLib.CallDelayed (
			function ()
				if not childDockContainer then return end
				if not childDockContainer:IsValid () then return end
				if not childDockContainer.Child then return end
				if not childDockContainer.Child:IsValid () then return end
				if not childDockContainer.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then return end
				childDockContainer.Child:EnsureTabVisible (childDockContainer.Child:GetSelectedTab ())
			end
		)
	end
	
	self:GetRootDockContainer ():DispatchEvent ("ContainerSplit", self, childDockContainer, otherDockContainer)
	return otherDockContainer
end

function PANEL:ToString ()
	return self:GetPath () .. " [" .. tostring (self:GetTable ()) .. ": " .. GCompute.DockContainer.DockContainerType [self.DockContainerType] .. "]"
end

function PANEL:UnregisterLocalView (view)
	if not self.LocalViewSet [view] then return end
	
	self.LocalViewSet [view] = nil
	self.LocalViewsById [view:GetId ()] = nil
	self.LocalViewCount = self.LocalViewCount - 1
end

-- Persistance
function PANEL:LoadSession (inBuffer, viewManager)
	local dockContainerType = inBuffer:UInt8 ()
	self:SetContainerType (dockContainerType)
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.None then
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
		self:SetOrientation (inBuffer:UInt8 ())
		self.Child:SetSplitterFraction (inBuffer:UInt16 () / 32768)
		self:GetPanel1 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()), viewManager)
		self:GetPanel2 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()), viewManager)
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		local tabCount = inBuffer:UInt16 ()
		local selectedTabIndex = inBuffer:UInt16 ()
		for i = 1, tabCount do
			local view = viewManager:GetViewById (inBuffer:String ())
			self:AddView (view)
			if i == selectedTabIndex then
				view:GetContainer ():EnsureVisible ()
			end
		end
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.View then
		self:SetView (viewManager:GetViewById (inBuffer:String ()))
	end
end

function PANEL:SaveSession (outBuffer)
	outBuffer:UInt8 (self.DockContainerType)
	if self.DockContainerType == GCompute.DockContainer.DockContainerType.None then
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.SplitContainer then
		outBuffer:UInt8 (self:GetOrientation ())
		outBuffer:UInt16 (self.Child:GetSplitterFraction () * 32768)
		local subOutBuffer = GLib.StringOutBuffer ()
		self:GetPanel1 ():SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
		subOutBuffer:Clear ()
		self:GetPanel2 ():SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.TabControl then
		outBuffer:UInt16 (self.Child:GetTabCount ())
		outBuffer:UInt16 (self.Child:GetSelectedTabIndex ())
		for tab in self.Child:GetEnumerator () do
			outBuffer:String (tab.View:GetId ())
		end
	elseif self.DockContainerType == GCompute.DockContainer.DockContainerType.View then
		outBuffer:String (self:GetView ():GetId ())
	end
end

-- SplitContainer
function PANEL:GetOtherPanel (dockContainer)
	if self:GetPanel1 () == dockContainer then
		return self:GetPanel2 ()
	end
	return self:GetPanel1 ()
end

function PANEL:GetPanel1 ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetPanel1 : This DockContainer is not in SplitContainer mode!")
		return nil
	end
	
	return self.Child:GetPanel1 ()
end

function PANEL:GetPanel2 ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetPanel2 : This DockContainer is not in SplitContainer mode!")
		return nil
	end
	
	return self.Child:GetPanel2 ()
end

function PANEL:GetOrientation ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetOrientation : This DockContainer is not in SplitContainer mode!")
		return Gooey.Orientation.Vertical
	end
	
	return self.Child:GetOrientation ()
end

function PANEL:SetOrientation (orientation)
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:SetOrientation : This DockContainer is not in SplitContainer mode!")
		return
	end
	
	self.Child:SetOrientation (orientation)
end

-- View
function PANEL:GetView ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.View then
		GCompute.Error ("DockContainer:GetView : This DockContainer is not in view mode!")
	end
	return next (self.LocalViewSet)
end

function PANEL:SetView (view)
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.View then
		GCompute.Error ("DockContainer:SetView : This DockContainer is not in view mode!")
	end
	
	if self:GetView () == view then return end
	self:RemoveView (self:GetView (), GCompute.ViewRemovalReason.Removal)
	self:AddView (view)
end

-- Internal, do not call
function PANEL:HookTabControl ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.TabControl then return end
	
	self.Child:AddEventListener ("ExternalTabDragStarted", tostring (self:GetTable ()),
		function (_, tab)
			if not tab.View then return end
			self.DragDropController:StartDrag ("DockableView", tab.View)
		end
	)
	
	self.Child:AddEventListener ("SelectedContentsChanged", tostring (self:GetTable ()),
		function (_, oldSelectedTab, oldSelectedContents, selectedTab, selectedContents)
			self:GetRootDockContainer ():SetActiveView (selectedTab and selectedTab.View or nil)
		end
	)
	self.Child:AddEventListener ("TabAdded", tostring (self:GetTable ()),
		function (_, tab)
			if not tab.View then return end
			
			self:RegisterLocalView (tab.View)
		end
	)
	self.Child:AddEventListener ("TabCloseRequested", tostring (self:GetTable ()),
		function (_, tab)
			if not tab.View then return end
			
			self:GetRootDockContainer ():DispatchEvent ("ViewCloseRequested", tab.View)
		end
	)
	self.Child:AddEventListener ("TabRemoved", tostring (self:GetTable ()),
		function (_, tab)
			if not tab.View then return end
			
			-- If the view is being moved to another DockContainer,
			-- tab.View should be nil
			-- Otherwise, the view is being deleted.
			self:RemoveView (tab.View, GCompute.ViewRemovalReason.Removal)
		end
	)
end

function PANEL:UnhookTabControl ()
	if self.DockContainerType ~= GCompute.DockContainer.DockContainerType.TabControl then return end
	
	self.Child:RemoveEventListener ("ExternalTabDragStarted",  tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("SelectedContentsChanged", tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabAdded",                tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabCloseRequested",       tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabRemoved",              tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabVisibleChanged",       tostring (self:GetTable ()))
end

function PANEL:HookView (view)
	if not view then return end
	
	view:AddEventListener ("IconChanged", tostring (self:GetTable ()),
		function (_, icon)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetIcon (icon)
			end
		end
	)
	view:AddEventListener ("TitleChanged", tostring (self:GetTable ()),
		function (_, title)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetText (title)
			end
		end
	)
	view:AddEventListener ("ToolTipTextChanged", tostring (self:GetTable ()),
		function (_, toolTipText)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetToolTipText (toolTipText)
			end
		end
	)
	view:AddEventListener ("VisibleChanged", tostring (self:GetTable ()),
		function (_, visible)
			if view:GetContainer ():GetTab () then
				view:GetContainer ():GetTab ():SetVisible (visible)
			end
		end
	)
end

function PANEL:UnhookView (view)
	if not view then return end
	
	view:RemoveEventListener ("IconChanged",        tostring (self:GetTable ()))
	view:RemoveEventListener ("TitleChanged",       tostring (self:GetTable ()))
	view:RemoveEventListener ("ToolTipTextChanged", tostring (self:GetTable ()))
	view:RemoveEventListener ("VisibleChanged",     tostring (self:GetTable ()))
end

-- Event handlers
function PANEL:OnRemoved ()
	self.DragDropController:EndDrag ()
	
	local views = {}
	for view in self:GetLocalViewEnumerator () do
		views [#views + 1] = view
	end
	for _, view in ipairs (views) do
		view:dtor ()
	end
end

function PANEL:Think ()
	if not self:IsRootDockContainer () then return end
	
	local activePanel = vgui.GetKeyboardFocus ()
	if not activePanel then return end
	
	local activeView = self:GetActiveView ()
	local activeContainer = nil
	if activeView then
		activeContainer = activeView:GetContainer ()
		if not activeView:GetContainer () or not activeView:GetContainer ():IsValid () then
			self:SetActiveView (nil)
			activeContainer = nil
		end
	end
	
	if activeContainer and activeContainer:IsOurChild (activePanel) then return end
	
	if self.SkipActiveViewThink > 1 then
		self.SkipActiveViewThink = self.SkipActiveViewThink - 1
		return
	end
	
	if vgui.FocusedHasParent (self) then
		while activePanel and activePanel:IsValid () and activePanel.ClassName ~= self.ClassName do
			activePanel = activePanel:GetParent ()
		end
		if not activePanel or not activePanel:IsValid () then return end
		if activePanel:GetRootDockContainer () ~= self then return end
		if activePanel:GetContainerType () == GCompute.DockContainer.DockContainerType.TabControl then
			local selectedTab = activePanel.Child:GetSelectedTab ()
			self:SetActiveView (selectedTab and selectedTab.View)
		elseif activePanel:GetContainerType () == GCompute.DockContainer.DockContainerType.View then
			self:SetActiveView (activePanel:GetView ())
		end
	end
	
end

Gooey.Register ("GComputeDockContainer", PANEL, "GPanel")