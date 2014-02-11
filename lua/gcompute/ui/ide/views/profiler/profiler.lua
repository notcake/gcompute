GCompute.IDE.Profiler = {}
GCompute.IDE.Profiler.SubViews = {}

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
	self.ComboBox:SetWidth (128)
	
	self.Profiler = nil
	self.ProfilingResultSet = nil
	
	self.SubViewContainer = vgui.Create ("GPanel", container)
	self.ActiveSubView = nil
	
	self.SubViews = {}
	self.SubViews [#self.SubViews + 1] = GCompute.IDE.Profiler.SubViews.Functions (self, self.SubViewContainer)
	self.SubViews [#self.SubViews + 1] = GCompute.IDE.Profiler.SubViews.FunctionDetails (self, self.SubViewContainer)
	
	for _, subView in ipairs (self.SubViews) do
		self.SubViews [subView:GetId ()] = subView
		
		local comboBoxItem = self.ComboBox:AddItem (subView:GetName (), subView:GetId ())
		comboBoxItem:AddEventListener ("Selected",
			function ()
				self:SetActiveSubView (subView)
			end
		)
		
		subView.ComboBoxItem = comboBoxItem
	end
	
	self:AddEventListener ("ActiveSubViewChanged",
		function (_, subView)
			if not subView then return end
			
			subView.ComboBoxItem:Select ()
		end
	)
	
	self:SetProfiler (GCompute.Profiling.Profiler)
	self:SetProfilingResultSet (GCompute.Profiling.ProfilingResultSet ())
	
	self:SetActiveSubView (self.SubViews.Functions)
end

function self:dtor ()
	self:Stop ()
	
	self:SetProfiler (nil)
	self:SetProfilingResultSet (nil)
	
	for _, subView in ipairs (self.SubViews) do
		subView:dtor ()
	end
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

-- Sub views
function self:GetActiveSubView ()
	return self.ActiveSubView
end

function self:GetSubView (id)
	return self.SubViews [id]
end

function self:SetActiveSubView (subView)
	if type (subView) == "string" then
		subView = self.SubViews [subView]
	end
	
	if self.ActiveSubView == subView then return end
	
	if self.ActiveSubView then
		self.ActiveSubView:SetVisible (false)
	end
	
	self.ActiveSubView = subView
	
	if self.ActiveSubView then
		self.ActiveSubView:SetVisible (true)
		self.ComboBox:SetSelectedItem (self.ActiveSubView:GetId ())
	end
end

function self:ShowFunctionCode (functionEntry)
	local uri = functionEntry:GetFunction ():GetFilePath ()
	local pathMatch = string.match (uri, "lua/(.*)")
	if pathMatch then
		if file.Exists (pathMatch, "LCL") then
			uri = "luacl/" .. pathMatch
		else
			uri = "luasv/" .. pathMatch
		end
		
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
end

-- Profiling
function self:GetProfiler ()
	return self.Profiler
end

function self:GetProfilingResultSet ()
	return self.ProfilingResultSet
end

function self:SetProfiler (profiler)
	if self.Profiler == profiler then return self end
	
	self.Profiler = profiler
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfiler (profiler)
	end
	
	return self
end

function self:SetProfilingResultSet (profilingResultSet)
	if self.ProfilingResultSet == profilingResultSet then return self end
	
	self.ProfilingResultSet = profilingResultSet
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfilingResultSet (profilingResultSet)
	end
	
	return self
end

function self:Clear ()
	if self.Profiler then
		self.Profiler:Clear ()
	end
	
	if self.ProfilingResultSet then
		self.ProfilingResultSet:Clear ()
	end
end

function self:Start ()
	if not self.Profiler then return end
	
	self.Profiler:SetProfilingResultSet (self.ProfilingResultSet)
	
	for _, subView in ipairs (self.SubViews) do
		subView:SetProfiler (self.Profiler)
		subView:SetProfilingResultSet (self.ProfilingResultSet)
	end
	
	self:Clear ()
	self.Profiler:Start ()
end

function self:Stop ()
	if not self.Profiler then return end
	
	self.Profiler:Stop ()
end

-- Event handlers
function self:PerformLayout (w, h)
	self.Toolbar:SetWide (w)
	self.SubViewContainer:SetPos (0, self.Toolbar:GetTall ())
	self.SubViewContainer:SetSize (w, h - self.Toolbar:GetTall ())
end

function self:Think ()
	if self.ActiveSubView then
		self.ActiveSubView:Think ()
	end
end