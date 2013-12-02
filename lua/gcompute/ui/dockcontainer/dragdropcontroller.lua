local self = {}
GCompute.DockContainer.DragDropController = GCompute.MakeConstructor (self, Gooey.DragDropController)

local dropButtons =
{
	{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY =   0, Glyph = "DockContainer.DockMiddle", Type = GCompute.DockContainer.DropTarget.Middle },
	{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY = -56, Glyph = "DockContainer.DockTop",    Type = GCompute.DockContainer.DropTarget.Top    },
	{ FractionX = 0.5, FractionY = 0.5, OffsetX =   0, OffsetY =  56, Glyph = "DockContainer.DockBottom", Type = GCompute.DockContainer.DropTarget.Bottom },
	{ FractionX = 0.5, FractionY = 0.5, OffsetX = -56, OffsetY =   0, Glyph = "DockContainer.DockLeft",   Type = GCompute.DockContainer.DropTarget.Left   },
	{ FractionX = 0.5, FractionY = 0.5, OffsetX =  56, OffsetY =   0, Glyph = "DockContainer.DockRight",  Type = GCompute.DockContainer.DropTarget.Right  }
}

local rootDropButtons =
{
	{ FractionX = 0.5, FractionY = 0,   OffsetX =   0, OffsetY =  48, Glyph = "DockContainer.DockTop",    Type = GCompute.DockContainer.DropTarget.Top    },
	{ FractionX = 0.5, FractionY = 1,   OffsetX =   0, OffsetY = -48, Glyph = "DockContainer.DockBottom", Type = GCompute.DockContainer.DropTarget.Bottom },
	{ FractionX = 0,   FractionY = 0.5, OffsetX =  48, OffsetY =   0, Glyph = "DockContainer.DockLeft",   Type = GCompute.DockContainer.DropTarget.Left   },
	{ FractionX = 1,   FractionY = 0.5, OffsetX = -48, OffsetY =   0, Glyph = "DockContainer.DockRight",  Type = GCompute.DockContainer.DropTarget.Right  }
}

