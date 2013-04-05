local self, info = GCompute.IDE.ViewTypes:CreateType ("Donation")
info:SetAutoCreate (true)
info:SetDefaultLocation ("Bottom/Right")
self.Title           = "Donate!"
self.Icon            = "icon16/heart.png"
self.Hideable        = true

function self:ctor (container)
	self.URL = "http://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=U9PLFRU6AYJPC"
	
	self.HTMLPanel = vgui.Create ("GHTML", container)
	self.HTMLPanel.OnCallback = function (_, objectName, methodName, args)
		if objectName == "gcompute" then
			if methodName == "donate" then
				GLib.CallDelayed (
					function ()
						gui.OpenURL (self.URL)
					end
				)
			end
		end
	end
	self.HTMLPanel:NewObjectCallback ("gcompute", "donate")
	self.HTMLPanel:SetHTML (
		[[
			<html>
				<head>
				</head>
				<body bgcolor="white">
					<div style="font-family: Verdana; font-size: 12; text-align: center; vertical-align: middle;">
						If you've found GCompute useful, or would like to support further development, consider donating!
						<br>
						<br>
						<br>
						<img src="https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif" style="cursor: pointer;" onclick="gcompute.donate ()">
					</div>
				</body>
			</html>
		]]
	)
end

function self:dtor ()
	if self.HTMLPanel and self.HTMLPanel:IsValid () then
		self.HTMLPanel:Remove ()
	end
	self.HTMLPanel = nil
end

-- Persistance
function self:LoadSession (inBuffer)
end

function self:SaveSession (outBuffer)
end