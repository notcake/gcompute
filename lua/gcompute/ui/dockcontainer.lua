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
	self.DockContainerType = GCompute.DockContainerType.None
	self.ParentDockContainer = nil
	
	self.Child = nil
	
	-- Root
	self.ActiveView = nil
	self.SkipActiveViewThink = 0
	
	-- TabControl
	self.LocalViewSet   = {}
	self.LocalViewsById = {}
	self.LocalViewCount = 0
	
	-- Drag and drop
	self.DropData =
	{
		EnterTime = 0,
		LeaveTime = 0,
		
		LastActiveDropTarget         = GCompute.DockContainerDropTarget.None,
		LastActiveDropTargetFraction = 0.75,
		
		ActiveDropTarget             = GCompute.DockContainerDropTarget.None,
		ActiveDropTargetFraction     = 0.75,
		ActiveDropTargetChangeTime   = 0,
		
		LastActiveDropButton         = GCompute.DockContainerDropTarget.None,
		ActiveDropButton             = GCompute.DockContainerDropTarget.None,
		ActiveDropButtonChangeTime   = 0
	}
	self.RootDropData = table.Copy (self.DropData)
	self.DropData.Buttons =
	{
		{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY =   0, Glyph = "DockContainer.DockMiddle", Type = GCompute.DockContainerDropTarget.Middle },
		{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY = -56, Glyph = "DockContainer.DockTop",    Type = GCompute.DockContainerDropTarget.Top    },
		{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY =  56, Glyph = "DockContainer.DockBottom", Type = GCompute.DockContainerDropTarget.Bottom },
		{ FractionX = 0.5, FractionY = 0.5, OffsetX = -56, OffsetY =   0, Glyph = "DockContainer.DockLeft",   Type = GCompute.DockContainerDropTarget.Left   },
		{ FractionX = 0.5, FractionY = 0.5, OffsetX =  56, OffsetY =   0, Glyph = "DockContainer.DockRight",  Type = GCompute.DockContainerDropTarget.Right  }
	}
	self.RootDropData.Buttons =
	{
		{ FractionX = 0.5, FractionY = 0,   OffsetX =   0, OffsetY =  48, Glyph = "DockContainer.DockTop",    Type = GCompute.DockContainerDropTarget.Top    },
		{ FractionX = 0.5, FractionY = 1,   OffsetX =   0, OffsetY = -48, Glyph = "DockContainer.DockBottom", Type = GCompute.DockContainerDropTarget.Bottom },
		{ FractionX = 0,   FractionY = 0.5, OffsetX =  48, OffsetY =   0, Glyph = "DockContainer.DockLeft",   Type = GCompute.DockContainerDropTarget.Left   },
		{ FractionX = 1,   FractionY = 0.5, OffsetX = -48, OffsetY =   0, Glyph = "DockContainer.DockRight",  Type = GCompute.DockContainerDropTarget.Right  }
	}
	
	self.DragDropController = Gooey.DragDropController (self)
	self.DragDropController:SetDropTargetEnabled (true)
	self.DragDropController:SetDragRenderer (
		function (dragDropController, x, y)
			if not self:IsValid () then return end
			
			local viewContainer = self.DragDropController:GetObject ():GetContainer ()
			if not viewContainer or not viewContainer:IsValid () then return end
			
			local w, h = viewContainer:GetSize ()
			if w > ScrW () * 0.2 then
				h = h * ScrW () * 0.2 / w
				w = ScrW () * 0.2
			end
			if h > ScrH () * 0.2 then
				w = w * ScrH () * 0.2 / h
				h = ScrH () * 0.2
			end
			
			render.PushFilterMin (TEXFILTER.LINEAR)
			render.PushFilterMag (TEXFILTER.LINEAR)
			
			render.SetScissorRect (x, y, x + w, y + h, true)
			Gooey.RenderContext:PushViewPort (x, y, w * ScrW () / viewContainer:GetWide (), h * ScrH () / viewContainer:GetTall ())
			surface.SetAlphaMultiplier (0.9)
			viewContainer:PaintAt (0, 0)
			surface.SetAlphaMultiplier (1)
			Gooey.RenderContext:PopViewPort ()
			render.SetScissorRect (0, 0, 0, 0, false)
			
			render.PopFilterMin ()
			render.PopFilterMag ()
		end
	)
	self.DragDropController:SetDropRenderer (
		function (dragDropController, x, y)
			self:DrawDropOverlay (Gooey.RenderContext)
		end
	)
