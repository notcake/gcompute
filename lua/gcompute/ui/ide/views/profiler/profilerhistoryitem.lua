local self = {}
GCompute.IDE.Profiler.HistoryItem = GCompute.MakeConstructor (self, Gooey.HistoryItem)

function self:ctor (view, subViewId)
	self.View = view
	self.SubViewId = subViewId
end

-- HistoryItem
function self:MoveForward ()
	self:Restore ()
end

function self:MoveBack ()
	self:Restore ()
end

-- HistoryItem
function self:GetSubViewId ()
	return self.SubViewId
end

function self:GetView ()
	return self.View
end

function self:GetSubView ()
	return self.View:GetSubView (self:GetSubViewId ())
end

function self:GetSubViewId ()
	return self.SubViewId
end

function self:SetView (view)
	self.View = view
end

function self:SetSubViewId (subViewId)
	self.SubViewId = subViewId
end

function self:Restore ()
	if self:GetSubView () then
		self:GetSubView ():RestoreHistoryItem (self)
	end
	
	self.View:SetActiveSubView (self.SubViewId)
end