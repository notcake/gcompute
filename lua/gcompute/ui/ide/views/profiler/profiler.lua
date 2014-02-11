local self, info = GCompute.IDE.ViewTypes:CreateType ("Profiler")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom")
self.Title    = "Profiler"
self.Icon     = "icon16/clock.png"
self.Hideable = true
self.Visible  = false

function self:ctor (container)
	self.Toolbar = vgui.Create ("GToolbar", container)
	self.Toolbar:AddButton ("Start")
		:SetIcon ("icon16/control_play.png")
		:AddEventListener ("Click",
			function ()
				self:Start ()
				self.Toolbar:GetItemById ("Start"):SetEnabled (false)
				self.Toolbar:GetItemById ("Stop") :SetEnabled (true)
			end
		)
	self.Toolbar:AddButton ("Stop")
		:SetIcon ("icon16/control_stop.png")
		:SetEnabled (false)
		:AddEventListener ("Click",
			function ()
				self:Stop ()
				self.Toolbar:GetItemById ("Start"):SetEnabled (true)
				self.Toolbar:GetItemById ("Stop") :SetEnabled (false)
			end
		)
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Back")
		:SetIcon ("icon16/resultset_previous.png")
	self.Toolbar:AddButton ("Forwards")
		:SetIcon ("icon16/resultset_next.png")
	self.ComboBox = self.Toolbar:AddComboBox ()
	self.ComboBox:AddItem ("Functions")
		:AddEventListener ("Selected",
			function ()
				self.ListView:SetVisible (true)
			end
		)
		:AddEventListener ("Deselected",
			function ()
				self.ListView:SetVisible (false)
			end
		)
	self.ComboBox:AddItem ("Function Details")
		:AddEventListener ("Selected",
			function ()
			end
		)
		:AddEventListener ("Deselected",
			function ()
			end
		)
	self.ComboBox:SetWidth (128)
		
	self.ListView = vgui.Create ("GListView", container)
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
	self.UpdateNeeded = false
	self.SortNeeded   = false
end

function self:dtor ()
	self:Stop ()
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

function self:Clear ()
	self.ListView:Clear ()
	self.ListViewItems = GLib.WeakTable ()
end

function self:Start ()
	self:Clear ()
	GCompute.Profiling.Profiler:Clear ()
	GCompute.Profiling.Profiler:Start ()
	
	self.UpdateNeeded = true
	self.SortNeeded   = true
end

function self:Stop ()
	GCompute.Profiling.Profiler:Stop ()
	
	self.UpdateNeeded = true
	self.SortNeeded   = true
end

-- Internal, do not call
function self:UpdateFunctionData ()
	if not self.UpdateNeeded then return end
	
	self.UpdateNeeded = false
	
	for functionEntry in GCompute.Profiling.Profiler:GetFunctionEntryEnumerator () do
		if not self.ListViewItems [functionEntry] then
			local listViewItem = self.ListView:AddItem (tostring (functionEntry:GetHashCode ()))
			listViewItem.FunctionEntry = functionEntry
			listViewItem:SetText (functionEntry:GetFunctionName ())
			
			local uri = functionEntry:GetFunction ():GetFilePath ()
			local pathMatch = string.match (uri, "lua/(.*)")
			if pathMatch then
				if file.Exists (pathMatch, "LCL") then
					uri = "luacl/" .. pathMatch
				else
					uri = "luasv/" .. pathMatch
				end
			end
			
			listViewItem:AddEventListener ("DoubleClick",
				function ()
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

-- Event handlers
function self:PerformLayout (w, h)
	self.Toolbar:SetWide (w)
	self.ListView:SetPos (0, self.Toolbar:GetTall ())
	self.ListView:SetSize (w, h - self.Toolbar:GetTall ())
end

function self:Think ()
	self.UpdateNeeded = self.UpdateNeeded or GCompute.Profiling.Profiler:IsRunning ()
	
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