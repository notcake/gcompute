local self = {}
self.Name = "Function Details"
GCompute.IDE.Profiler.SubViews.FunctionDetails = GCompute.MakeConstructor (self, GCompute.IDE.Profiler.ProfilerSubView)

function self:ctor (view, container)
	self.Callers = vgui.Create ("GComputeProfilerFunctionBreakdown", container)
	self.Current = vgui.Create ("GComputeProfilerFunctionBreakdown", container)
	self.Callees = vgui.Create ("GComputeProfilerFunctionBreakdown", container)
	self.Callers:SetText ("Calling functions")
	self.Current:SetText ("Current function")
	self.Callees:SetText ("Called functions")
	self.Callers:SetVisible (self:IsVisible ())
	self.Current:SetVisible (self:IsVisible ())
	self.Callees:SetVisible (self:IsVisible ())
	
	self.Callers:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self:SetFunctionEntry (functionEntry)
		end
	)
	
	self.Current:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self.View:ShowFunctionCode (functionEntry)
		end
	)
	
	self.Callees:AddEventListener ("FunctionEntryClicked",
		function (_, functionEntry)
			self:SetFunctionEntry (functionEntry)
		end
	)
	
	self.FunctionEntry = nil
	
	self.LastSortTime = SysTime ()
	self.SortNeeded   = false
end

function self:dtor ()
	self.Callers:Remove ()
	self.Current:Remove ()
	self.Callees:Remove ()
end

function self:Clear ()
	self.Callers:Clear ()
	self.Current:Clear ()
	self.Callees:Clear ()
end

function self:GetFunctionEntry ()
	return self.FunctionEntry
end

function self:SetFunctionEntry (functionEntry)
	if self.FunctionEntry == functionEntry then return self end
	
	self.FunctionEntry = functionEntry
	self:Clear ()
	self.UpdateNeeded = true
	
	return self
end

function self:OnVisibleChanged (visible)
	self.Callers:SetVisible (visible)
	self.Current:SetVisible (visible)
	self.Callees:SetVisible (visible)
end

function self:PerformLayout (w, h)
	local padding = 8
	w = w - 2 * padding
	h = h - 2 * padding
	
	local y = padding
	
	local containerWidth = (w - 2 * 32) / 3
	self.Callers:SetPos (padding, y)
	self.Current:SetPos (padding + containerWidth + 32, y)
	self.Callees:SetPos (padding + 2 * containerWidth + 2 * 32, y)
	self.Callers:SetHeight (h)
	self.Current:SetHeight (h)
	self.Callees:SetHeight (h)
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