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
	self.ViewSet    = {}
	self.ViewsById  = {}
	self.NextViewId = 0
	
	self.ActiveView = nil
	
	-- TabControl
	self.LocalViewSet   = {}
	self.LocalViewsById = {}
	self.LocalViewCount = 0
	
	-- Drag and drop
	self.DropButtons =
	{
		{ X =   0, Y =   0, Glyph = "DockContainer.DockMiddle", Type = GCompute.DockContainerDropTarget.Middle },
		{ X =   0, Y = -56, Glyph = "DockContainer.DockTop",    Type = GCompute.DockContainerDropTarget.Top    },
		{ X =   0, Y =  56, Glyph = "DockContainer.DockBottom", Type = GCompute.DockContainerDropTarget.Bottom },
		{ X = -56, Y =   0, Glyph = "DockContainer.DockLeft",   Type = GCompute.DockContainerDropTarget.Left   },
		{ X =  56, Y =   0, Glyph = "DockContainer.DockRight",  Type = GCompute.DockContainerDropTarget.Right  }
	}
	
	self.DragEnterTime = 0
	self.DragLeaveTime = 0
	
	self.LastActiveDropTarget         = GCompute.DockContainerDropTarget.None
	self.LastActiveDropTargetFraction = 0.75
	
	self.ActiveDropTarget             = GCompute.DockContainerDropTarget.None
	self.ActiveDropTargetFraction     = 0.75
	self.ActiveDropTargetChangeTime   = 0
	
	self.LastActiveDropButton         = GCompute.DockContainerDropTarget.None
	self.ActiveDropButton             = GCompute.DockContainerDropTarget.None
	self.ActiveDropButtonChangeTime   = 0
	
	self.DragDropController = Gooey.DragDropController (self)
	self.DragDropController:SetDragRenderer (
		function (dragDropController, x, y)
			if not self:IsValid () then return end
			
			local viewContainer = self.DragDropController:GetObject ():GetContainer ()
			if not viewContainer or not viewContainer:IsValid () then return end
			
			local w = 256
			local h = 256
			render.SetScissorRect (x, y, x + viewContainer:GetWide () / ScrW () * w, y + viewContainer:GetTall () / ScrH () * h, true)
			Gooey.RenderContext:PushViewPort (x, y, w, h)
			surface.SetAlphaMultiplier (0.9)
			viewContainer:PaintAt (0, 0)
			surface.SetAlphaMultiplier (1)
			Gooey.RenderContext:PopViewPort ()
			render.SetScissorRect (0, 0, 0, 0, false)
		end
	)
	self.DragDropController:SetDropRenderer (
		function (dragDropController, x, y)
			self:DrawDropOverlay ()
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
	
	if view:GetContainer ():GetDockContainer () then
		view:GetContainer ():GetDockContainer ():RemoveView (view, GCompute.ViewRemovalReason.Rearrangement)
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
	
	self:GetRootDockContainer ():DispatchEvent ("ViewMoved", view)
end

function PANEL:GenerateViewId ()
	while self.ViewsById [tostring (self.NextViewId)] do
		self.NextViewId = self.NextViewId + 1
	end
	self.NextViewId = self.NextViewId + 1
	return tostring (self.NextViewId - 1)
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
	local panel2 = self:GetPanel1 ():GetLargestContainer ()
	if panel1:GetWide () * panel1:GetTall () > panel2:GetWide () * panel2:GetTall () then
		return panel1
	end
	return panel2
end

function PANEL:GetLargestView ()
	local largestContainer = self:GetLargestContainer ()
	if not largestContainer then return nil end
	
	if largestContainer:GetContainerType () == GCompute.DockContainerType.TabControl then
		if not self.Child then return nil end
		return self.Child:GetSelectedTab () and self.Child:GetSelectedTab ().View or nil
	elseif largestContainer:GetContainerType () == GCompute.DockContainerType.View then
		return self:GetView ()
	end
	return nil
end

function PANEL:GetLocalViewCount ()
	return self.LocalViewCount
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

function PANEL:GetViewById (id)
	if not self:IsRootDockContainer () then
		return self:GetRootDockContainer ():GetViewById (id)
	end
	return self.ViewsById [id]
end

function PANEL:GetViewEnumerator ()
	if not self:IsRootDockContainer () then
		return self:GetRootDockContainer ():GetViewEnumerator ()
	end
	
	local next, tbl, key = pairs (self.ViewSet)
	return function ()
		key = next (tbl, key)
		return key
	end
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
			if contents and contents:IsValid () then
				contents:PerformLayout ()
			end
		end
	elseif self.DockContainerType == GCompute.DockContainerType.View then
		local container = self:GetView () and self:GetView ():GetContainer ()
		local contents = container and container:GetContents () or nil
		if contents and contents:IsValid () then
			contents:PerformLayout ()
		end
	end
end

function PANEL:RegisterLocalView (view)
	if not view then return end
	if self.LocalViewSet [view] then return end
	self:RegisterView (view)
	
	self.LocalViewSet [view] = true
	self.LocalViewsById [view:GetId ()] = view
	self.LocalViewCount = self.LocalViewCount + 1
end

function PANEL:RegisterView (view)
	if not view then return end
	if not self:IsRootDockContainer () then
		self:GetRootDockContainer ():RegisterView (view)
		return
	end
	if self.ViewSet [view] then return end
	
	self.ViewSet [view] = true
	if not view:GetId () then
		view:SetId (self:GenerateViewId (view))
	end
	self.ViewsById [view:GetId ()] = view
	
	self:DispatchEvent ("ViewRegistered", view)
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
		view:GetContainer ():SetParent (nil)
		self.Child = nil
	end
	view:GetContainer ():SetDockContainer (nil)
	view:GetContainer ():SetVisible (false)
	self:UnhookView (view)
	
	if self:GetActiveView () == view then
		self:SetActiveView (nil)
	end
	
	self:GetRootDockContainer ():DispatchEvent ("ViewRemoved", self, view, viewRemovalReason or GCompute.ViewRemovalReason.Removal)
end

function PANEL:SetActiveView (view)
	if not self:IsRootDockContainer () then
		self:GetRootDockContainer ():SetActiveView (view)
		return
	end
	
	if view and not self.ViewSet [view] then return end
	if self.ActiveView == view then return end
	
	local oldSelectedView = self.ActiveView
	self.ActiveView = view
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
	
	if childDockContainer.Child and childDockContainer.DockContainerType == GCompute.DockContainerType.TabControl then
		timer.Simple (0.050,
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
	self:PerformLayoutRecursive ()
	
	self:GetRootDockContainer ():DispatchEvent ("ContainerSplit", self, childDockContainer, otherDockContainer)
	return otherDockContainer
end

function PANEL:UnregisterLocalView (view)
	if not self.LocalViewSet [view] then return end
	
	self.LocalViewSet [view] = nil
	self.LocalViewsById [view:GetId ()] = nil
	self.LocalViewCount = self.LocalViewCount - 1
end

function PANEL:UnregisterView (view)
	if not self:IsRootDockContainer () then
		self:GetRootDockContainer ():UnregisterView (view)
		return
	end
	if not self.ViewSet [view] then return end
	
	self.ViewSet [view] = nil
	self.ViewsById [view:GetId ()] = nil
	
	self:DispatchEvent ("ViewUnregistered", view)
end

-- Persistance
function PANEL:LoadSession (inBuffer)
	local dockContainerType = inBuffer:UInt8 ()
	self:SetContainerType (dockContainerType)
	if self.DockContainerType == GCompute.DockContainerType.None then
	elseif self.DockContainerType == GCompute.DockContainerType.SplitContainer then
		self:SetOrientation (inBuffer:UInt8 ())
		self.Child:SetSplitterFraction (inBuffer:UInt16 () / 32768)
		self:GetPanel1 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()))
		self:GetPanel2 ():LoadSession (GLib.StringInBuffer (inBuffer:String ()))
	elseif self.DockContainerType == GCompute.DockContainerType.TabControl then
		local tabCount = inBuffer:UInt16 ()
		local selectedTabIndex = inBuffer:UInt16 ()
		for i = 1, tabCount do
			local view = self:GetViewById (inBuffer:String ())
			self:AddView (view)
			if i == selectedTabIndex then
				view:GetContainer ():Select ()
			end
		end
	elseif self.DockContainerType == GCompute.DockContainerType.View then
		self:SetView (self:GetViewById (inBuffer:String ()))
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
function PANEL:DrawDropOverlay ()
	local renderContext = Gooey.RenderContext
	
	local alphaScale
	if self.DragEnterTime > self.DragLeaveTime then
		alphaScale = math.min (1, (SysTime () - self.DragEnterTime) / 0.2)
	else
		alphaScale = math.max (0, 1 - (SysTime () - self.DragLeaveTime) / 0.2)
	end
	
	renderContext:PushViewPort (self:LocalToScreen (0, 0))
	
	self:DrawDropTargets (renderContext, alphaScale)
	
	renderContext:PopViewPort ()
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
	draw.RoundedBox (math.min (16, w / 2, h / 2), x, y, w, h, dropRectangleColor)
