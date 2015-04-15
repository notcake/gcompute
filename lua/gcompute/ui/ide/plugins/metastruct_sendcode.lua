local self = GCompute.IDE.Plugins:Create ("Metastruct.sendcode")

function self:ctor (ideFrame)
	self.IDEFrame         = ideFrame
	self.ActiveView       = nil
	self.ActiveCodeEditor = nil
	
	self.ModifiedMenus = GLib.WeakKeyTable ()
	self.Controls = {}
	
	if not sendcode then return end
	
	self.IDEFrame:AddEventListener ("ActiveViewChanged", "Metastruct.sendcode",
		function (_)
			local activeView       = self.IDEFrame:GetActiveView ()
			local activeCodeEditor = self.IDEFrame:GetActiveCodeEditor () or self:GetViewCodeEditor (activeView)
			
			self:SetActiveView       (activeView      )
			self:SetActiveCodeEditor (activeCodeEditor)
			
			self.SendButton:SetEnabled (self.ActiveCodeEditor ~= nil)
		end
	)
	
	self.TargetItem = nil
	
	self.PlayerMenu = Gooey.Menu ()
	self.PlayerMenu:AddEventListener ("MenuOpening",
		function (_)
			local code  = self.TargetItem.Code
			local title = self.TargetItem.Title
			
			local players = player.GetAll ()
			table.sort (players,
				function (a, b)
					return a:Name ():lower () < b:Name ():lower ()
				end
			)
			
			for _, v in ipairs (players) do
				self.PlayerMenu:AddItem (v:Name ())
					:SetIcon (v:IsAdmin () and "icon16/shield_go.png" or "icon16/user_go.png")
					:AddEventListener ("Click",
						function ()
							if not v            then return end
							if not v:IsValid () then return end
							
							sendcode.send (v:UserID (), code, title)
						end
					)
			end
		end
	)
	self.PlayerMenu:AddEventListener ("MenuClosed",
		function ()
			self.PlayerMenu:Clear ()
			
			self.TargetItem = nil
		end
	)
	
	local toolbar = self.IDEFrame:GetToolbar ()
	self:AddControl (toolbar:AddSeparator ())
	self.SendButton = toolbar:AddButton ("Send")
	self:AddControl (self.SendButton)
	self.SendButton:SetIcon ("icon16/email_go.png")
		:AddEventListener ("Click",
			function (_)
				local title = LocalPlayer ():Nick () .. "/" .. self.ActiveView:GetTitle ()
				local code  = self.ActiveCodeEditor:GetText ()
				
				self.TargetItem =
				{
					Code = code,
					Title = title
				}
				self.PlayerMenu:Show ()
			end
		)
	local toolbarButton = toolbar:AddButton ("Receive")
	self:AddControl (toolbarButton)
	toolbarButton:SetIcon ("icon16/email_open.png")
		:AddEventListener ("Click",
			function (_)
				local menu = Gooey.Menu ()
				
				if not next (sendcode.list) then
					menu:AddItem ("Nothing to receive.")
						:SetEnabled (false)
				else
					local userIdToPlayers = {}
					for _, v in ipairs (player.GetAll ()) do
						userIdToPlayers [v:UserID ()] = v
					end
					
					for userId, _ in pairs (sendcode.list) do
						local ply = userIdToPlayers [userId]
						
						local menuItem = menu:AddItem (tostring (userId))
						menuItem:AddEventListener ("Click",
							function (_)
								sendcode.request (userId,
									function (code, title)
										local codeView = self.IDEFrame:CreateCodeView (title)
										codeView:SetCode (code)
										codeView:Select ()
									end
								)
							end
						)
						
						if ply then
							menuItem:SetText (ply:Nick ())
								:SetIcon (ply:IsAdmin () and "icon16/shield.png" or "icon16/user.png")
						else
							menuItem:SetText ("Disconnected player " .. userId)
								:SetIcon ("icon16/help.png")
						end
					end
				end
				
				menu:AddEventListener ("MenuClosed",
					function ()
						menu:dtor ()
					end
				)
				menu:Show ()
			end
		)
	
	self.ModifiedMenus [self.IDEFrame.TabContextMenu] = true
	self:AddControl (self.IDEFrame.TabContextMenu:AddSeparator ())
	self.SendMenuItem = self.IDEFrame.TabContextMenu:AddItem ("Send")
	self:AddControl (self.SendMenuItem)
	self.SendMenuItem:SetIcon ("icon16/email_go.png")
	self.SendMenuItem:SetSubMenu (self.PlayerMenu)
	
	self.IDEFrame.TabContextMenu:AddEventListener ("MenuOpening", "Metastruct.sendcode",
		function (_, tab)
			local codeEditor = tab and tab.View and self:GetViewCodeEditor (tab.View)
			self.SendMenuItem:SetVisible (codeEditor ~= nil)
			if codeEditor then
				self.TargetItem =
				{
					Code  = codeEditor:GetText (),
					Title = LocalPlayer ():Nick () .. "/" .. tab.View:GetTitle ()
				}
			end
		end
	)
