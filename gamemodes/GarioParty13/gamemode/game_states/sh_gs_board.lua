--
-- Gario Party 13
-- 28/06/20
--
-- State: Board
--

STATE_BOARD = "Board"

GP13_BOARD_CAMERA_ANGLE = 40
GP13_BOARD_CAMERA_DISTANCE = 75

Board = Board or {}

GM.AddGameState( STATE_BOARD, {
	OnStart = function( self )
		for k, ply in pairs( player.GetAll() ) do
			ply:HideFPSController()
		end

		self.Round = ( self.Round or 0 ) + 1
		Turn:Initialize()

		if ( CLIENT ) then
			Board.Scene = LoadScene( "city.json" )
		end
	end,
	OnThink = function( self )
		local next = Turn:Think()
		if ( !next ) then
			Dice:Hide()
			GAMEMODE:SwitchState( STATE_MINIGAME_INTRO )
		end
	end,
	OnFinish = function( self )
		for k, ply in pairs( player.GetAll() ) do
			ply:ShowFPSController()
		end
	end,
})

hook.Add( "PostDrawOpaqueRenderables", HOOK_PREFIX .. STATE_BOARD .. "PostDrawOpaqueRenderables", function()
	if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
		-- Clear world
		render.Clear( 0, 0, 0, 255 )
		render.ClearDepth()

		-- Render background scene
		Board.Scene = LoadScene( "city.json" ) -- TODO TEMP TESTING
		render.SetLightingMode( 2 )
			RenderScene( Board.Scene, GP13_BOARD_POS + Vector( 2, 3.25, 0 ) * GP13_BOARD_SCALE )
		render.SetLightingMode( 0 )

		-- Render board spaces
		Board:Render()
	end
end )

hook.Add( "CalcView", HOOK_PREFIX .. STATE_BOARD .. "_CalcView", function( self, ply, pos, angles, fov )
	if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
		local center = GP13_BOARD_POS
			local minx, maxx, miny, maxy
			for x, ys in pairs( Board.Data ) do
				if ( !minx or x < minx ) then
					minx = x
				end
				if ( !maxx or x > maxx ) then
					maxx = x
				end
				for y, _ in pairs( ys ) do
					if ( !miny or y < miny ) then
						miny = y
					end
					if ( !maxy or y > maxy ) then
						maxy = y
					end
				end
			end
			center = center + Vector( miny + ( maxy - miny ) / 2, minx + ( maxx - minx ) / 2 ) * GP13_BOARD_SCALE
		local dist = math.max( maxx - minx, maxy - miny )
		local angles = Angle( GP13_BOARD_CAMERA_ANGLE, 0, 0 )
		local view = {}
			view.origin = center + angles:Forward() * -GP13_BOARD_CAMERA_DISTANCE * dist
			view.angles = angles
			view.fov = 90
			view.drawviewer = true
		return view
	end
end )
