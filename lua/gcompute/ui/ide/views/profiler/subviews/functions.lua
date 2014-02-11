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
	
	self.LastSortTime = SysTime ()
	self.SortNeeded   = false
end

function self:dtor ()
	self.ListView:Remove ()
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
					local functionDetails = self.View:GetSubView ("Function Details")
					self.View:SetActiveSubView (functionDetails)
					functionDetails:SetFunctionEntry (listViewItem.FunctionEntry)
					
					if true then return end
					self:GetIDE ():OpenUri (uri,
						function (success, resource, view)
							if not view then return end
							view:Select ()
							
							if view:GetType () ~= "Code" then return end
							
							local startLine = functionEntry:GetFunction ():GetStartLine ()
							local endLine = functionEntry:GetFunction ():GetEndLine ()
							local location1 = GCompute.CodeEditor.LineCharacterLocation (startLine - 1, char and (char - 1) or 0)
							local location2 = GCompute.CodeEditor.LineCharacterLocation (endLine - 1, char and (char - 1) or 0)
							location1 = view:GetEditor ():GetDocument ():CharacterToColumn (location1, view:GetEditor ():GetTextRenderer ())
							location2 = view:GetEditor ():GetDocument ():CharacterToColumn (location2, view:GetEditor ():GetTextRenderer ())
							view:GetEditor ():SetCaretPos (location2)
							GLib.CallDelayed (
								function ()
									view:GetEditor ():ScrollToCaret ()
									view:GetEditor ():SetCaretPos (location1)
									view:GetEditor ():SetSelection (view:GetEditor ():GetCaretPos ())
									view:GetEditor ():ScrollToCaret ()
								end
							)
						end
					)
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