end

function self:dtor ()
	self:SetActiveView       (nil)
	self:SetActiveCodeEditor (nil)
	
	self.IDEFrame.TabContextMenu:RemoveEventListener ("MenuOpening", "Metastruct.sendcode")
	
	for menu, _ in pairs (self.ModifiedMenus) do
		menu:RemoveEventListener ("MenuOpening", "Metastruct.sendcode")
	end
	
	self.ModifiedMenus = {}
	
	self.IDEFrame:RemoveEventListener ("ActiveViewChanged", "Metastruct.sendcode")
	
	if self.PlayerMenu then
		self.PlayerMenu:dtor ()
		self.PlayerMenu = nil
	end
	
	for control in self:GetControlEnumerator () do
		control:Remove ()
	end
	self:ClearControls ()
end

-- Internal, do not call
function self:AddControl (control)
	self.Controls [control] = true
end

function self:ClearControls ()
	self.Controls = {}
end

function self:GetControlEnumerator ()
	return GLib.KeyEnumerator (self.Controls)
end

function self:RemoveControl (control)
	self.Controls [control] = nil
end

function self:GetViewCodeEditor (view)
	if not view then return nil end
	
	if view:GetType () == "Code" then
		return view:GetEditor ()
	end
	
	if view:GetType () == "Output" or
	   view:GetType () == "Console" or
	   view:GetType () == "Memory" then
		return view:GetEditor ()
	end
	
	return nil
end

function self:SetActiveView (view)
	self.ActiveView = view
	return self
end

function self:SetActiveCodeEditor (codeEditor)
	if self.ActiveCodeEditor == codeEditor then return self end
	
	self:UnhookCodeEditor (self.ActiveCodeEditor)
	self.ActiveCodeEditor = codeEditor
	self:HookCodeEditor (self.ActiveCodeEditor)
	
	local codeEditorContextMenu = self.ActiveCodeEditor and self.ActiveCodeEditor:GetContextMenu ()
	if codeEditorContextMenu and not self.ModifiedMenus [codeEditorContextMenu] then
		self.ModifiedMenus [codeEditorContextMenu] = true
		self:AddControl (codeEditorContextMenu:AddSeparator ())
		local sendSelectionMenuItem = codeEditorContextMenu:AddItem ("Send selection")
		self:AddControl (sendSelectionMenuItem)
		sendSelectionMenuItem:SetIcon ("icon16/email_go.png")
		sendSelectionMenuItem:SetSubMenu (self.PlayerMenu)
		
		codeEditorContextMenu:AddEventListener ("MenuOpening", "Metastruct.sendcode",
			function (_)
				local enabled = self.ActiveCodeEditor and not self.ActiveCodeEditor:IsSelectionEmpty ()
				sendSelectionMenuItem:SetEnabled (enabled)
				self.TargetItem =
				{
					Code  = self.ActiveCodeEditor:GetSelectionText (),
					Title = LocalPlayer ():Nick () .. "/" .. self.ActiveView:GetTitle () .. " selection"
				}
			end
		)
	end
	
	return self
end

function self:HookCodeEditor (codeEditor)
	if not codeEditor then return end
end
function self:UnhookCodeEditor (codeEditor)
	if not codeEditor then return end
end