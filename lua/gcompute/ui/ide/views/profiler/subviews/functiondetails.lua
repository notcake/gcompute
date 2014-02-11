local self = {}
self.Name = "Function Details"
GCompute.IDE.Profiler.SubViews.FunctionDetails = GCompute.MakeConstructor (self, GCompute.IDE.Profiler.ProfilerSubView)

function self:ctor (view, container)
	self.Container = vgui.Create ("GPanel", container)
	self.Container:SetBackgroundColor (GLib.Colors.White)
	self.Container:SetVisible (self:IsVisible ())
	
	self.Container.Paint = function (_, w, h)
		local renderContext = Gooey.RenderContext
		
		draw.RoundedBox (4, 0, 0, w, h, GLib.Colors.White)
		
		local x, y = self.PathLabel:GetPos ()
		y = y + self.PathLabel:GetHeight ()
		y = y + 4
		
		surface.SetDrawColor (GLib.Colors.Black)
		surface.DrawLine (4, y, w - 32, y)
	end
	
	self.TitleLabel = vgui.Create ("GLabel", self.Container)
	self.TitleLabel:SetFont ("DermaLarge")
	self.TitleLabel:SetTextColor (GLib.Colors.Black)
	self.PathLabel = vgui.Create ("GLabel", self.Container)
	self.PathLabel:SetTextColor (GLib.Colors.Black)
	
	self.Callers = vgui.Create ("GComputeProfilerFunctionBreakdown", self.Container)
	self.Current = vgui.Create ("GComputeProfilerFunctionBreakdown", self.Container)
	self.Callees = vgui.Create ("GComputeProfilerFunctionBreakdown", self.Container)
	self.Callers:SetText ("Calling functions")
	self.Current:SetText ("Current function")
	self.Callees:SetText ("Called functions")
	
	self.Callers:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self.View:NavigateToFunctionDetailsView (functionEntry)
		end
	)
	
	self.Current:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self.View:ShowFunctionCode (functionEntry)
		end
	)
	
	self.Callees:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self.View:NavigateToFunctionDetailsView (functionEntry)
		end
	)
	
	self.Callers:SetButtonMenu (self.View:GetFunctionEntryMenu ())
	self.Current:SetButtonMenu (self.View:GetFunctionEntryMenu ())
	self.Callees:SetButtonMenu (self.View:GetFunctionEntryMenu ())
	
	self.FunctionEntry = nil
	
	self.LastSortTime = SysTime ()
	self.SortNeeded   = false
end

function self:dtor ()
	self:SetFunctionEntry (nil)
	
	self.Container:Remove ()
end

function self:Clear ()
	self:SetFunctionEntry (nil)
	
	self.Callers:Clear ()
	self.Current:Clear ()
	self.Callees:Clear ()
end

-- History
function self:CreateHistoryItem (historyItem)
	historyItem = historyItem or GCompute.IDE.Profiler.HistoryItem ()
	historyItem:SetSubViewId (self:GetId ())
	
	historyItem.FunctionEntry = self.FunctionEntry
	
	return historyItem
end

function self:RestoreHistoryItem (historyItem)
	self:SetFunctionEntry (historyItem.FunctionEntry)
end

function self:GetFunctionEntry ()
	return self.FunctionEntry
end

function self:SetFunctionEntry (functionEntry)
	if self.FunctionEntry == functionEntry then return self end
	
	-- Clear boxes
	self.Callers:Clear ()
	self.Current:Clear ()
	self.Callees:Clear ()
	
	self.FunctionEntry = functionEntry
	
	-- Update title and path
	local func = self.FunctionEntry and self.FunctionEntry:GetFunction ()
	local definitionLocation = ""
	if func then
		definitionLocation = func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine ()
	end
	
	self.TitleLabel:SetText (self.FunctionEntry and self.FunctionEntry:GetFunctionName () or "")
	self.PathLabel:SetText (definitionLocation)
	
	-- Flag for update
	self.UpdateNeeded = true
	
	return self
end

function self:OnVisibleChanged (visible)
	self.Container:SetVisible (visible)
end

function self:PerformLayout (w, h)
	self.Container:SetSize (w, h)
	
	local padding = 8
	local contentWidth  = w - 2 * padding
	local contentHeight = h - 2 * padding
	
	local x = padding
	local y = padding
	
	-- Title label
	self.TitleLabel:SetPos (x, y)
	self.TitleLabel:SetSize (w, 32)
	y = y + self.TitleLabel:GetHeight ()
	
	-- Path label
	self.PathLabel:SetPos (x, y)
	self.PathLabel:SetSize (w, 16)
	y = y + self.PathLabel:GetHeight ()
	
	-- Horizontal line
	y = y + 12
	
	local spacing = 32
	local containerWidth = (contentWidth - 2 * spacing) / 3
	contentHeight = h - y - padding
	
	self.Callers:SetPos (padding, y)
	self.Current:SetPos (padding + containerWidth + spacing, y)
	self.Callees:SetPos (padding + 2 * containerWidth + 2 * spacing, y)
	self.Callers:SetHeight (contentHeight)
	self.Current:SetHeight (contentHeight)
	self.Callees:SetHeight (contentHeight)
	self.Callers:SetWidth (containerWidth)
	self.Current:SetWidth (containerWidth)
	self.Callees:SetWidth (containerWidth)
end

function self:Think ()
	self.UpdateNeeded = self.UpdateNeeded or self.Profiler:IsRunning ()
	
	if self.UpdateNeeded then
		self:Update ()
	end
	if self.SortNeeded and
	   SysTime () - self.LastSortTime > 1 then
		self.Callers:Sort ()
		self.Callees:Sort ()
		self.LastSortTime = SysTime ()
		self.SortNeeded = false
	end
end

-- Internal, do not call
function self:Update ()
	if not self.UpdateNeeded then return end
	
	self.UpdateNeeded = false
	
	if not self.ProfilingResultSet then return end
	if not self.FunctionEntry then return end
	
	self.Callers:SetMaximumSampleCount (self.FunctionEntry:GetInclusiveSampleCount ())
	self.Current:SetMaximumSampleCount (self.FunctionEntry:GetInclusiveSampleCount ())
	self.Callees:SetMaximumSampleCount (self.FunctionEntry:GetInclusiveSampleCount ())
	self.Callers:SetTotalSampleCount (self.ProfilingResultSet:GetSampleCount ())
	self.Current:SetTotalSampleCount (self.ProfilingResultSet:GetSampleCount ())
	self.Callees:SetTotalSampleCount (self.ProfilingResultSet:GetSampleCount ())
	
	for func, count in self.FunctionEntry:GetCallerEnumerator () do
		local functionEntry = self.ProfilingResultSet:GetFunctionEntry (func)
		self.Callers:AddFunctionEntry (functionEntry)
		self.Callers:UpdateFunctionEntry (functionEntry, count)
	end
	
	self.Current:AddFunctionEntry (self.FunctionEntry)
	self.Current:UpdateFunctionEntry (self.FunctionEntry)
	
	for func, count in self.FunctionEntry:GetCalleeEnumerator () do
		local functionEntry = self.ProfilingResultSet:GetFunctionEntry (func)
		self.Callees:AddFunctionEntry (functionEntry)
		self.Callees:UpdateFunctionEntry (functionEntry, count)
	end
	
	self.SortNeeded = true
end