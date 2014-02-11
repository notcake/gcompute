local self = {}
self.Name = "Functions"

GCompute.IDE.Profiler.SubViews.Functions = GCompute.MakeConstructor (self, GCompute.IDE.Profiler.ProfilerSubView)

function self:ctor (view, container)
	self.ListView = vgui.Create ("GListView", container)
	self.ListView:SetVisible (self:IsVisible ())
	self.ListView:AddColumn ("Function")
	self.ListView:AddColumn ("Inclusive Samples")
		:SetComparator (
			function (a, b)
				return a.FunctionEntry.InclusiveSampleCount > b.FunctionEntry.InclusiveSampleCount
			end
		)
	self.ListView:AddColumn ("Exclusive Samples")
		:SetComparator (
			function (a, b)
				return a.FunctionEntry.ExclusiveSampleCount > b.FunctionEntry.ExclusiveSampleCount
			end
		)
	self.ListView:AddColumn ("Inclusive Samples %")
		:SetComparator (
			function (a, b)
				return a.FunctionEntry.InclusiveSampleCount > b.FunctionEntry.InclusiveSampleCount
			end
		)
	self.ListView:AddColumn ("Exclusive Samples %")
		:SetComparator (
			function (a, b)
				return a.FunctionEntry.ExclusiveSampleCount > b.FunctionEntry.ExclusiveSampleCount
			end
		)
	self.ListView:SetComparator (
		function (a, b)
			return a.FunctionEntry.ExclusiveSampleCount > b.FunctionEntry.ExclusiveSampleCount
		end
	)
	
	self.ListViewItems = GCompute.WeakTable ()
	
	self.ListViewMenu = self.View:GetFunctionEntryMenu ():Clone ()
	self.ListViewMenu:AddEventListener ("MenuOpening",
		function (_, selectedItems)
			local singleItemSelected = #selectedItems == 1
			self.ListViewMenu:GetItemById ("View Source"):SetEnabled (singleItemSelected)
			self.ListViewMenu:GetItemById ("Show Function Details"):SetEnabled (singleItemSelected)
			
			if singleItemSelected then
				self.ListViewMenu:SetTargetItem (selectedItems [1].FunctionEntry)
				return
			end
			
			local selectedFunctionEntries = {}
			for _, listViewItem in ipairs (selectedItems) do
				selectedFunctionEntries [#selectedFunctionEntries + 1] = listViewItem.FunctionEntry
			end
			
			self.ListViewMenu:SetTargetItem (selectedFunctionEntries)
		end
	)
	self.ListView:SetMenu (self.ListViewMenu)
	
	self.LastSortTime = SysTime ()
	self.SortNeeded   = false
end

function self:dtor ()
	self.ListView:Remove ()
	self.ListViewMenu:dtor ()
end

function self:Clear ()
	self.ListView:Clear ()
	self.ListViewItems = GLib.WeakTable ()
end

function self:OnVisibleChanged (visible)
	self.ListView:SetVisible (visible)
end

function self:PerformLayout (w, h)
	self.ListView:SetPos (0, 0)
	self.ListView:SetSize (w, h)
end

function self:Think ()
	self.UpdateNeeded = self.UpdateNeeded or self.Profiler:IsRunning ()
	
	if self.UpdateNeeded then
		self:UpdateFunctionData ()
	end
	if self.SortNeeded and
	   SysTime () - self.LastSortTime > 1 then
		self.ListView:Sort ()
		self.LastSortTime = SysTime ()
		self.SortNeeded = false
	end
end

-- Internal, do not call
function self:UpdateFunctionData ()
	if not self.UpdateNeeded then return end
	
	self.UpdateNeeded = false
	
	if not self.ProfilingResultSet then return end
	
	for functionEntry in self.ProfilingResultSet:GetFunctionEntryEnumerator () do
		if not self.ListViewItems [functionEntry] then
			local listViewItem = self.ListView:AddItem (tostring (functionEntry:GetHashCode ()))
			listViewItem.FunctionEntry = functionEntry
			listViewItem:SetText (functionEntry:GetFunctionName ())
			
			listViewItem:AddEventListener ("DoubleClick",
				function ()
					self.View:NavigateToFunctionDetailsView (listViewItem.FunctionEntry)
				end
			)
			
			local func = functionEntry:GetFunction ()
			listViewItem:SetToolTipText (func:GetFilePath () .. ": " .. func:GetStartLine () .. "-" .. func:GetEndLine ())
			
			self.ListViewItems [functionEntry] = listViewItem
		end
		
		local listViewItem = self.ListViewItems [functionEntry]
		listViewItem:SetColumnText ("Inclusive Samples", tostring (functionEntry.InclusiveSampleCount))
		listViewItem:SetColumnText ("Exclusive Samples", tostring (functionEntry.ExclusiveSampleCount))
		listViewItem:SetColumnText ("Inclusive Samples %", string.format ("%.2f %%", functionEntry:GetInclusiveSampleFraction () * 100))
		listViewItem:SetColumnText ("Exclusive Samples %", string.format ("%.2f %%", functionEntry:GetExclusiveSampleFraction () * 100))
	end
	
	self.SortNeeded = true
end