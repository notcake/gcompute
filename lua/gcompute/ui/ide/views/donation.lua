local self = GCompute.IDE.ViewTypes:CreateType ("Donation")

function self:ctor (container)
	self.URL = "http://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=U9PLFRU6AYJPC"
	
	self.HTMLPanel = vgui.Create ("HTML", container)
	self.HTMLPanel.OnCallback = function (_, objectName, methodName, args)
		if objectName == "gcompute" then
			if methodName == "donate" then
				gui.OpenURL (self.URL)
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
	
	self:SetTitle ("Donate!")
	self:SetIcon ("icon16/heart.png")
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