end

function PANEL:AddView (view)
	if not view then return end
	if self.LocalViewSet [view] then return end
	
	if next (self.LocalViewSet) and self.DockContainerType == GCompute.DockContainerType.View then
		self:SetContainerType (GCompute.DockContainerType.TabControl)
	end
	if self.DockContainerType == GCompute.DockContainerType.None then
		self:SetContainerType (GCompute.DockContainerType.View)
	end
	if self.DockContainerType ~= GCompute.DockContainerType.TabControl and
	   self.DockContainerType ~= GCompute.DockContainerType.View then
		GCompute.Error ("DockContainer:AddView : This DockContainer is not in tabcontrol or view mode!")
		return
	end
	
	local originalDockContainer = view:GetContainer ():GetDockContainer ()
	if originalDockContainer then
		originalDockContainer:RemoveView (view, GCompute.ViewRemovalReason.Rearrangement)
	end
	
	if self.DockContainerType == GCompute.DockContainerType.TabControl then
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
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
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
	
	if largestContainer:GetContainerType () == GCompute.DockContainerType.TabControl then
		if not largestContainer.Child then return nil end
		return largestContainer.Child:GetSelectedTab () and largestContainer.Child:GetSelectedTab ().View or nil
	elseif largestContainer:GetContainerType () == GCompute.DockContainerType.View then
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
	if self.DockContainerType == GCompute.DockContainerType.SplitContainer then
		local queryOrientation = Gooey.Orientation.Horizontal
		if dockingSide == GCompute.DockingSide.Left or
		   dockingSide == GCompute.DockingSide.Right then
			queryOrientation = Gooey.Orientation.Vertical
		end
		
		if self:GetOrientation () == queryOrientation then
			local childDockContainer
			if dockingSide == GCompute.DockingSide.Top or
			   dockingSide == GCompute.DockingSide.Left then
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
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
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
		if self.DockContainerType == GCompute.DockContainerType.SplitContainer then
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
	
	childDockContainerType = GCompute.DockContainerType.None
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
	if self.DockContainerType == GCompute.DockContainerType.SplitContainer then
		self:GetPanel1 ():PerformLayoutRecursive ()
		self:GetPanel2 ():PerformLayoutRecursive ()
	elseif self.DockContainerType == GCompute.DockContainerType.TabControl then
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
	elseif self.DockContainerType == GCompute.DockContainerType.View then
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
	
	if self.DockContainerType ~= GCompute.DockContainerType.TabControl and
	   self.DockContainerType ~= GCompute.DockContainerType.View then
		GCompute.Error ("DockContainer:RemoveView : This DockContainer is not in tabcontrol or view mode!")
	end
	
	if not self.LocalViewSet [view] then return end
	self:UnregisterLocalView (view)
	
	if self.DockContainerType == GCompute.DockContainerType.TabControl then
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
	if not GCompute.DockContainerType [dockContainerType] then
		GCompute.Error ("DockContainer:SetContainerType : Container type " .. dockContainerType .. " is not valid!")
		return
	end
	if self.DockContainerType == dockContainerType then return end
	
	local firstView = next (self.LocalViewSet)
	if dockContainerType ~= GCompute.DockContainerType.TabControl and
	   dockContainerType ~= GCompute.DockContainerType.View then
		firstView = nil
	end
	for view, _ in pairs (self.LocalViewSet) do
		self:RemoveView (view, view == firstView and GCompute.ViewRemovalReason.Conversion or GCompute.ViewRemovalReason.Removal)
	end
	
	if self.DockContainerType == GCompute.DockContainerType.TabControl then
		self:UnhookTabControl ()
	end
	
	if self.Child then
		self.Child:Remove ()
		self.Child = nil
	end
	
	self.DockContainerType = dockContainerType
	self.DragDropController:SetDropTargetEnabled (self:IsRootDockContainer ())
	
	if self.DockContainerType == GCompute.DockContainerType.None then
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainerType.View then
		self:AddView (firstView)
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainerType.TabControl then
		self.Child = vgui.Create ("GTabControl", self)
		self:HookTabControl ()
		self:AddView (firstView)
		self.DragDropController:SetDropTargetEnabled (true)
	elseif self.DockContainerType == GCompute.DockContainerType.SplitContainer then
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
		if childDockContainer.DockContainerType == GCompute.DockContainerType.SplitContainer then
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
	
	self.DockContainerType = GCompute.DockContainerType.SplitContainer
	self.DragDropController:SetDropTargetEnabled (self:IsRootDockContainer ())
	
	self.Child = vgui.Create ("GSplitContainer", self)
	
	if dockingSide == GCompute.DockingSide.Top or
	   dockingSide == GCompute.DockingSide.Bottom then
		self:SetOrientation (Gooey.Orientation.Horizontal)
	else
		self:SetOrientation (Gooey.Orientation.Vertical)
	end
	
	local otherDockContainer = vgui.Create ("GComputeDockContainer")
	if dockingSide == GCompute.DockingSide.Top or
	   dockingSide == GCompute.DockingSide.Left then
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
	if childDockContainer.Child and childDockContainer.DockContainerType == GCompute.DockContainerType.TabControl then
		GLib.CallDelayed (
			function ()
				if not childDockContainer then return end
				if not childDockContainer:IsValid () then return end
				if not childDockContainer.Child then return end
				if not childDockContainer.Child:IsValid () then return end
				if not childDockContainer.DockContainerType == GCompute.DockContainerType.TabControl then return end
				childDockContainer.Child:EnsureTabVisible (childDockContainer.Child:GetSelectedTab ())
			end
		)
	end
	
	self:GetRootDockContainer ():DispatchEvent ("ContainerSplit", self, childDockContainer, otherDockContainer)
	return otherDockContainer
