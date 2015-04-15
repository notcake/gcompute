local self = GCompute.IDE.Plugins:Create ("Metastruct.COH")

CreateClientConVar ("gcompute_editor_5ever", 1, true, false)

function self:ctor (ideFrame)
	self.IDEFrame = ideFrame
	self.TypingCode = false
	self.ActiveCodeEditor = nil
	
	self.IDEFrame:AddEventListener ("VisibleChanged", "Metastruct.COH",
		function (_)
			self:UpdateHookedView ()
		end
	)
	self.IDEFrame:AddEventListener ("ActiveViewChanged", "Metastruct.COH",
		function (_)
			self:UpdateHookedView ()
		end
	)
end

timer.Simple (1,
	function ()
		if chatbox then
			chatbox._ShowChat2Box = chatbox._ShowChat2Box or chatbox.ShowChat2Box
			function chatbox.ShowChat2Box (tab, mode, reserved)
				pcall (
					function ()
						if GetConVar ("gcompute_editor_5ever"):GetBool () and GCompute and GCompute.IDE and tab == 2 then
							GCompute.IDE.GetInstance ():GetFrame ():SetVisible (true)
							GCompute.IDE.GetInstance ():GetFrame ():MoveToFront ()
						else
							chatbox._ShowChat2Box (tab, mode, reserved)
						end
					end
				)
			end
		end
	end
)

function self:dtor ()
	self:UnhookCodeEditor (self.ActiveCodeEditor)
	self.ActiveCodeEditor = nil
	
	self.IDEFrame:RemoveEventListener ("VisibleChanged",          "Metastruct.COH")
	self.IDEFrame:RemoveEventListener ("ActiveViewChanged",       "Metastruct.COH")
	hook.Remove ("PlayerBindPress", "Metastruct.COH")
	
	self:UpdateChatStatus ()
end

function self:HookCodeEditor (codeEditor)
	if not codeEditor then return end
	
	codeEditor:AddEventListener ("TextChanged", "Metastruct.COH",
		function ()
			self:UpdateChatStatus ()
		end
	)
end

function self:UnhookCodeEditor (codeEditor)
	if not codeEditor then return end
	
	codeEditor:RemoveEventListener ("TextChanged", "Metastruct.COH")
end

function self:UpdateHookedView ()
	local codeEditor = self.IDEFrame:GetActiveCodeEditor ()
	if not codeEditor and
	   self.IDEFrame:GetActiveView () and
	   (self.IDEFrame:GetActiveView ():GetType () == "Output" or
	    self.IDEFrame:GetActiveView ():GetType () == "Console" or
		self.IDEFrame:GetActiveView ():GetType () == "Memory") then
		codeEditor = self.IDEFrame:GetActiveView ():GetEditor ()
	end
	if not self.IDEFrame:IsVisible () then
		codeEditor = nil
	end
	
	self:UnhookCodeEditor (self.ActiveCodeEditor)
	self:HookCodeEditor (codeEditor)
	self.ActiveCodeEditor = codeEditor
	
	self:UpdateChatStatus ()
end

function self:UpdateChatStatus ()
	if not coh then return end
	
	if self.ActiveCodeEditor then
		if not self.TypingCode then
			coh.StartChat ()
			self.TypingCode = true
		end
		local code = self.ActiveCodeEditor:GetText ()
		if #code > 4096 then
			code = string.sub (code, 1, GLib.UTF8.GetSequenceStart (code, 4097) - 1) .. "..."
		end
		coh.SendTypedMessage (code)
	else
		if self.TypingCode then
			coh.FinishChat ()
			coh.SendTypedMessage (true)
			self.TypingCode = false
		end
	end
end