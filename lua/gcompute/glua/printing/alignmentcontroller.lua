local self = {}
GCompute.GLua.Printing.AlignmentController = GCompute.MakeConstructor (self)

local pool = {}
local function PoolAllocate ()
	if #pool == 0 then return {} end
	local t = pool [#pool]
	pool [#pool] = nil
	return t
end

local function PoolFree (t)
	pool [#pool + 1] = t
end

function self:ctor ()
	self.Alignments     = PoolAllocate ()
	self.AlignmentStack = PoolAllocate ()
end

function self:AddAlignment (name, n)
	self.Alignments [name] = self.Alignments [name] or 0
	self.Alignments [name] = math.max (self.Alignments [name], n)
end

function self:Clear ()
	self.Alignments = PoolAllocate ()
end

function self:GetAlignment (name)
	return self.Alignments [name] or 0
end

-- Alignment stack
function self:PushAlignments ()
	self.AlignmentStack [#self.AlignmentStack + 1] = self.Alignments
	self.Alignments = PoolAllocate ()
end

function self:PopDiscardAlignments ()
	self.Alignments = self.AlignmentStack [#self.AlignmentStack]
	self.AlignmentStack [#self.AlignmentStack] = nil
end

function self:PopMergeAlignments ()
	local alignments = self.AlignmentStack [#self.AlignmentStack]
	for k, v in pairs (self.Alignments) do
		alignments [k] = alignments [k] or 0
		alignments [k] = math.max (alignments [k], v)
		self.Alignments [k] = nil
	end
	
	PoolFree (self.Alignments)
	
	self.Alignments = alignments
	self.AlignmentStack [#self.AlignmentStack] = nil
end