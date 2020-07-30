--
-- Gario Party 13
-- 28/06/20
--
-- State: Board
--

STATE_BOARD = "Board"

GP13_BOARD_CAMERA_ANGLE		= 40
GP13_BOARD_CAMERA_DISTANCE	= 75
MAX_ROUNDS					= 15

Board = Board or {}

GM.AddGameState( STATE_BOARD, {
	OnStart = function( self )
		-- Late joiners
		for k, v in pairs( player.GetAll() ) do
			v:SwitchState( PLAYER_STATE_PLAY )
		end

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:HideFPSController()
		end

		self.Round = ( self.Round or 0 )
		if ( SERVER ) then
			self.Round = self.Round + 1
			if ( self.Round == MAX_ROUNDS ) then
				PrintMessage( HUD_PRINTCENTER, "Last Round!" )
			end
		end
		Turn:Initialize()

		if ( CLIENT ) then
			Board.Scene = LoadScene( "city.json" )

			Music:Play( MUSIC_TRACK_BOARD )
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
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:ShowFPSController()
		end

		if ( CLIENT ) then
			Music:Pause( MUSIC_TRACK_BOARD )
		end
	end,
})

hook.Add( "PostDrawOpaqueRenderables", HOOK_PREFIX .. STATE_BOARD .. "PostDrawOpaqueRenderables", function()
	if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
		-- Clear world
		render.Clear( 0, 0, 0, 255 )
		render.ClearDepth()

		-- Render background scene
		--Board.Scene = LoadScene( "city.json" ) print( "reloading every frame" ) -- TODO TEMP TESTING
		render.SetLightingMode( 2 )
			Board.OriginPos = GP13_BOARD_POS + Vector( 2, 3.25, 0 ) * GP13_BOARD_SCALE
			RenderScene( Board.Scene, Board.OriginPos )
		render.SetLightingMode( 0 )

		-- Render board spaces
		Board:Render()
	end
end )

hook.Add( "PrePlayerDraw", HOOK_PREFIX .. STATE_BOARD .. "PrePlayerDraw", function()
	if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
		return true
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

hook.Add( "HUDPaint", HOOK_PREFIX .. STATE_BOARD .. "_HUDPaint", function()
	if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
		local x = ScrW() / 2
		local y = ScrH() / 32
		local w = ScrW() / 8
		local h = ScrH() / 16
		draw.RoundedBox( 4, x - w / 2, y - h / 2, w, h, COLOUR_WHITE )
		draw.SimpleText( "Round " .. GAMEMODE.GameStates[STATE_BOARD].Round, "CloseCaption_BoldItalic", x, y, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end )