end

function PANEL:ToString ()
	return self:GetPath () .. " [" .. tostring (self:GetTable ()) .. ": " .. GCompute.DockContainerType [self.DockContainerType] .. "]"
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
	if self.DockContainerType == GCompute.DockContainerType.None then
	elseif self.DockContainerType == GCompute.DockContainerType.SplitContainer then
		self:SetOrientation (inBuffer:UInt8 ())
		self.Child:SetSplitterFraction (inBuffer:UInt16 () / 32768)
		self:GetPanel1 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()), viewManager)
		self:GetPanel2 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()), viewManager)
	elseif self.DockContainerType == GCompute.DockContainerType.TabControl then
		local tabCount = inBuffer:UInt16 ()
		local selectedTabIndex = inBuffer:UInt16 ()
		for i = 1, tabCount do
			local view = viewManager:GetViewById (inBuffer:String ())
			self:AddView (view)
			if i == selectedTabIndex then
				view:GetContainer ():EnsureVisible ()
			end
		end
	elseif self.DockContainerType == GCompute.DockContainerType.View then
		self:SetView (viewManager:GetViewById (inBuffer:String ()))
	end
end

function PANEL:SaveSession (outBuffer)
	outBuffer:UInt8 (self.DockContainerType)
	if self.DockContainerType == GCompute.DockContainerType.None then
	elseif self.DockContainerType == GCompute.DockContainerType.SplitContainer then
		outBuffer:UInt8 (self:GetOrientation ())
		outBuffer:UInt16 (self.Child:GetSplitterFraction () * 32768)
		local subOutBuffer = GLib.StringOutBuffer ()
		self:GetPanel1 ():SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
		subOutBuffer:Clear ()
		self:GetPanel2 ():SaveSession (subOutBuffer)
		outBuffer:String (subOutBuffer:GetString ())
	elseif self.DockContainerType == GCompute.DockContainerType.TabControl then
		outBuffer:UInt16 (self.Child:GetTabCount ())
		outBuffer:UInt16 (self.Child:GetSelectedTabIndex ())
		for tab in self.Child:GetEnumerator () do
			outBuffer:String (tab.View:GetId ())
		end
	elseif self.DockContainerType == GCompute.DockContainerType.View then
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
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetPanel1 : This DockContainer is not in SplitContainer mode!")
		return nil
	end
	
	return self.Child:GetPanel1 ()
