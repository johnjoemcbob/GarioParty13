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

RT_Transition = GetRenderTarget( "rt_transition", ScrW(), ScrH() )
MAT_RT_Transition = CreateMaterial( "mat_rt_transition", "UnlitGeneric", {
	["$basetexture"] = RT_Transition:GetName(),
	["$vertexcolor"] = 1
} )
--MAT_ScreenEffect = Material( "pp/bloom" )

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

	Transition.NeedCapture = true
end

function Transition:Finish()
	Transition.Active = false

	--Transition.Frame:Remove()
	--Transition.Frame = nil
end

function Transition:Render()
	if ( self.Active and !self.RenderTargeting ) then
		surface.SetDrawColor( COLOUR_WHITE )

		if ( self.State == STATE_IN ) then
			if ( self.Frame and self.Frame:GetHTMLMaterial() ) then
				render.SetMaterial( self.Frame:GetHTMLMaterial() )
				--render.DrawScreenQuadEx( 0, 0, ScrW(), ScrH() )
			end
		end

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

hook.Add( "PostRender", HOOK_PREFIX .. "PostRender", function()
	-- if ( Transition.NeedCapture ) then
	-- 	local data = render.Capture( {
	-- 		x = 0,
	-- 		y = 0,
	-- 		w = ScrW(),
	-- 		h = ScrH(),
	-- 		quality = 100
	-- 	} )
	-- 	local base64 = util.Base64Encode( data )

	-- 	Transition.Frame = vgui.Create( "DHTML" )
	-- 	Transition.Frame:Dock( FILL )
	-- 	--Transition.Frame:SetWidth( ScrW() )
	-- 	--Transition.Frame:SetHeight( ScrH() )
	-- 	Transition.Frame:SetAlpha( 0 )
	-- 	Transition.Frame:SetMouseInputEnabled( false )
	-- 	Transition.Frame:SetHTML( [[
	-- 		<style type="text/css">
	-- 			body {
	-- 				margin: 0;
	-- 				padding: 0;
	-- 				overflow: hidden;
	-- 			}
	-- 			img {
	-- 				width: 125%;
	-- 				height: 125%;
	-- 			}
	-- 		</style>
			
	-- 		<img src="data:image/jpg;base64,]] .. base64 .. [["> ]]
	-- 	)
	-- 	Transition.NeedCapture = nil
	-- end
end )
