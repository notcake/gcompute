local self, info = GCompute.IDE.ViewTypes:CreateType ("HookProfiler")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom")
self.Title    = "Hook Profiler"
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
	self.ListView = vgui.Create ("GListView", container)
	self.ListView:AddColumn ("Hook")
	self.ListView:AddColumn ("ID")
	self.ListView:AddColumn ("Calls")
	self.ListView:AddColumn ("Frame Time (ms)")
	self.ListView:AddColumn ("ΔFPS")
	self.ListView.Comparator = function (a, b)
		return a.HookData.CallCount > b.HookData.CallCount
	end
	self.ListView:SetColumnComparator ("Frame Time (ms)",
		function (a, b)
			return a.HookData.LastFrameTime > b.HookData.LastFrameTime
		end
	)
	self.ListView:SetColumnComparator ("ΔFPS",
		function (a, b)
			return a.HookData.DeltaFPS > b.HookData.DeltaFPS
		end
	)
	
	self.Hooks = {}
	self.LastSortTime = SysTime ()
end

function self:dtor ()
	self:Stop ()
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end

function self:CreateHookData (eventName, hookName)
	local hookData = {}
	hookData.EventName       = eventName
	hookData.HookName        = hookName
	hookData.OriginalHandler = nil
	hookData.CallCount       = 0
	hookData.Time            = 0
	
	hookData.LastFrame       = CurTime ()
	hookData.LastFrameTime   = 0
	
	hookData.DeltaFPS        = 0
	return hookData
end

function self:Start ()
	for eventName, hookTable in pairs (hook.GetTable ()) do
		self.Hooks [eventName] = self.Hooks [eventName] or {}
		for hookName, handler in pairs (hookTable) do
			local hookData = self.Hooks [eventName] [hookName] or self:CreateHookData (eventName, hookName)
			self.Hooks [eventName] [hookName] = hookData
			hookData.CallCount = 0
			hookData.Time = 0
			if not hookData.OriginalHandler then
				hookData.OriginalHandler = handler
			end
			hook.Add (eventName, hookName,
				function (...)
					local startTime = SysTime ()
					hookData.CallCount = hookData.CallCount + 1
					local a, b, c, d, e, f, g, h = hookData.OriginalHandler (...)
					hookData.Time = hookData.Time + SysTime () - startTime
					if CurTime () ~= hookData.LastFrame then
						hookData.LastFrame = CurTime ()
						hookData.LastFrameTime = 0
					end
					hookData.LastFrameTime = hookData.LastFrameTime + SysTime () - startTime
					return a, b, c, d, e, f, g, h
				end
			)
		end
	end
end

function self:Stop ()
	for eventName, hookTable in pairs (self.Hooks) do
		for hookName, hookData in pairs (hookTable) do
			if hook.GetTable () [eventName] [hookName] and hookData.OriginalHandler then
				hook.Add (eventName, hookName, hookData.OriginalHandler)
				hookData.OriginalHandler = nil
			end
		end
	end
end

-- Internal, do not call
function self:UpdateHookData (hookData)
	if not hookData.ListViewItem then
		local listViewItem = self.ListView:AddLine (tostring (hookData))
		listViewItem:SetText (tostring (hookData.EventName))
		listViewItem:SetColumnText (2, tostring (hookData.HookName))
		
		listViewItem.HookData = hookData
		hookData.ListViewItem = listViewItem
	end
	
	hookData.ListViewItem:SetColumnText (3, tostring (hookData.CallCount))
	hookData.ListViewItem:SetColumnText (4, string.format ("%.3f", (hookData.LastFrameTime) * 1000))
	
	local currentFPS = 1 / FrameTime ()
	local higherFPS = 1 / (FrameTime () - hookData.LastFrameTime)
	hookData.DeltaFPS = higherFPS - currentFPS
	hookData.ListViewItem:SetColumnText (5, string.format ("%.3f", hookData.DeltaFPS))
end

-- Event handlers
function self:PerformLayout (w, h)
	self.Toolbar:SetWide (w)
	self.ListView:SetPos (0, self.Toolbar:GetTall ())
	self.ListView:SetSize (w, h - self.Toolbar:GetTall ())
end

function self:Think ()
	for eventName, hookTable in pairs (self.Hooks) do
		for hookName, hookData in pairs (hookTable) do
			self:UpdateHookData (hookData)
		end
	end
end