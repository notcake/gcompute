local self = GCompute.Editor.Plugins:Create ("Metastruct")

CreateClientConVar ("gcompute_editor_5ever", 1, true, false)

function self:ctor (editor)
	self.Editor = editor
	self.TypingCode = false
	self.ActiveCodeEditor = nil
	
	self.Editor:AddEventListener ("VisibleChanged", "Metastruct",
		function (_)
			self:UpdateHookedContents ()
		end
	)
	self.Editor:AddEventListener ("SelectedContentsChanged", "Metastruct",
		function (_)
			self:UpdateHookedContents ()
		end
	)
end

timer.Simple (1,
	function ()
		if chatbox then
			chatbox._ShowChat2Box = chatbox._ShowChat2Box or chatbox.ShowChat2Box
			function chatbox.ShowChat2Box (tab)
				pcall (function ()
					if GetConVar ("gcompute_editor_5ever"):GetBool () and GCompute and GCompute.Editor and tab == 2 then
						GCompute.Editor:GetFrame ():SetVisible (true)
						GCompute.Editor:GetFrame ():MoveToFront ()
					else
						chatbox._ShowChat2Box (tab)
					end
				end)
			end
		end
	end
)

function self:dtor ()
	self.Editor:RemoveEventListener ("VisibleChanged", "Metastruct")
	self.Editor:RemoveEventListener ("SelectedContentsChanged", "Metastruct")
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

function self:UpdateHookedContents ()
	local codeEditor = self.Editor:GetActiveCodeEditor ()
	if not self.Editor:IsVisible () then
		codeEditor = nil
	end
	
	self:UnhookCodeEditor (self.ActiveCodeEditor)
	self:HookCodeEditor (codeEditor)
	self.ActiveCodeEditor = codeEditor
	
	self:UpdateChatStatus ()
end

function self:UpdateChatStatus ()
	if not COH2 then return end
	
	if self.ActiveCodeEditor then
		if not self.TypingCode then
			COH2:ChatStart ()
			self.TypingCode = true
		end
		local code = self.ActiveCodeEditor:GetText ()
		if code:len () > 1024 then
			code = code:sub (1, GLib.UTF8.GetSequenceStart (code, 1025) - 1) .. "..."
		end
		COH2:ChatUpdate (code)
	else
		if self.TypingCode then
			COH2:ChatStop ()
			self.TypingCode = false
		end
	end
end