end

function PANEL:GetPanel2 ()
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetPanel2 : This DockContainer is not in SplitContainer mode!")
		return nil
	end
	
	return self.Child:GetPanel2 ()
end

function PANEL:GetOrientation ()
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:GetOrientation : This DockContainer is not in SplitContainer mode!")
		return Gooey.Orientation.Vertical
	end
	
	return self.Child:GetOrientation ()
end

function PANEL:SetOrientation (orientation)
	if self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		GCompute.Error ("DockContainer:SetOrientation : This DockContainer is not in SplitContainer mode!")
		return
	end
	
	self.Child:SetOrientation (orientation)
end

-- View
function PANEL:GetView ()
	if self.DockContainerType ~= GCompute.DockContainerType.View then
		GCompute.Error ("DockContainer:GetView : This DockContainer is not in view mode!")
	end
	return next (self.LocalViewSet)
end

function PANEL:SetView (view)
	if self.DockContainerType ~= GCompute.DockContainerType.View then
		GCompute.Error ("DockContainer:SetView : This DockContainer is not in view mode!")
	end
	
	if self:GetView () == view then return end
	self:RemoveView (self:GetView (), GCompute.ViewRemovalReason.Removal)
	self:AddView (view)
end

-- Internal, do not call
function PANEL:DoDragDrop (dragDropController, dropData)
	local view = dragDropController:GetObject ()
	local originalDockContainer = view:GetContainer ():GetDockContainer ()
	if dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.None then
		return
	elseif dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.Middle then
		self:AddView (view)
		self:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	else
		local dockingSide = nil
		if dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.Top then
			dockingSide = GCompute.DockingSide.Top
		elseif dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.Bottom then
			dockingSide = GCompute.DockingSide.Bottom
		elseif dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.Left then
			dockingSide = GCompute.DockingSide.Left
		elseif dropData.ActiveDropTarget == GCompute.DockContainerDropTarget.Right then
			dockingSide = GCompute.DockingSide.Right
		end
		
		-- Check if originalDockContainer needs to be fixed up
		if self == originalDockContainer then
			local otherDockContainer = self:Split (dockingSide, dropData.ActiveDropTargetFraction)
			if self:GetPanel1 () == otherDockContainer then
				originalDockContainer = self:GetPanel2 ()
			else
				originalDockContainer = self:GetPanel1 ()
			end
			otherDockContainer:AddView (view)
		else
			self:Split (dockingSide, dropData.ActiveDropTargetFraction):AddView (view)
		end
		self:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	end
	view:GetContainer ():Select ()
end

