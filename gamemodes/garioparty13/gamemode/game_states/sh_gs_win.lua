--
-- Gario Party 13
-- 18/07/20
--
-- State: Win
--

STATE_WIN = "Win"

GP13_WIN_POS				= Vector( 0, 0, 0 )
GP13_WIN_CAMERA_OFFSET		= Vector( 300, 400, 100 )
GP13_WIN_SCALE				= 100
GP13_WIN_CAMERA_ANGLE		= 20
GP13_WIN_CAMERA_DISTANCE	= 75

local TIME_RESETTOLOBBY		= 15

Win = Win or {}

local taunts = {
	--"taunt_muscle",
	"taunt_dance",
	--"taunt_laugh",
	--"taunt_robot",
	--"taunt_persistence",
}

GM.AddGameState( STATE_WIN, {
	OnStart = function( self )
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:HideFPSController()
		end

		if ( CLIENT ) then
			Win.Scene = LoadScene( "city.json" )

			-- Reset player board models
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				if ( ply.BoardModel and ply.BoardModel:IsValid() ) then
					ply.NextPlay = 0
				end
			end
		end

		-- Calculate winners
		self.Winners = {}
			local scores = {}
				for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
					scores[v] = v:GetScore()
				end
			local placing = 1
			for ply, score in SortedPairsByValue( scores, true ) do
				self.Winners[placing] = ply
				placing = placing + 1
				if ( placing > 3 ) then break end
			end

		-- Timer to reset back to lobby
		timer.Simple( TIME_RESETTOLOBBY, function()
			GAMEMODE:SwitchState( STATE_LOBBY )
			timer.Simple( 1, function()
				RunConsoleCommand( "changelevel", "gm_construct" )
			end )
		end )
		self.StartTime = CurTime()

		Dice.Current = nil
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:ShowFPSController()
		end
	end,
})

hook.Add( "PostDrawOpaqueRenderables", HOOK_PREFIX .. STATE_WIN .. "PostDrawOpaqueRenderables", function()
	if ( GAMEMODE:GetStateName() == STATE_WIN ) then
		local self = GAMEMODE.GameStates[STATE_WIN]

		-- Clear world
		render.Clear( 0, 0, 0, 255 )
		render.ClearDepth()

		-- Render background scene
		local pos = GP13_WIN_POS + Vector( 2, 3.25, 0 ) * GP13_WIN_SCALE
		Win.Scene = LoadScene( "win.json" ) -- TODO TEMP TESTING
		render.SetLightingMode( 2 )
			RenderScene( Win.Scene, pos )

			-- Render player podium places
			-- TODO sort
			local placing = 1
			for k, ply in pairs( self.Winners ) do
				if ( ply.BoardModel and ply.BoardModel:IsValid() ) then
					ply.BoardModel:SetPos( pos + Win.Scene["place" .. placing][2] )
					ply.BoardModel:DrawModel()

					-- Animate
					-- if ( ply.BoardModel.NextPlay <= CurTime() ) then
					-- 	ply.BoardModel:ResetSequence( taunts[math.random( 1, #taunts )] )
					-- 	ply.BoardModel.Delay = ply.BoardModel:SequenceDuration()
					-- 	ply.BoardModel.NextPlay = CurTime() + ply.BoardModel.Delay
					-- end
					-- ply.BoardModel:FrameAdvance()
				end
				placing = placing + 1
				if ( placing > 3 ) then break end
			end
		render.SetLightingMode( 0 )
	end
end )

hook.Add( "CalcView", HOOK_PREFIX .. STATE_WIN .. "_CalcView", function( self, ply, pos, angles, fov )
	if ( GAMEMODE:GetStateName() == STATE_WIN ) then
		local center = GP13_WIN_POS + GP13_WIN_CAMERA_OFFSET
		local dist = 1
		local angles = Angle( GP13_WIN_CAMERA_ANGLE, 0, 0 )
		local view = {}
			view.origin = center + angles:Forward() * -GP13_WIN_CAMERA_DISTANCE * dist
			view.angles = angles
			view.fov = 90
			view.drawviewer = true
		return view
	end
end )

hook.Add( "HUDPaint", HOOK_PREFIX .. STATE_WIN .. "_HUDPaint", function()
	if ( GAMEMODE:GetStateName() == STATE_WIN ) then
		local self = GAMEMODE.GameStates[STATE_WIN]

		-- Top players
		local margin = ScrW() / 32
		local x = margin
		local y = margin
		local w = ScrW() / 8
		local h = ScrH() / 16
		local between = 96
		local outlinewidth = 2
		local colour		= COLOUR_WHITE
		local outlinecolour	= COLOUR_BLACK
		--draw.RoundedBox( 4, x - w / 2, y - h / 2, w, h, COLOUR_WHITE )
		if ( self.Winners[1] and self.Winners[1]:IsValid() ) then
			draw.SimpleTextOutlined( self.Winners[1]:Nick() .. " Wins!!", "MinigameTitle", x, y, self.Winners[1]:GetColour(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlinewidth, outlinecolour )
		end
		if ( self.Winners[2] and self.Winners[2]:IsValid() ) then
			draw.SimpleTextOutlined( "2nd: " .. self.Winners[2]:Nick(), "DermaLarge", x, y + between * 1, self.Winners[2]:GetColour(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlinewidth, outlinecolour )
		end
		if ( self.Winners[3] and self.Winners[3]:IsValid() ) then
			draw.SimpleTextOutlined( "3rd: " .. self.Winners[3]:Nick(), "DermaLarge", x, y + between * 1.5, self.Winners[3]:GetColour(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlinewidth, outlinecolour )
		end

		-- Full scores in bottom left
		local x = ScrW() - margin
		local y = ScrH() - margin
		local between = 64
		local font = "DermaLarge"
			surface.SetFont( font )
			local tw, th = surface.GetTextSize( "HEY" )
		for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			draw.SimpleText( v:Nick() .. ": " .. v:GetScore(), font, x, y - ( h + between * 2 ) * ( k - 1 ) / ( #PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) + 1 ), COLOUR_BLACK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )	
		end

		-- Timer
		local font = "DermaLarge"
		local width = ScrW() / 8
		local height = ScrH() / 16
		local x = ScrW() / 32
		local y = ScrH() - x
		local border = height / 8
		local elapsed = CurTime() - self.StartTime
		local left = math.Clamp( TIME_RESETTOLOBBY - elapsed, -1, TIME_RESETTOLOBBY )
		local percent = left / TIME_RESETTOLOBBY
		if ( left >= 0 ) then
			surface.SetDrawColor( COLOUR_BLACK )
			surface.DrawRect( x, y - height, width, height )
			surface.SetDrawColor( colour )
			surface.DrawRect( x, y - height, width * percent, height )
			draw.SimpleTextOutlined( math.ceil( left ), font, x + width / 2, y - height / 2, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlinewidth, outlinecolour )
		end
	end
end )