function self:ctor (control)
	self.DropData =
	{
		EnterTime = 0,
		LeaveTime = 0,
		
		LastActiveDropTarget         = GCompute.DockContainer.DropTarget.None,
		LastActiveDropTargetFraction = 0.75,
		
		ActiveDropTarget             = GCompute.DockContainer.DropTarget.None,
		ActiveDropTargetFraction     = 0.75,
		ActiveDropTargetChangeTime   = 0,
		
		LastActiveDropButton         = GCompute.DockContainer.DropTarget.None,
		ActiveDropButton             = GCompute.DockContainer.DropTarget.None,
		ActiveDropButtonChangeTime   = 0
	}
	self.RootDropData = table.Copy (self.DropData)
	self.DropData.Buttons = dropButtons
	self.RootDropData.Buttons = rootDropButtons
	
	self:SetDragRenderer (
		function (dragDropController, x, y)
			local viewContainer = self:GetObject ():GetContainer ()
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
	self:SetDropRenderer (
		function (dragDropController, x, y)
			self:DrawDropOverlay (Gooey.RenderContext)
		end
	)
end

-- Internal, do not call
function self:DoDragDrop (control, dragDropController, dropData)
	local view = dragDropController:GetObject ()
	
	if not view then return end
	if not view:GetContainer () then return end
	if not view:GetContainer ():IsValid () then return end
	
	local originalDockContainer = view:GetContainer ():GetDockContainer ()
	if dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.None then
		return
	elseif dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.Middle then
		control:AddView (view)
		control:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	else
		local dockingSide = nil
		if dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.Top then
			dockingSide = GCompute.DockContainer.DockingSide.Top
		elseif dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.Bottom then
			dockingSide = GCompute.DockContainer.DockingSide.Bottom
		elseif dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.Left then
			dockingSide = GCompute.DockContainer.DockingSide.Left
		elseif dropData.ActiveDropTarget == GCompute.DockContainer.DropTarget.Right then
			dockingSide = GCompute.DockContainer.DockingSide.Right
		end
		
		-- Check if originalDockContainer needs to be fixed up
		if control == originalDockContainer then
			local otherDockContainer = control:Split (dockingSide, dropData.ActiveDropTargetFraction)
			if control:GetPanel1 () == otherDockContainer then
				originalDockContainer = control:GetPanel2 ()
			else
				originalDockContainer = control:GetPanel1 ()
			end
			otherDockContainer:AddView (view)
		else
			control:Split (dockingSide, dropData.ActiveDropTargetFraction):AddView (view)
		end
		control:GetRootDockContainer ():DispatchEvent ("ViewDropped", view, originalDockContainer, view:GetContainer ():GetDockContainer ())
	end
	view:GetContainer ():Select ()
end

-- Drop Targets
local function IsPointInButton (buttonX, buttonY, x, y)
	return x > buttonX - 24 and x < buttonX + 24 and
	       y > buttonY - 24 and y < buttonY + 24
end

function self:DropButtonFromPoint (x, y, dropData)
	if self.Control:GetWide () < 160 or self.Control:GetTall () < 160 then return end
	if self.Control:GetContainerType () == GCompute.DockContainer.DockContainerType.None then return end
	
	local centreX = self.Control:GetWide () * 0.5
	local centreY = self.Control:GetTall () * 0.5
	
	local dropButton = nil
	for _, buttonData in ipairs (dropData.Buttons) do
		if IsPointInButton (buttonData.FractionX * self.Control:GetWide () + buttonData.OffsetX, buttonData.FractionY * self.Control:GetTall () + buttonData.OffsetY, x, y) then
			dropButton = buttonData.Type
			break
		end
	end
	return dropButton
end

function self:GetActiveDropButton ()
	return self.DropData.ActiveDropButton
end

function self:GetActiveDropTarget ()
	return self.DropData.ActiveDropTarget
end

function self:GetActiveRootDropButton ()
	return self.RootDropData.ActiveDropButton
end

function self:GetActiveRootDropTarget ()
	return self.RootDropData.ActiveDropTarget
end

function self:SetActiveDropButton (dockContainerDropTarget)
	if self.DropData.ActiveDropButton == dockContainerDropTarget then return end
	
	self.DropData.LastActiveDropButton       = self.ActiveDropButton
	self.DropData.ActiveDropButton           = dockContainerDropTarget
	self.DropData.ActiveDropButtonChangeTime = SysTime ()
end

function self:SetActiveDropTarget (dropTarget, dropTargetFraction)
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

function self:SetActiveRootDropButton (dockContainerRootDropTarget)
	if self.RootDropData.ActiveDropButton == dockContainerRootDropTarget then return end
	
	self.RootDropData.LastActiveDropButton       = self.RootDropData.ActiveDropButton
	self.RootDropData.ActiveDropButton           = dockContainerRootDropTarget
	self.RootDropData.ActiveDropButtonChangeTime = SysTime ()
end

function self:SetActiveRootDropTarget (rootDropTarget, rootDropTargetFraction)
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

-- Root
function self:GetRootDragDropController ()
	if not self.Control then return nil end
	if self.Control:IsRootDockContainer () then return self end
	return self.Control:GetRootDockContainer ().DragDropController
end

-- Rendering
function self:DrawDropOverlay (renderContext)
	local alphaScale
	if self.DropData.EnterTime > self.DropData.LeaveTime then
		alphaScale = math.min (1, (SysTime () - self.DropData.EnterTime) / 0.2)
	else
		alphaScale = math.max (0, 1 - (SysTime () - self.DropData.LeaveTime) / 0.2)
	end
	
	-- Draw rectangles
	renderContext:PushViewPort (self.Control:LocalToScreen (0, 0))
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.max (  0, (1 - (SysTime () - self.DropData.ActiveDropTargetChangeTime) / 0.2) * 255), self.DropData.LastActiveDropTarget, self.DropData.LastActiveDropTargetFraction)
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.min (255,      (SysTime () - self.DropData.ActiveDropTargetChangeTime) / 0.2  * 255), self.DropData.ActiveDropTarget,     self.DropData.ActiveDropTargetFraction)
	renderContext:PopViewPort ()
	
	self:DrawRootDropOverlay (renderContext)
	
	if not self.Control:IsRootDockContainer () or self.Control:GetContainerType () ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		renderContext:PushViewPort (self.Control:LocalToScreen (0, 0))
		self:DrawDropTargets (renderContext, alphaScale, self.DropData)
		renderContext:PopViewPort ()
	end
end

