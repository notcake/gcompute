local self = {}
GCompute.EPOE = GCompute.MakeConstructor (self)

function self:ctor ()
	self.LineBuffer =
	{
		{
			Text = ""
		}
	}
	
	hook.Add ("EPOE", "GCompute.EPOE",
		function (message, colorId, color)
			if not color then
				if colorId == 2 then
					color = GLib.Colors.IndianRed
				elseif colorId == 4 then
					color = GLib.Colors.White
				elseif colorId == 8 then
					color = GLib.Colors.SandyBrown
				end
			end
			
			local lines = message:Split ("\n")
			
			for i = 1, #lines do
				if i > 1 then
					self.LineBuffer [#self.LineBuffer + 1] =
					{
						Text = ""
					}
				end
				
				local line = self.LineBuffer [#self.LineBuffer]
				line.Text = line.Text .. lines [i]
				line [#line + 1] =
				{
					Text  = lines [i],
					Color = color
				}
			end
			
			while #self.LineBuffer > 1 do
				self:DispatchEvent ("LineReceived", self.LineBuffer [1])
				table.remove (self.LineBuffer, 1)
			end
		end
	)
	
	GCompute.AddEventListener ("Unloaded", self:GetHashCode (),
		function ()
			self:dtor ()
		end
	)
	
	GCompute.EventProvider (self)
end

function self:dtor ()
	hook.Remove ("EPOE", "GCompute.EPOE")
	GCompute.RemoveEventListener ("Unloaded", self:GetHashCode ())
end

GCompute.EPOE = GCompute.EPOE ()