end

local dropButtonColor = Color (255, 255, 255, 255)
function PANEL:DrawDropTargets (renderContext, alphaScale)
	-- Draw rectangles
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.max (0, (1 - (SysTime () - self.ActiveDropTargetChangeTime) / 0.2) * 255), self.LastActiveDropTarget, self.LastActiveDropTargetFraction)
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.min (255, (SysTime () - self.ActiveDropTargetChangeTime) / 0.2 * 255), self.ActiveDropTarget, self.ActiveDropTargetFraction)
	
	-- Draw drop buttons
	if self:IsRootDockContainer () and self.DockContainerType == GCompute.DockContainerType.SplitContainer then return end
	
	if self:GetWide () < 160 or self:GetTall () < 160 then return end
	
	local lastActiveButtonAlphaFraction = math.max (0, (1 - (SysTime () - self.ActiveDropButtonChangeTime) / 0.2))
	local activeButtonAlphaFraction     = math.min (1, (SysTime () - self.ActiveDropButtonChangeTime) / 0.2)
	local lastActiveButtonAlpha = alphaScale * (0.7 + 0.3 * lastActiveButtonAlphaFraction)
	local activeButtonAlpha     = alphaScale * (0.7 + 0.3 * activeButtonAlphaFraction)
	
	dropButtonColor.r = GLib.Colors.Silver.r
	dropButtonColor.g = GLib.Colors.Silver.g
	dropButtonColor.b = GLib.Colors.Silver.b
	local centreX = self:GetWide () * 0.5
	local centreY = self:GetTall () * 0.5
	local w = 48
	local h = 48
	for _, buttonData in ipairs (self.DropButtons) do
		local x = centreX + buttonData.X
		local y = centreY + buttonData.Y
		if buttonData.Type == self.LastActiveDropButton then
			surface.SetAlphaMultiplier (lastActiveButtonAlpha)
			dropButtonColor.a = 255 * lastActiveButtonAlpha
		elseif buttonData.Type == self.ActiveDropButton then
			surface.SetAlphaMultiplier (activeButtonAlpha)
			dropButtonColor.a = 255 * activeButtonAlpha
		else
			surface.SetAlphaMultiplier (0.7 * alphaScale)
			dropButtonColor.a = 255 * 0.7 * alphaScale
		end
		Gooey.Glyphs.Draw (buttonData.Glyph, renderContext, dropButtonColor, x, y, w, h)
	end
	surface.SetAlphaMultiplier (1)
