local self = {}

--[[
	Events:
		ProcessOpened (Process process)
			Fired when a process is double clicked.
		SelectedProcessChanged (Process process)
			Fired when a process is selected from the list.
]]

function self:Init ()
	self.ProcessList = nil
	
	self.Processes = {}
	self.HookedProcesses = {}
	
	self:AddColumn ("Name")
	self:AddColumn ("PID")
		:SetAlignment (6)
		:SetMaximumWidth (64)
		:SetComparator (			
			function (a, b)
				return a.Process:GetProcessId () < b.Process:GetProcessId ()
			end
		)
	self:AddColumn ("CPU")
		:SetAlignment (6)
		:SetMaximumWidth (64)
		:SetComparator (
			function (a, b)
				return a.Process:GetCpuTime () < b.Process:GetCpuTime ()
			end
		)
	self:AddColumn ("Created")
		:SetMaximumWidth (192)
		:SetComparator (
			function (a, b)
				return a.Process:GetCreationTimestamp () < b.Process:GetCreationTimestamp ()
			end
		)
	
	self.Menu = Gooey.Menu ()
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			local targetItem = self:GetSelectedProcesses ()
			self.Menu:SetTargetItem (targetItem)
			
			self.Menu:GetItemById ("Terminate"):SetEnabled (#targetItem ~= 0)
		end
	)
	self.Menu:AddItem ("Terminate",
		function (targetProcesses)
			for _, process in ipairs (targetProcesses) do
				process:Terminate ()
			end
		end
	):SetIcon ("icon16/cross.png")
	self.Menu:AddItem ("Suspend",
		function (targetProcesses)
			for _, process in ipairs (targetProcesses) do
				process:Suspend ()
			end
		end
	):SetIcon ("icon16/control_pause_blue.png")
	self.Menu:AddItem ("Resume",
		function (targetProcesses)
			for _, process in ipairs (targetProcesses) do
				process:Resume ()
			end
		end
	):SetIcon ("icon16/control_play_blue.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Properties",
		function (targetProcesses)
		end
	):SetIcon ("icon16/application_view_list.png")
	
	self:AddEventListener ("DoubleClick",
		function (_, item)
			if not item then return end
			if not item.Process then return end
			self:DispatchEvent ("ProcessOpened", item.Process)
		end
	)
	
	self:AddEventListener ("SelectionChanged",
		function (_, item)
			local process = item and item.Process or nil
			self:DispatchEvent ("SelectedProcessChanged", process)
		end
	)
	
	self.ProcessHooks =
	{
		NameChanged = function (process, name)
			local listViewItem = self.Processes [process:GetProcessId ()]
			listViewItem:SetText (name)
			self:Sort ()
		end,
		Terminated = function (process)
			local listViewItem = self.Processes [process:GetProcessId ()]
			listViewItem:SetBackgroundColor (GLib.Colors.Red)
			
			timer.Simple (1,
				function ()
					self:RemoveProcess (process)
				end
			)
		end
	}
end

function self.DefaultComparator (a, b)
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:GetProcessList ()
	return self.ProcessList
end

function self:GetSelectedProcess ()
	local item = self.SelectionController:GetSelectedItem ()
	return item and item.Process or nil
end

function self:GetSelectedProcesses ()
	local selectedProcesses = {}
	for _, item in ipairs (self.SelectionController:GetSelectedItems ()) do
		selectedProcesses [#selectedProcesses + 1] = item.Process
	end
	return selectedProcesses
end

function self:MergeRefresh ()
	if not self.ProcessList then return end
	
	for _, process in self.ProcessList:GetEnumerator () do
		self:AddProcess (process)
	end
	self:Sort ()
end

function self:SetProcessList (processList)
	if self.ProcessList == processList then return end

	self:Clear ()
	self.Processes = {}
	if self.ProcessList then
		self.ProcessList:RemoveEventListener ("ProcessCreated",   self:GetHashCode ())
		self.ProcessList:RemoveEventListener ("ProcessDestroyed", self:GetHashCode ())
		
		for process, _ in pairs (self.HookedProcesses) do
			self:RemoveProcess (process)
		end
		self.ProcessList = nil
	end
	if not processList then return end
	
	self.ProcessList = processList
	self:MergeRefresh ()
	
	self.ProcessList:AddEventListener ("ProcessCreated", self:GetHashCode (),
		function (_, process)
			self:AddProcess (process)
			self:Sort ()
		end
	)
	
	self.ProcessList:AddEventListener ("ProcessDestroyed", self:GetHashCode (),
		function (_, process)
			self:Sort ()
		end
	)
end

function self:Think ()
	for _, listViewItem in pairs (self.Processes) do
		local cpuTime = listViewItem.Process:GetCpuTime ()
		local cpuFraction = cpuTime / (1 / 60)
		if cpuFraction == 0 then
			listViewItem:SetColumnText ("CPU", "")
		else
			listViewItem:SetColumnText ("CPU", string.format ("%.2f", cpuFraction * 100))
		end
	end
end

-- Internal, do not call
function self:AddProcess (process)
	if self.Processes [process:GetProcessId ()] then return end
	
	local listViewItem = self:AddItem (process:GetName ())
	listViewItem:SetText (process:GetName ())
	listViewItem.Process = process
	
	self:UpdateIcon (listViewItem)
	
	listViewItem:SetColumnText ("PID", string.format ("%08x", process:GetProcessId ()))
	listViewItem:SetColumnText ("CPU", "")
	listViewItem:SetColumnText ("Created", GLib.FormatDate (process:GetCreationTimestamp ()))
	
	self.Processes [process:GetProcessId ()] = listViewItem
	
	self.HookedProcesses [process] = true
	for hookName, hook in pairs (self.ProcessHooks) do
		process:AddEventListener (hookName, self:GetHashCode (), hook)
	end
	
	return listViewItem
end

function self:RemoveProcess (process)
	if not self.Processes [process:GetProcessId ()] then return end
	
	if self.Processes [process:GetProcessId ()] and self.Processes [process:GetProcessId ()]:IsValid () then
		self.Processes [process:GetProcessId ()]:Remove ()
	end
	self.Processes [process:GetProcessId ()] = nil
	
	self.HookedProcesses [process] = nil
	for hookName, _ in pairs (self.ProcessHooks) do
		process:RemoveEventListener (hookName, self:GetHashCode ())
	end
end

function self:UpdateIcon (listViewItem)
	local process = listViewItem.Process
	listViewItem:SetIcon ("icon16/application_xp_terminal.png")
end

-- Event handlers
function self:OnRemoved ()
	self:SetProcessList (nil)
end

-- Event handlers
self.PermissionsChanged = GCompute.NullCallback

vgui.Register ("GComputeProcessListView", self, "GListView")