--
-- Gario Party 13
-- 02/07/20
--
-- Clientside State Transition
--

local HOOK_PREFIX = HOOK_PREFIX .. "TRANSITION_"

Transition = Transition or {}

TRANSITION_CIRCLES		= 12
TRANSITION_CIRCLESEGS	= 32

local STATE_IN		= 0
local STATE_STAY	= 1
local STATE_OUT		= 2
local STATE_LOAD	= 3

function Transition:Start( state )
	Transition.Active = true
	Transition.StartTime = CurTime()
	Transition.Duration = TRANSITION_DURATION
	Transition.Circles = {}
	for circ = 1, TRANSITION_CIRCLES do
		table.insert( Transition.Circles, {
			x = math.random( 0, ScrW() ) - ScrW() / 2,
			y = math.random( 0, ScrH() ) - ScrH() / 2,
			off = 0,
			radius = 0,
		} )
	end
	Transition.State = state or STATE_IN
end

function Transition:Render()
	if ( self.Active and !self.RenderTargeting ) then
		surface.SetDrawColor( COLOUR_WHITE )

		for k, circle in pairs( self.Circles ) do
			draw.NoTexture()
			draw.Circle( circle.x + circle.x * circle.off + ScrW() / 2, circle.y + circle.y * circle.off + ScrH() / 2, circle.radius, TRANSITION_CIRCLESEGS, 0 )
		end
	end
end

function Transition:Update()
	if ( self.Active ) then
		local progress = ( CurTime() - self.StartTime ) / self.Duration

		-- Update state
		if ( self.State == STATE_IN ) then
			for k, circle in pairs( self.Circles ) do
				circle.radius = ScrW() * progress
				circle.off = ( 1 - progress ) * 5
			end
		elseif ( self.State == STATE_OUT ) then
			for k, circle in pairs( self.Circles ) do
				circle.radius = ScrW() * ( 1 - progress )
				circle.off = progress * 5
			end
		else
			for k, circle in pairs( self.Circles ) do
				circle.radius = ScrW()
				circle.off = 0
			end
		end

		-- Finish state
		if ( progress >= 1 ) then
			if ( self.State == STATE_IN ) then
				self.State = STATE_STAY
				self.StartTime = CurTime()
				self.Duration = 0.2
			elseif ( self.State == STATE_STAY ) then
				self.State = STATE_OUT
				self.StartTime = CurTime()
				self.Duration = TRANSITION_DURATION
			elseif ( self.State == STATE_OUT ) then
				self:Finish()
			end
		end
	end
end

function Transition:Finish()
	self.Active = false
end

-- Gamemode Hooks
hook.Add( "Think", HOOK_PREFIX .. "Think", function()
	Transition:Update()
end )

-- Moved to sh_minigames_hooks
-- hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
-- 	Transition:Render()
-- end )
