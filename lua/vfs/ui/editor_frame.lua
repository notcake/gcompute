local self = {}

function self:Init ()
	self:SetTitle ("Editor")

	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Toolbar = vgui.Create ("GToolbar", self)
	self.CodeEditor = vgui.Create ("GCodeEditor", self)
	
	self.Toolbar:AddButton ("Save", function ()
	end):SetIcon ("gui/g_silkicons/disk")
	self.Toolbar:AddButton ("Save All", function ()
	end):SetIcon ("gui/g_silkicons/disk_multiple")
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Cut", function ()
	end):SetIcon ("gui/g_silkicons/cut")
	self.Toolbar:AddButton ("Copy", function ()
	end):SetIcon ("gui/g_silkicons/page_white_copy")
	self.Toolbar:AddButton ("Paste", function ()
	end):SetIcon ("gui/g_silkicons/paste_plain")
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Undo", function ()
	end):SetIcon ("gui/g_silkicons/arrow_undo")
	self.Toolbar:AddButton ("Redo", function ()
	end):SetIcon ("gui/g_silkicons/arrow_redo")
	self.Toolbar:AddSeparator ()
	self.Toolbar:AddButton ("Run Code", function ()
		RunString (self.CodeEditor:GetText ())
	end):SetIcon ("gui/g_silkicons/resultset_next")
	self.Toolbar:AddSeparator ()
	
	self:InvalidateLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Toolbar then
		self.Toolbar:SetPos (2, 21)
		self.Toolbar:SetSize (self:GetWide () - 4, self.Toolbar:GetTall ())
	end
	if self.CodeEditor then
		self.CodeEditor:SetPos (8, 29 + self.Toolbar:GetTall ())
		self.CodeEditor:SetSize (self:GetWide () - 16, self:GetTall () - self.Toolbar:GetTall () - 29)
	end
end

-- Interface
function self:LoadFile (file)
	file:Open (GAuth.GetLocalId (), VFS.OpenFlags.ReadOnly,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						self.CodeEditor:SetText (data)
						fileStream:Close ()
					end
				)
			end
		end
	)
end

vgui.Register ("VFSEditorFrame", self, "DFrame")