local self = GCompute.IDE.Plugins:Create ("Metastruct")

CreateClientConVar ("gcompute_editor_5ever", 0, true, false)

function self:ctor (ide)
	self.IDE = ide
	self.TypingCode = false
	self.ActiveCodeEditor = nil
	
	self.IDE:AddEventListener ("VisibleChanged", "Metastruct",
		function (_)
			self:UpdateHookedView ()
		end
	)
	self.IDE:AddEventListener ("ActiveViewChanged", "Metastruct",
		function (_)
			self:UpdateHookedView ()
		end
	)
end

timer.Simple (1,
	function ()
		if chatbox then
			chatbox._ShowChat2Box = chatbox._ShowChat2Box or chatbox.ShowChat2Box
			function chatbox.ShowChat2Box (tab)
				pcall (
					function ()
						if GetConVar ("gcompute_editor_5ever"):GetBool () and GCompute and GCompute.IDE and tab == 2 then
							GCompute.IDE.GetInstance ():GetFrame ():SetVisible (true)
							GCompute.IDE.GetInstance ():GetFrame ():MoveToFront ()
						else
							chatbox._ShowChat2Box (tab)
						end
					end
				)
			end
		end
	end
)

function self:dtor ()
	self.IDE:RemoveEventListener ("VisibleChanged", "Metastruct")
	self.IDE:RemoveEventListener ("SelectedContentsChanged", "Metastruct")
	hook.Remove ("PlayerBindPress", "Metastruct")
end

function self:HookCodeEditor (codeEditor)
	if not codeEditor then return end
	
	codeEditor:AddEventListener ("TextChanged", "Metastruct",
		function ()
			self:UpdateChatStatus ()
		end
	)
end

function self:UnhookCodeEditor (codeEditor)
	if not codeEditor then return end
	
	codeEditor:RemoveEventListener ("TextChanged", "Metastruct")
end

function self:UpdateHookedView ()
	local codeEditor = self.IDE:GetActiveCodeEditor ()
	if not codeEditor and
	   self.IDE:GetActiveView () and
	   self.IDE:GetActiveView ():GetType () == "Output" then
		codeEditor = self.IDE:GetActiveView ():GetEditor ()
	end
	if not self.IDE:IsVisible () then
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
		if code:len () > 4096 then
			code = code:sub (1, GLib.UTF8.GetSequenceStart (code, 4097) - 1) .. "..."
		end
		coh.SendTypedMessage (code)
	else
		if self.TypingCode then
			coh.FinishChat ()
			self.TypingCode = false
		end
	end
end