function PANEL:DrawDropOverlay (renderContext)
	local alphaScale
	if self.DropData.EnterTime > self.DropData.LeaveTime then
		alphaScale = math.min (1, (SysTime () - self.DropData.EnterTime) / 0.2)
	else
		alphaScale = math.max (0, 1 - (SysTime () - self.DropData.LeaveTime) / 0.2)
	end
	
	-- Draw rectangles
	renderContext:PushViewPort (self:LocalToScreen (0, 0))
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.max (  0, (1 - (SysTime () - self.DropData.ActiveDropTargetChangeTime) / 0.2) * 255), self.DropData.LastActiveDropTarget, self.DropData.LastActiveDropTargetFraction)
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.min (255,      (SysTime () - self.DropData.ActiveDropTargetChangeTime) / 0.2  * 255), self.DropData.ActiveDropTarget,     self.DropData.ActiveDropTargetFraction)
	renderContext:PopViewPort ()
	
	self:DrawRootDropOverlay (renderContext)
	
	if not self:IsRootDockContainer () or self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		renderContext:PushViewPort (self:LocalToScreen (0, 0))
		self:DrawDropTargets (renderContext, alphaScale, self.DropData)
		renderContext:PopViewPort ()
	end
end

local dropRectangleColor = Color (255, 255, 255, 255)
function PANEL:DrawDropRectangle (renderContext, alpha, dropTarget, dropFraction)
	local x = 0
	local y = 0
	local w = self:GetWide ()
	local h = self:GetTall ()
	if dropTarget == GCompute.DockContainerDropTarget.None then
		w = 0
		h = 0
	elseif dropTarget == GCompute.DockContainerDropTarget.Middle then
		if self.DockContainerType == GCompute.DockContainerType.TabControl then
			x, y, w, h = self.Child:GetPaddedContentRectangle ()
		end
	elseif dropTarget == GCompute.DockContainerDropTarget.Top then
		h = self:GetTall () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainerDropTarget.Bottom then
		y = self:GetTall () * dropFraction
		h = self:GetTall () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainerDropTarget.Left then
		w = self:GetWide () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainerDropTarget.Right then
		x = self:GetWide () * dropFraction
		w = self:GetWide () * (1 - dropFraction)
	end
	
	x = x + 4
	y = y + 4
	w = w - 8
	h = h - 8
	
	if w < 0 then w = 0 end
	if h < 0 then h = 0 end
	
	dropRectangleColor.r = GLib.Colors.CornflowerBlue.r
	dropRectangleColor.g = GLib.Colors.CornflowerBlue.g
	dropRectangleColor.b = GLib.Colors.CornflowerBlue.b
	dropRectangleColor.a = alpha
	draw.RoundedBox (math.min (16, math.floor (w / 4) * 2, math.floor (h / 4) * 2), x, y, w, h, dropRectangleColor)
end

local dropButtonColor = Color (216, 216, 216, 255)
function PANEL:DrawDropTargets (renderContext, alphaScale, dropData)
	-- Draw drop buttons
	if self:GetWide () < 160 or self:GetTall () < 160 then return end
	if self:GetContainerType () == GCompute.DockContainerType.None then return end
	
	local baseAlpha = 0.75
	local lastActiveButtonAlphaFraction = math.max (0, (1 - (SysTime () - dropData.ActiveDropButtonChangeTime) / 0.2))
	local activeButtonAlphaFraction     = math.min (1,      (SysTime () - dropData.ActiveDropButtonChangeTime) / 0.2)
	local lastActiveButtonAlpha = alphaScale * (baseAlpha + (1 - baseAlpha) * lastActiveButtonAlphaFraction)
	local activeButtonAlpha     = alphaScale * (baseAlpha + (1 - baseAlpha) * activeButtonAlphaFraction)
	
	local w = 48
	local h = 48
	for _, buttonData in ipairs (dropData.Buttons) do
		local x = buttonData.FractionX * self:GetWide () + buttonData.OffsetX
		local y = buttonData.FractionY * self:GetTall () + buttonData.OffsetY
		if buttonData.Type == dropData.LastActiveDropButton then
			surface.SetAlphaMultiplier (lastActiveButtonAlpha)
			dropButtonColor.a = 255 * lastActiveButtonAlpha
		elseif buttonData.Type == dropData.ActiveDropButton then
			surface.SetAlphaMultiplier (activeButtonAlpha)
			dropButtonColor.a = 255 * activeButtonAlpha
		else
			surface.SetAlphaMultiplier (baseAlpha * alphaScale)
			dropButtonColor.a = 255 * baseAlpha * alphaScale
		end
		Gooey.Glyphs.Draw (buttonData.Glyph, renderContext, dropButtonColor, x, y, w, h)
	end
	surface.SetAlphaMultiplier (1)