local dropRectangleColor = Color (255, 255, 255, 255)
function self:DrawDropRectangle (renderContext, alpha, dropTarget, dropFraction)
	local x = 0
	local y = 0
	local w = self.Control:GetWide ()
	local h = self.Control:GetTall ()
	if dropTarget == GCompute.DockContainer.DropTarget.None then
		w = 0
		h = 0
	elseif dropTarget == GCompute.DockContainer.DropTarget.Middle then
		if self.Control:GetContainerType () == GCompute.DockContainer.DockContainerType.TabControl then
			x, y, w, h = self.Control.Child:GetPaddedContentRectangle ()
		end
	elseif dropTarget == GCompute.DockContainer.DropTarget.Top then
		h = self.Control:GetTall () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainer.DropTarget.Bottom then
		y = self.Control:GetTall () * dropFraction
		h = self.Control:GetTall () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainer.DropTarget.Left then
		w = self.Control:GetWide () * (1 - dropFraction)
	elseif dropTarget == GCompute.DockContainer.DropTarget.Right then
		x = self.Control:GetWide () * dropFraction
		w = self.Control:GetWide () * (1 - dropFraction)
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
function self:DrawDropTargets (renderContext, alphaScale, dropData)
	-- Draw drop buttons
	if self.Control:GetWide () < 160 or self.Control:GetTall () < 160 then return end
	if self.Control:GetContainerType () == GCompute.DockContainer.DockContainerType.None then return end
	
	local baseAlpha = 0.75
	local lastActiveButtonAlphaFraction = math.max (0, (1 - (SysTime () - dropData.ActiveDropButtonChangeTime) / 0.2))
	local activeButtonAlphaFraction     = math.min (1,      (SysTime () - dropData.ActiveDropButtonChangeTime) / 0.2)
	local lastActiveButtonAlpha = alphaScale * (baseAlpha + (1 - baseAlpha) * lastActiveButtonAlphaFraction)
	local activeButtonAlpha     = alphaScale * (baseAlpha + (1 - baseAlpha) * activeButtonAlphaFraction)
	
	local w = 48
	local h = 48
	for _, buttonData in ipairs (dropData.Buttons) do
		local x = buttonData.FractionX * self.Control:GetWide () + buttonData.OffsetX
		local y = buttonData.FractionY * self.Control:GetTall () + buttonData.OffsetY
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

function self:DrawRootDropOverlay (renderContext)
	if not self.Control:IsRootDockContainer () then
		self:GetRootDragDropController ():DrawRootDropOverlay (renderContext)
		return
	end
	
	local alphaScale
	if self.RootDropData.EnterTime > self.RootDropData.LeaveTime then
		alphaScale = math.min (1, (SysTime () - self.RootDropData.EnterTime) / 0.2)
	else
		alphaScale = math.max (0, 1 - (SysTime () - self.RootDropData.LeaveTime) / 0.2)
	end
	
	-- Draw rectangles
	renderContext:PushViewPort (self.Control:LocalToScreen (0, 0))
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.max (  0, (1 - (SysTime () - self.RootDropData.ActiveDropTargetChangeTime) / 0.2) * 255), self.RootDropData.LastActiveDropTarget, self.RootDropData.LastActiveDropTargetFraction)
	self:DrawDropRectangle (renderContext, alphaScale * 0.5 * math.min (255,      (SysTime () - self.RootDropData.ActiveDropTargetChangeTime) / 0.2  * 255), self.RootDropData.ActiveDropTarget,     self.RootDropData.ActiveDropTargetFraction)
	renderContext:PopViewPort ()
	
	renderContext:PushViewPort (self.Control:LocalToScreen (0, 0))
	self:DrawDropTargets (renderContext, alphaScale, self.RootDropData)
	renderContext:PopViewPort ()
end

-- Event handlers
function self:OnControlChanged (oldControl, control)
	if oldControl then
		Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. self:GetHashCode ())
	end
	
	if control then
	end
end

function self:OnDragDrop (_, dragDropController)
	self:GetRootDragDropController ():OnRootDragDrop (dragDropController)
	
	self:DoDragDrop (self.Control, dragDropController, self.DropData)
	
	self:SetActiveDropButton (GCompute.DockContainer.DropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainer.DropTarget.None)
end

function self:OnDragEnter (_, dragDropController, oldDropPanel)
	if not oldDropPanel or oldDropPanel.ClassName ~= self.Control.ClassName or oldDropPanel:GetRootDockContainer () ~= self.Control:GetRootDockContainer () then
		self:GetRootDragDropController ():OnRootDragEnter (dragDropController)
	end
	self.DropData.EnterTime = SysTime ()
	
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. self:GetHashCode ())
end

function self:OnDragLeave (_, dragDropController, newDropPanel)
	if not newDropPanel or newDropPanel.ClassName ~= self.Control.ClassName or newDropPanel:GetRootDockContainer () ~= self.Control:GetRootDockContainer () then
		self:GetRootDragDropController ():OnRootDragLeave (dragDropController)
	end
	self:SetActiveDropButton (GCompute.DockContainer.DropTarget.None)
	self:SetActiveDropTarget (GCompute.DockContainer.DropTarget.None)
	
	self.DropData.LeaveTime = SysTime ()
	
	Gooey.AddRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. self:GetHashCode (),
		function ()
			self:DrawDropOverlay (Gooey.RenderContext)
			if SysTime () - self.DropData.LeaveTime > 1 then
				Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "GCompute.DockContainer." .. self:GetHashCode ())
			end
		end
	)
