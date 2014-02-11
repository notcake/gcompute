local self = {}

function self:Init ()
	self.Label = vgui.Create ("GLabel", self)
	self.Container = vgui.Create ("GPanel", self)
	
	self.TotalSampleCount = 0
	self.MaximumSampleCount = 0
	self.ContainerElements = {}
	self.FunctionEntryCounts = {}
	self.FunctionEntryContainerElements = {}
	
	self.ButtonMenu = nil
	
	self:AddEventListener ("TextChanged",
		function ()
			self.Label:SetText (self:GetText ())
		end
	)
	
	self.Container:SetBackgroundColor (GLib.Colors.CornflowerBlue)
end

function self:AddFunctionEntry (functionEntry)
	if self.FunctionEntryContainerElements [functionEntry] then return end
	
	local func = functionEntry:GetFunction ()
	
	local element = vgui.Create ("GButton", self.Container)
	element.FunctionEntry = functionEntry
	element:SetText (functionEntry:GetFunctionName ())
	element:SetToolTipText (func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine ())
	element:AddEventListener ("Click",
		function ()
			self:DispatchEvent ("FunctionEntryClicked", element.FunctionEntry)
		end
	)
	element:AddEventListener ("RightClick",
		function ()
			if not self.ButtonMenu then return end
			
			self.ButtonMenu:Show (element, element.FunctionEntry)
		end
	)
	
	self.ContainerElements [#self.ContainerElements + 1] = element
	self.FunctionEntryContainerElements [functionEntry] = element
	self.FunctionEntryCounts [functionEntry] = functionEntry:GetInclusiveSampleCount ()
	
	self:InvalidateLayout ()
end

function self:ContainsFunctionEntry (functionEntry)
	return self.FunctionEntryContainerElements [functionEntry] ~= nil
end

function self:Clear ()
	for _, element in ipairs (self.ContainerElements) do
		element:Remove ()
	end
	
	self.ContainerElements = {}
	self.FunctionEntryCounts = {}
	self.FunctionEntryContainerElements = {}
end

function self:GetMaximumSampleCount ()
	return self.MaximumSampleCount
end

function self:GetButtonMenu ()
	return self.ButtonMenu
end

function self:GetTotalSampleCount ()
	return self.TotalSampleCount
end

function self:SetButtonMenu (buttonMenu)
	self.ButtonMenu = buttonMenu
end

function self:SetMaximumSampleCount (maximumSampleCount)
	if self.MaximumSampleCount == maximumSampleCount then return self end
	
	self.MaximumSampleCount = maximumSampleCount
	
	for _, containerElement in ipairs (self.ContainerElements) do
		self:UpdateContainerElement (containerElement)
	end
	
	self:InvalidateLayout ()
	
	return self
end

function self:SetTotalSampleCount (totalSampleCount)
	if self.TotalSampleCount == totalSampleCount then return self end
	
	self.TotalSampleCount = totalSampleCount
	
	self:InvalidateLayout ()
	
	return self
end

function self:Sort ()
	table.sort (self.ContainerElements,
		function (a, b)
			return self.FunctionEntryCounts [a.FunctionEntry] > self.FunctionEntryCounts [b.FunctionEntry]
		end
	)
	
	self:InvalidateLayout ()
end

function self:UpdateContainerElement (containerElement)
	local functionEntry = containerElement.FunctionEntry
	local count = self.FunctionEntryCounts [functionEntry]
	containerElement:SetText (functionEntry:GetFunctionName () .. " (" .. string.format ("%.2f %%", count / self:GetTotalSampleCount () * 100) .. ")")
end

function self:UpdateFunctionEntry (functionEntry, count)
	local containerElement = self.FunctionEntryContainerElements [functionEntry]
	
	if not containerElement then return end
	
	count = count or functionEntry:GetInclusiveSampleCount ()
	self.FunctionEntryCounts [functionEntry] = count
	
	self:UpdateContainerElement (self.FunctionEntryContainerElements [functionEntry])
	self:InvalidateLayout ()
end

function self:OnRemoved ()
end

function self:Paint (w, h)
end

function self:PerformLayout ()
	local w = self:GetWidth ()
	local h = self:GetHeight ()
	
	local x = 0
	local y = 0
	
	-- Label
	self.Label:SetPos (0, 0)
	self.Label:SetSize (w, 20)
	
	y = y + self.Label:GetHeight ()
	y = y + 8
	
	-- Container
	self.Container:SetPos (0, y)
	self.Container:SetSize (w, h - y)
	
	h = self.Container:GetHeight () - 8
	w = self.Container:GetWidth () - 8
	
	x = 4
	y = 4
	for _, containerElement in ipairs (self.ContainerElements) do
		h = h * 0.5
		local count = self.FunctionEntryCounts [containerElement.FunctionEntry]
		local elementHeight = h * count / self:GetMaximumSampleCount ()
		elementHeight = math.max (24, elementHeight)
		
		containerElement:SetPos (x, y)
		containerElement:SetSize (w, elementHeight)
		
		y = y + containerElement:GetHeight () + 4
	end
end

Gooey.Register ("GComputeProfilerFunctionBreakdown", self, "GPanel")