end

function PANEL:DrawRootDropOverlay (renderContext)
	if not self:IsRootDockContainer () then
		self:GetRootDockContainer ():DrawRootDropOverlay (renderContext)
		return
	end
	
	local alphaScale
	if self.RootDropData.EnterTime > self.RootDropData.LeaveTime then
		alphaScale = math.min (1, (SysTime () - self.RootDropData.EnterTime) / 0.2)
	else
		alphaScale = math.max (0, 1 - (SysTime () - self.RootDropData.LeaveTime) / 0.2)
	end
	
	-- Draw rectangles
	renderContext:PushViewPort (self:LocalToScreen (0, 0))
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.max (  0, (1 - (SysTime () - self.RootDropData.ActiveDropTargetChangeTime) / 0.2) * 255), self.RootDropData.LastActiveDropTarget, self.RootDropData.LastActiveDropTargetFraction)
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.min (255,      (SysTime () - self.RootDropData.ActiveDropTargetChangeTime) / 0.2  * 255), self.RootDropData.ActiveDropTarget,     self.RootDropData.ActiveDropTargetFraction)
	renderContext:PopViewPort ()
	
	renderContext:PushViewPort (self:LocalToScreen (0, 0))
	self:DrawDropTargets (renderContext, alphaScale, self.RootDropData)
	renderContext:PopViewPort ()
end

local function IsPointInButton (buttonX, buttonY, x, y)
	return x > buttonX - 24 and x < buttonX + 24 and
	       y > buttonY - 24 and y < buttonY + 24
end

function PANEL:DropButtonFromPoint (x, y, dropData)
	if self:GetWide () < 160 or self:GetTall () < 160 then return end
	if self:GetContainerType () == GCompute.DockContainerType.None then return end
	
	local centreX = self:GetWide () * 0.5
	local centreY = self:GetTall () * 0.5
	
	local dropButton = nil
	for _, buttonData in ipairs (dropData.Buttons) do
		if IsPointInButton (buttonData.FractionX * self:GetWide () + buttonData.OffsetX, buttonData.FractionY * self:GetTall () + buttonData.OffsetY, x, y) then
			dropButton = buttonData.Type
			break
		end
	end
	return dropButton
end

function PANEL:GetActiveDropButton ()
	return self.DropData.ActiveDropButton
end

function PANEL:GetActiveDropTarget ()
	return self.DropData.ActiveDropTarget
end

function PANEL:GetActiveRootDropButton ()
	return self.RootDropData.ActiveDropButton
end

function PANEL:GetActiveRootDropTarget ()
	return self.RootDropData.ActiveDropTarget
end

function PANEL:SetActiveDropButton (dockContainerDropTarget)
	if self.DropData.ActiveDropButton == dockContainerDropTarget then return end
	
	self.DropData.LastActiveDropButton       = self.ActiveDropButton
	self.DropData.ActiveDropButton           = dockContainerDropTarget
	self.DropData.ActiveDropButtonChangeTime = SysTime ()
end

function PANEL:SetActiveDropTarget (dropTarget, dropTargetFraction)
	if self.DropData.ActiveDropTarget == dropTarget and
	   self.DropData.ActiveDropTargetFraction == dropTargetFraction then
		return
	end
	
	self.DropData.LastActiveDropTarget         = self.DropData.ActiveDropTarget
	self.DropData.LastActiveDropTargetFraction = self.DropData.ActiveDropTargetFraction
	self.DropData.ActiveDropTarget             = dropTarget
	self.DropData.ActiveDropTargetFraction     = dropTargetFraction or 0.75
	self.DropData.ActiveDropTargetChangeTime   = SysTime ()