end

local function IsPointInButton (buttonX, buttonY, x, y)
	return x > buttonX - 24 and x < buttonX + 24 and
	       y > buttonY - 24 and y < buttonY + 24
end

function PANEL:DropButtonFromPoint (x, y)
	if self:GetWide () < 160 or self:GetTall () < 160 then return end
	
	local centreX = self:GetWide () * 0.5
	local centreY = self:GetTall () * 0.5
	
	local dropButton = nil
	for _, buttonData in ipairs (self.DropButtons) do
		if IsPointInButton (centreX + buttonData.X, centreY + buttonData.Y, x, y) then
			dropButton = buttonData.Type
			break
		end
	end
	return dropButton
end

function PANEL:GetActiveDropButton ()
	return self.ActiveDropButton
end

function PANEL:GetActiveDropTarget ()
	return self.ActiveDropTarget
end

function PANEL:SetActiveDropButton (dockContainerDropTarget)
	if self.ActiveDropButton == dockContainerDropTarget then return end
	
	self.LastActiveDropButton = self.ActiveDropButton
	self.ActiveDropButton = dockContainerDropTarget
	self.ActiveDropButtonChangeTime = SysTime ()
end

function PANEL:SetActiveDropTarget (dropTarget, dropTargetFraction)
	if self.ActiveDropTarget == dropTarget then return end
	
	self.LastActiveDropTarget         = self.ActiveDropTarget
	self.LastActiveDropTargetFraction = self.ActiveDropTargetFraction
	self.ActiveDropTarget             = dropTarget
	self.ActiveDropTargetFraction     = dropTargetFraction or 0.75
	self.ActiveDropTargetChangeTime = SysTime ()
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
			self:UnregisterView (tab.View)
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
end