end

function self:OnDragOver (_, dragDropController, x, y)
	self:GetRootDragDropController ():OnRootDragOver (dragDropController)
	if self:GetRootDragDropController ():GetActiveRootDropButton () ~= GCompute.DockContainer.DropTarget.None then
		self:SetActiveDropButton (GCompute.DockContainer.DropTarget.None)
		self:SetActiveDropTarget (GCompute.DockContainer.DropTarget.None)
		return
	end
	
	local dropButton = nil
	local dropTarget = nil
	local dropTargetFraction = 0.75
	
	-- Our drop targets
	if not self.Control:IsRootDockContainer () or
	   self.Control:GetContainerType () ~= GCompute.DockContainer.DockContainerType.SplitContainer then
		dropButton = self:DropButtonFromPoint (x, y, self.DropData)
		if dropButton then
			dropTarget = dropButton
			local hasDocument      = self.Control:GetLargestView () and self.Control:GetLargestView ():GetDocument () and true or false
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
		if self.Control:GetContainerType () == GCompute.DockContainer.DockContainerType.None then
			dropTarget = GCompute.DockContainer.DropTarget.Middle
		end
		
		-- Drops on the tab header section of tab self.Control containers
		-- always hit the middle drop target
		if self.Control:GetContainerType () == GCompute.DockContainer.DockContainerType.TabControl and
		   self.Control.Child:IsPointInHeaderArea (x, y) then
			dropTarget = GCompute.DockContainer.DropTarget.Middle
		end
		
		-- Identify the area drop target
		if not dropTarget then
			local normalizedX = x / self.Control:GetWide ()
			local normalizedY = y / self.Control:GetTall ()
			if normalizedX < 0.25 then
				dropTarget = GCompute.DockContainer.DropTarget.Left
			elseif normalizedX > 0.75 then
				dropTarget = GCompute.DockContainer.DropTarget.Right
			end
			if normalizedY < 0.25 then
				dropTarget = GCompute.DockContainer.DropTarget.Top
			elseif normalizedY > 0.75 then
				dropTarget = GCompute.DockContainer.DropTarget.Bottom
			end
		end
		dropButton = dropButton or GCompute.DockContainer.DropTarget.None
		dropTarget = dropTarget or GCompute.DockContainer.DropTarget.Middle
	end
	self:SetActiveDropButton (dropButton or GCompute.DockContainer.DropTarget.None)
	self:SetActiveDropTarget (dropTarget or GCompute.DockContainer.DropTarget.None, dropTargetFraction)
end

function self:OnRootDragDrop (dragDropController)
	self:DoDragDrop (self.Control, dragDropController, self.RootDropData)
	
	self:SetActiveRootDropButton (GCompute.DockContainer.DropTarget.None)
	self:SetActiveRootDropTarget (GCompute.DockContainer.DropTarget.None)
end

function self:OnRootDragEnter (dragDropController)
	self.RootDropData.EnterTime = SysTime ()
end

function self:OnRootDragLeave (dragDropController)
	self:SetActiveRootDropButton (GCompute.DockContainer.DropTarget.None)
	self:SetActiveRootDropTarget (GCompute.DockContainer.DropTarget.None)
	
	self.RootDropData.LeaveTime = SysTime ()
end

function self:OnRootDragOver (dragDropController)
	local x, y = self.Control:CursorPos ()
	local dropButton = nil
	local dropTarget = nil
	local dropTargetFraction = 0.75
	
	-- Our drop targets
	dropButton = self:DropButtonFromPoint (x, y, self.RootDropData)
	if dropButton then
		dropTarget = dropButton
		local hasDocument      = self.Control:GetLargestView () and self.Control:GetLargestView ():GetDocument () and true or false
		local otherHasDocument = dragDropController:GetObject ():GetDocument () and true or false
		
		if hasDocument == otherHasDocument then
			dropTargetFraction = 0.5
		elseif hasDocument then
			dropTargetFraction = 0.75
		else
			dropTargetFraction = 0.25
		end
	end
	self:SetActiveRootDropButton (dropButton or GCompute.DockContainer.DropTarget.None)
	self:SetActiveRootDropTarget (dropTarget or GCompute.DockContainer.DropTarget.None, dropTargetFraction)
end