end

function PANEL:SetActiveRootDropButton (dockContainerRootDropTarget)
	if self.RootDropData.ActiveDropButton == dockContainerRootDropTarget then return end
	
	self.RootDropData.LastActiveDropButton       = self.RootDropData.ActiveDropButton
	self.RootDropData.ActiveDropButton           = dockContainerRootDropTarget
	self.RootDropData.ActiveDropButtonChangeTime = SysTime ()
end

function PANEL:SetActiveRootDropTarget (rootDropTarget, rootDropTargetFraction)
	if self.RootDropData.ActiveDropTarget == rootDropTarget and
	   self.RootDropData.ActiveDropTargetFraction == rootDropTargetFraction then
		return
	end
	
	self.RootDropData.LastActiveDropTarget         = self.RootDropData.ActiveDropTarget
	self.RootDropData.LastActiveDropTargetFraction = self.RootDropData.ActiveDropTargetFraction
	self.RootDropData.ActiveDropTarget             = rootDropTarget
	self.RootDropData.ActiveDropTargetFraction     = rootDropTargetFraction or 0.75
	self.RootDropData.ActiveDropTargetChangeTime   = SysTime ()
end

function PANEL:HookTabControl ()
	if self.DockContainerType ~= GCompute.DockContainerType.TabControl then return end
	
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
	if self.DockContainerType ~= GCompute.DockContainerType.TabControl then return end
	
	self.Child:RemoveEventListener ("ExternalTabDragStarted",  tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("SelectedContentsChanged", tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabAdded",                tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabCloseRequested",       tostring (self:GetTable ()))
	self.Child:RemoveEventListener ("TabRemoved",              tostring (self:GetTable ()))
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
function PANEL:OnDragDrop (dragDropController)
	self:GetRootDockContainer ():OnRootDragDrop (dragDropController)
	
	self:DoDragDrop (dragDropController, self.DropData)
	
	self:SetActiveDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainerDropTarget.None)
end

function PANEL:OnDragEnter (dragDropController, oldDropPanel)
	if not oldDropPanel or oldDropPanel.ClassName ~= self.ClassName or oldDropPanel:GetRootDockContainer () ~= self:GetRootDockContainer () then
		self:GetRootDockContainer ():OnRootDragEnter (dragDropController)
	end
	self.DropData.EnterTime = SysTime ()
	
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
end

function PANEL:OnDragLeave (dragDropController, newDropPanel)
	if not newDropPanel or newDropPanel.ClassName ~= self.ClassName or newDropPanel:GetRootDockContainer () ~= self:GetRootDockContainer () then
		self:GetRootDockContainer ():OnRootDragLeave (dragDropController)
	end
	self:SetActiveDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainerDropTarget.None)
	
	self.DropData.LeaveTime = SysTime ()
	
	Gooey.AddRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()),
		function ()
			if not self:IsValid () then return end
			
			self:DrawDropOverlay (Gooey.RenderContext)
			if SysTime () - self.DropData.LeaveTime > 1 then
				Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
			end
		end
	)
end