function PANEL:UnhookView (view)
	if not view then return end
	
	view:RemoveEventListener ("IconChanged",        tostring (self:GetTable ()))
	view:RemoveEventListener ("TitleChanged",       tostring (self:GetTable ()))
	view:RemoveEventListener ("ToolTipTextChanged", tostring (self:GetTable ()))
end

-- Event handlers
function PANEL:OnDragDrop (dragDropController)
	local view = dragDropController:GetObject ()
	local originalDockContainer = view:GetContainer ():GetDockContainer ()
	if self.ActiveDropTarget == GCompute.DockContainerDropTarget.None then
	elseif self.ActiveDropTarget == GCompute.DockContainerDropTarget.Middle then
		self:AddView (view)
		self:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	else
		local dockingSide = nil
		if self.ActiveDropTarget == GCompute.DockContainerDropTarget.Top then
			dockingSide = GCompute.DockingSide.Top
		elseif self.ActiveDropTarget == GCompute.DockContainerDropTarget.Bottom then
			dockingSide = GCompute.DockingSide.Bottom
		elseif self.ActiveDropTarget == GCompute.DockContainerDropTarget.Left then
			dockingSide = GCompute.DockingSide.Left
		elseif self.ActiveDropTarget == GCompute.DockContainerDropTarget.Right then
			dockingSide = GCompute.DockingSide.Right
		end
		if self == originalDockContainer then
			local otherDockContainer = self:Split (dockingSide, self.ActiveDropTargetFraction)
			if self:GetPanel1 () == otherDockContainer then
				originalDockContainer = self:GetPanel2 ()
			else
				originalDockContainer = self:GetPanel1 ()
			end
			otherDockContainer:AddView (view)
		else
			self:Split (dockingSide, self.ActiveDropTargetFraction):AddView (view)
		end
		self:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	end
	view:GetContainer ():Select ()
	
	self:SetActiveDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainerDropTarget.None)
end

function PANEL:OnDragEnter (dragDropController)
	self.DragEnterTime = SysTime ()
	
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
end

function PANEL:OnDragLeave (dragDropController)
	self:SetActiveDropButton (GCompute.DockContainerDropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainerDropTarget.None)
	
	self.DragLeaveTime = SysTime ()
	
	Gooey.AddRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()),
		function ()
			if not self:IsValid () then return end
			
			self:DrawDropOverlay ()
			if SysTime () - self.DragLeaveTime > 1 then
				Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
			end
		end
	)
end

function PANEL:OnDragOver (dragDropController, x, y)
	local dropButton = nil
	local dropTarget = nil
	local dropTargetFraction = 0.75
	
	if not self:IsRootDockContainer () or
	   self.DockContainerType ~= GCompute.DockContainerType.SplitContainer then
		dropButton = self:DropButtonFromPoint (x, y)
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
		
		local normalizedX = x / self:GetWide ()
		local normalizedY = y / self:GetTall ()
		if not dropTarget then
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

function PANEL:OnRemoved ()
	self.DragDropController:EndDrag ()
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. tostring (self:GetTable ()))
	
	if self:IsRootDockContainer () then
		for view, _ in pairs (self.ViewSet) do
			view:dtor ()
		end
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
	if vgui.FocusedHasParent (self) then
		while activePanel and activePanel:IsValid () and activePanel.ClassName ~= self.ClassName do
			activePanel = activePanel:GetParent ()
		end
		if not activePanel or not activePanel:IsValid () then return end
		if activePanel:GetRootDockContainer () ~= self then return end
		if activePanel:GetContainerType () == GCompute.DockContainerType.TabControl then
			self:SetActiveView (activePanel.Child:GetSelectedTab ().View)
		elseif activePanel:GetContainerType () == GCompute.DockContainerType.View then
			self:SetActiveView (activePanel:GetView ())
		end
	end
	
end

Gooey.Register ("GComputeDockContainer", PANEL, "GPanel")