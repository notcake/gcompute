function GCompute.IDE.Toolbar (self)
	local toolbar = vgui.Create ("GToolbar", self)
	
	-- File Operations
	toolbar:AddButton ("New")
		:SetAction ("New")
	toolbar:AddButton ("Open")
		:SetAction ("Open")
	toolbar:AddButton ("Save")
		:SetAction ("Save")
	toolbar:AddButton ("Save All")
		:SetAction ("Save All")
	
	toolbar:AddSeparator ()
	
	-- Clipboard
	toolbar:AddButton ("Cut")
		:SetEnabled (false)
		:SetAction ("Cut")
	toolbar:AddButton ("Copy")
		:SetEnabled (false)
		:SetAction ("Copy")
	toolbar:AddButton ("Paste")
		:SetAction ("Paste")
	
	toolbar:AddSeparator ()
	
	-- Undo / Redo
	-- Don't register click handlers for undo / redo.
	-- They should get registered with an UndoRedoController which will
	-- register click handlers.
	toolbar:AddSplitButton ("Undo")
		:SetIcon ("icon16/arrow_undo.png")
		:AddEventListener ("DropDownClosed",
			function (_, dropDownMenu)
				dropDownMenu:Clear ()
			end
		)
		:AddEventListener ("DropDownOpening",
			function (_, dropDownMenu)
				local undoRedoStack = self:GetActiveUndoRedoStack ()
				if not undoRedoStack then return end
				local stack = undoRedoStack:GetUndoStack ()
				for i = 0, 19 do
					local item = stack:Peek (i)
					if not item then return end
					
					dropDownMenu:AddItem (item:GetDescription ())
						:AddEventListener ("Click",
							function ()
								undoRedoStack:Undo (i + 1)
							end
						)
				end
			end
		)
	toolbar:AddSplitButton ("Redo")
		:SetIcon ("icon16/arrow_redo.png")
		:AddEventListener ("DropDownClosed",
			function (_, dropDownMenu)
				dropDownMenu:Clear ()
			end
		)
		:AddEventListener ("DropDownOpening",
			function (_, dropDownMenu)
				local undoRedoStack = self:GetActiveUndoRedoStack ()
				if not undoRedoStack then return end
				local stack = undoRedoStack:GetRedoStack ()
				for i = 0, 19 do
					local item = stack:Peek (i)
					if not item then return end
					
					dropDownMenu:AddItem (item:GetDescription ())
						:AddEventListener ("Click",
							function ()
								undoRedoStack:Redo (i + 1)
							end
						)
				end
			end
		)
	
	toolbar:AddSeparator ()
	
	toolbar:AddButton ("Run Code")
		:SetAction ("Run Code")
	
	toolbar:AddSeparator ()
	
	toolbar:AddButton ("Namespace Browser")
		:SetIcon ("icon16/application_side_list.png")
		:AddEventListener ("Click",
			function ()
				if not self.RootNamespaceBrowserView then
					self.RootNamespaceBrowserView = self:CreateNamespaceBrowserView (namespace)
					self.RootNamespaceBrowserView:AddEventListener ("Removed",
						function ()
							self.RootNamespaceBrowserView = nil
						end
					)
				end
				self.RootNamespaceBrowserView:Select ()
			end
		)
	
	toolbar:AddSeparator ()
	
	toolbar:AddButton ("Reload GCompute")
		:SetIcon ("icon16/arrow_refresh.png")
		:AddEventListener ("Click",
			function ()
				RunConsoleCommand ("gcompute_reload")
				RunConsoleCommand ("gcompute_show_ide")
			end
		)
	
	toolbar:AddSeparator ()
	
	toolbar:AddButton ("Stress Test")
		:SetIcon ("icon16/exclamation.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				codeEditor:SetText (
[[A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9
A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:0:1:2:3:4:5:6:7:8:9]]
				)
			end
		)
	toolbar:AddButton ("Unicode Stress Test")
		:SetIcon ("icon16/exclamation.png")
		:AddEventListener ("Click",
			function ()
				local codeEditor = self:GetActiveCodeEditor ()
				if not codeEditor then return end
				local lines = {}
				for y = 0, 255 do
					local bits = {}
					bits [#bits + 1] = string.format ("%04x: ", y * 256)
					for x = 0, 255 do
						if y * 256 + x == 0 then
							bits [#bits + 1] = " "
						else
							bits [#bits + 1] = GLib.UTF8.Char (y * 256 + x)
						end
					end
					bits [#bits + 1] = "\n"
					lines [#lines + 1] = table.concat (bits)
				end
				codeEditor:SetText (table.concat (lines))
			end
		)
	
	return toolbar
end