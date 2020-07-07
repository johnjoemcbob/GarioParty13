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

function Transition:Start()
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
	Transition.State = STATE_IN
end

function Transition:Finish()
	Transition.Active = false
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

hook.Add( "Think", HOOK_PREFIX .. "Think", function()
	if ( Transition.Active ) then
		local progress = ( CurTime() - Transition.StartTime ) / Transition.Duration

		-- Update state
		if ( Transition.State == STATE_IN ) then
			for k, circle in pairs( Transition.Circles ) do
				circle.radius = ScrW() * progress
				circle.off = ( 1 - progress ) * 5
			end
		elseif ( Transition.State == STATE_OUT ) then
			for k, circle in pairs( Transition.Circles ) do
				circle.radius = ScrW() * ( 1 - progress )
				circle.off = progress * 5
			end
		end

		-- Finish state
		if ( progress >= 1 ) then
			if ( Transition.State == STATE_IN ) then
				Transition.State = STATE_STAY
				Transition.StartTime = CurTime()
				Transition.Duration = 0.2
			elseif ( Transition.State == STATE_STAY ) then
				Transition.State = STATE_OUT
				Transition.StartTime = CurTime()
				Transition.Duration = TRANSITION_DURATION
			elseif ( Transition.State == STATE_OUT ) then
				Transition:Finish()
			end
		end
	end
end )

hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
	Transition:Render()
end )