function PANEL:OnDragOver (dragDropController, x, y)
	self:GetRootDockContainer ():OnRootDragOver (dragDropController)
	if self:GetRootDockContainer ():GetActiveRootDropButton () ~= GCompute.DockContainerDropTarget.None then
		self:SetActiveDropButton (GCompute.DockContainerDropTarget.None)
		self:SetActiveDropTarget (GCompute.DockContainerDropTarget.None)
		return
	end
	
	local dropButton = nil
	local dropTarget = nil
	local dropTargetFraction = 0.75
	
	-- Our drop targets
	if not self:IsRootDockContainer () or
	   self:GetContainerType () ~= GCompute.DockContainerType.SplitContainer then
		dropButton = self:DropButtonFromPoint (x, y, self.DropData)
		if dropButton then
			dropTarget = dropButton
			local hasDocument      = self:GetLargestView () and self:GetLargestView ():GetDocument () and true or false
			local otherHasDocument = dragDropController:GetObject ():GetDocument () and true or false
			
			if hasDocument == otherHasDocument then
				dropTargetFraction = 0.5
			elseif hasDocument then
				dropTargetFraction = 0.75
			else
				dropTargetFraction = 0.25
			end
		end
		
		-- Drops on empty containers always hit the middle drop target
		if self:GetContainerType () == GCompute.DockContainerType.None then
			dropTarget = GCompute.DockContainerDropTarget.Middle
		end
		
		-- Drops on the tab header section of tab control containers
		-- always hit the middle drop target
		if self:GetContainerType () == GCompute.DockContainerType.TabControl and
		   self.Child:IsPointInHeaderArea (x, y) then
			dropTarget = GCompute.DockContainerDropTarget.Middle
		end
		
		-- Identify the area drop target
		if not dropTarget then
			local normalizedX = x / self:GetWide ()
			local normalizedY = y / self:GetTall ()
			if normalizedX < 0.25 then
				dropTarget = GCompute.DockContainerDropTarget.Left
			elseif normalizedX > 0.75 then
				dropTarget = GCompute.DockContainerDropTarget.Right
			end
			if normalizedY < 0.25 then
				dropTarget = GCompute.DockContainerDropTarget.Top
			elseif normalizedY > 0.75 then
				dropTarget = GCompute.DockContainerDropTarget.Bottom
			end
		end
		dropButton = dropButton or GCompute.DockContainerDropTarget.None
		dropTarget = dropTarget or GCompute.DockContainerDropTarget.Middle
	end
	self:SetActiveDropButton (dropButton or GCompute.DockContainerDropTarget.None)
	self:SetActiveDropTarget (dropTarget or GCompute.DockContainerDropTarget.None, dropTargetFraction)
end

function PANEL:OnRootDragDrop (dragDropController)
	self:DoDragDrop (dragDropController, self.RootDropData)
	
	self:SetActiveRootDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveRootDropTarget (GCompute.DockContainerDropTarget.None)
end

function PANEL:OnRootDragEnter (dragDropController)
	self.RootDropData.EnterTime = SysTime ()
end

function PANEL:OnRootDragLeave (dragDropController)
	self:SetActiveRootDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveRootDropTarget (GCompute.DockContainerDropTarget.None)
	
	self.RootDropData.LeaveTime = SysTime ()
end

function PANEL:OnRootDragOver (dragDropController)
	local x, y = self:CursorPos ()
	local dropButton = nil
	local dropTarget = nil
	local dropTargetFraction = 0.75
	
	-- Our drop targets
	dropButton = self:DropButtonFromPoint (x, y, self.RootDropData)
	if dropButton then
		dropTarget = dropButton
		local hasDocument      = self:GetLargestView () and self:GetLargestView ():GetDocument () and true or false
		local otherHasDocument = dragDropController:GetObject ():GetDocument () and true or false
		
		if hasDocument == otherHasDocument then
			dropTargetFraction = 0.5
		elseif hasDocument then
			dropTargetFraction = 0.75
		else
			dropTargetFraction = 0.25
		end
	end
	self:SetActiveRootDropButton (dropButton or GCompute.DockContainerDropTarget.None)
	self:SetActiveRootDropTarget (dropTarget or GCompute.DockContainerDropTarget.None, dropTargetFraction)
end

function PANEL:OnRemoved ()
	self.DragDropController:EndDrag ()
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
	
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
		if activePanel:GetContainerType () == GCompute.DockContainerType.TabControl then
			local selectedTab = activePanel.Child:GetSelectedTab ()
			self:SetActiveView (selectedTab and selectedTab.View)
		elseif activePanel:GetContainerType () == GCompute.DockContainerType.View then
			self:SetActiveView (activePanel:GetView ())
		end
	end
	
end

Gooey.Register ("GComputeDockContainer", PANEL, "GPanel")