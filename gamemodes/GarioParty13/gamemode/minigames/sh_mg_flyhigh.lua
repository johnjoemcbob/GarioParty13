--
-- Gario Party 13
-- 30/06/20
--
-- Game: Fly High
--

local SPEEDS = { 1, 1 }

local MODEL

local FLYHIGH_TIMELIMIT	= 40

local NAME = "Fly High"
GM.AddGame( NAME, "Default", {
	Author = "johnjoemcbob",
	TagLine = "High Fly",
	Instructions = "Highest jump wins!\nEach high jump increases your max speed",
	Controls = "Swim around to gain speed!\nJump out of the water to gain points",
	GIF = "https://i.imgur.com/Uhg9L3R.gif",
	Colour = Color( 100, 150, 255, 255 ),

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!

		self:StartConstants()
		self:AddConstant( "MODEL_FISH"			, "MODEL"	, "models/ichthyosaur.mdl", {}, function( self, val )
			if ( CLIENT ) then
				self:CreateClientModel()
			end
		end )
		self:AddConstant( "HEIGHT_MIN"			, "NUMBER"	, -830 )
		self:AddConstant( "HEIGHT_WATER"		, "NUMBER"	, 0 )
		self:AddConstant( "HEIGHT_MAX"			, "NUMBER"	, 9912 )
		self:AddConstant( "SPEED_MIN"			, "NUMBER"	, 1000 )
		self:AddConstant( "SPEED_STARTMAX"		, "NUMBER"	, 5000 )
		self:AddConstant( "SPLASH_REQUIRED"		, "NUMBER"	, 4000000 )
		self:AddConstant( "SPLASH_BOOSTMAXSPEED", "NUMBER"	, 1000 )
		self:AddConstant( "SPEED_INCREASE"		, "NUMBER"	, 500 )
		self:AddConstant( "SPEED_FISHLERP"		, "NUMBER"	, 5 )
		self:AddConstant( "SPEED_DIE"			, "NUMBER"	, 50 )
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		
		-- if ( SERVER ) then
		-- 	timer.Simple( FLYHIGH_TIMELIMIT, function()
		-- 		if ( GAMEMODE:GetStateName() == STATE_MINIGAME and GAMEMODE.GameStates[STATE_MINIGAME].Minigame == NAME ) then
		-- 			-- Find max scoring player
		-- 			local ply = nil
		-- 				local maxscore = -1
		-- 				for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
		-- 					local score = v:GetNWInt( "Score", 0 )
		-- 					if ( score > maxscore ) then
		-- 						ply = v
		-- 						maxscore = score
		-- 					end
		-- 				end
		-- 			self:Win( ply )
		-- 		end
		-- 	end )
		-- end

		self.StartTime = CurTime()
	end,
	Destroy = function( self )
	end,
	PlayerJoin = function( self, ply )
		if ( CLIENT ) then
			ply.FlyHigh_FishAngle = Angle( 0, 0, 0 )

			if ( ply == LocalPlayer() ) then
				Music:Play( MUSIC_TRACK_FLYHIGH )
			end
		end
		if ( SERVER ) then
			ply:SetJumpPower( 0 )

			-- Networked variables
			ply:SetNWFloat( "Score", ply:GetNWFloat( "Score", 0 ) )
		end
	end,
	PlayerSpawn = function( self, ply )
		if ( SERVER ) then
			ply:SetModel( "models/alyx_emptool_prop.mdl" ) -- Set to tiny model "invisible"
			ply:SetModelScale( 0.1 )

			ply:SetWalkSpeed( ply.OldWalkSpeed )
			ply:SetRunSpeed( ply.OldRunSpeed )
			ply:SetNWFloat( "MaxSpeed", self["SPEED_STARTMAX"] ) -- Reset on rejoin?

			-- Spawn
			ply:SetPos( Vector( math.random( -2105, 690 ), math.random( 2267, 6144 ), -170 ) )
		end
	end,
	Think = function( self )
		if ( self.StartTime + FLYHIGH_TIMELIMIT <= CurTime() ) then
			-- Find max scoring player
			local ply = nil
				local maxscore = -1
				for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
					local score = v:GetNWInt( "Score", 0 )
					if ( score > maxscore ) then
						ply = v
						maxscore = score
					end
				end
			self:Win( ply )
		end
	end,
	PlayerThink = function( self, ply )
		if ( CLIENT ) then
			if ( ply:Alive() and ply:GetNWFloat( "Score" ) <= ply:GetPos().z ) then
				GAMEMODE.EmitChainPitchedSound(
					"FlyHigh",
					ply,
					Sound_OrchestraHit,
					75,
					0.5,
					100,
					20,
					5,
					0.5,
					2
				)
			end
		end

		if ( SERVER ) then
			if ( ply:WaterLevel() >= 2 ) then
				-- Increase the players speed when underwater and swimming around
				local incr = -1
					if ( ply:GetAbsVelocity() != Angle():Up() and ply:GetAbsVelocity():LengthSqr() >= 10000 ) then
						incr = 1
					end
				local speed = ply:GetWalkSpeed()
				speed = math.Clamp( speed + FrameTime() * self["SPEED_INCREASE"] * incr, self["SPEED_MIN"], ply:GetNWFloat( "MaxSpeed", self["SPEED_STARTMAX"] ) )

				ply:SetWalkSpeed( speed )
				ply:SetRunSpeed( speed )

				ply:SetHealth( math.min( ply:Health() + self["SPEED_DIE"] * 1.5 * FrameTime(), ply:GetMaxHealth() ) )

				-- Splash from great height - get faster!
				if ( ply.FlyHighState == "Air" and ply:GetVelocity():LengthSqr() > self["SPLASH_REQUIRED"] ) then
					ply:SetNWFloat( "MaxSpeed", ply:GetNWFloat( "MaxSpeed", self["SPEED_STARTMAX"] ) + self["SPLASH_BOOSTMAXSPEED"] )

					GAMEMODE.EmitChainPitchedSound(
						"FlyHigh",
						ply,
						Sound_OrchestraHit,
						75,
						0.4,
						100,
						20,
						5,
						0,
						0
					)
				end

				ply.FlyHighState = "Water"
			else
				-- If out of water, start tracking maximum height
				if ( ply:Alive() and ply.FlyHighState != "Ground" ) then
					local maxheight = math.max( ply:GetNWFloat( "Score" ), ply:GetPos().z )
					ply:SetNWFloat( "Score", maxheight )
				end

				-- Suffocate if running on land
				if ( ply:IsOnGround() ) then
					ply:TakeDamage( self["SPEED_DIE"] * FrameTime(), ply, ply )
					
					ply:SetWalkSpeed( ply.OldWalkSpeed )
					ply:SetRunSpeed( ply.OldRunSpeed )
					ply:SetNWFloat( "MaxSpeed", self["SPEED_STARTMAX"] ) -- Reset on rejoin?

					ply.FlyHighState = "Ground"
				end

				if ( ply.FlyHighState != "Ground" ) then
					ply.FlyHighState = "Air"
				end
			end
		end
	end,
	PlayerDeath = function( self, victim, inflictor, attacker )
		victim:SetNWFloat( "Score", 0 )
		victim:SetNWFloat( "MaxSpeed", 0 )
	end,
	HUDPaint = function( self )
		-- Timer
		local colour = GAMEMODE.ColourPalette[LocalPlayer():GetNWInt( "Colour" )]
		local font = "DermaLarge"
		local width = ScrW() / 4
		local height = ScrH() / 16
		local x = ScrW() / 2
		local y = height
		local border = height / 8
		local elapsed = ( CurTime() - self.StartTime )
		local time = FLYHIGH_TIMELIMIT - elapsed
		local percent = time / FLYHIGH_TIMELIMIT
		if ( time >= 0 ) then
			surface.SetDrawColor( COLOUR_BLACK )
			surface.DrawRect( x - width / 2, y - height / 2, width, height )
			surface.SetDrawColor( colour )
			surface.DrawRect( x - width / 2, y - height / 2, width * percent, height )
			draw.SimpleText( math.ceil( time ), font, x, y, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		-- Speed bar
		local maxspeed = LocalPlayer():GetNWFloat( "MaxSpeed", self["SPEED_STARTMAX"] )
		local x = ScrW() / 2
		local y = ScrH() / 16 * 15
		local width = ScrW() / 8
			width = width + ( ScrW() / 4 / 2 / self["SPEED_STARTMAX"] ) * maxspeed
		local height = ScrH() / 16
		local normalized = ( LocalPlayer():GetWalkSpeed() - self["SPEED_MIN"] ) / ( maxspeed - self["SPEED_MIN"] )
		draw.RoundedBox( 8, x - width / 2, y - height / 2, width, height, Color( 255, 255, 255, 128 ) )
		draw.RoundedBox( 8, x - width / 2, y - height / 2, width * normalized, height, Color( 50, 100, 255, 255 ) )

		-- Heights panel
		local heights = { self["HEIGHT_MIN"], self["HEIGHT_WATER"], self["HEIGHT_MAX"] }
		local function gety( z )
			local ydist = heights[3] - heights[1]
			local rangemult = 0.8
			local rangeoff = 0.9
			return ScrH() * rangeoff - ( ScrH() * rangemult * ( z - heights[1] ) / ydist )
		end

		local x = ScrW()

		for ply, v in pairs( self.Players ) do
			local name = ply:Nick()
				if ( ply == LocalPlayer() ) then
					name = "Me"
				end
			local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
				colour.a = 128

			local border = 12

			-- Draw max height
			local val = math.ceil( ply:GetNWFloat( "Score" ) )
			local y = gety( val )
			local txt = val .. " - " .. name
			local font = "DermaDefault"
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
			draw.RoundedBox( 8, x - width, y - height / 2, width, height, colour ) -- 0, 0 is Screen top left
			draw.SimpleText( txt, font, x - width / 2, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			-- Draw current height
			local val = math.ceil( ply:GetPos().z )
			local x = x - 64
			local y = gety( val )
			local txt = name .. " " .. val
			local font = "DermaDefault"
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
			draw.RoundedBox( 8, x - width / 2, y - height / 2, width, height, colour ) -- 0, 0 is Screen top left
			draw.SimpleText( txt, font, x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end,
	Scoreboard = function( self, ply, row )
		local game = Label( math.ceil( ply:GetNWFloat( "Score" ) ), row )
		game:SetTextColor( Color( 0, 0, 255, 255 ) )
		game:Dock( LEFT )
	end,
	PostPlayerDraw = function( self, ply )
		-- From: https://wiki.facepunch.com/gmod/GM:PostPlayerDraw
		if not IsValid(ply) or not ply:Alive() then return end
		if ( !MODEL or !MODEL:IsValid() ) then self:CreateClientModel() end

		local attach = { Pos = ply:GetPos(), Ang = Angle( 0, 0, 0 ) }

		local pos = attach.Pos
		local ang
			local targetang = attach.Ang
				if ( ply:GetAbsVelocity():LengthSqr() != 0 ) then
					targetang = ply:GetVelocity():Angle()
				end
			if ( ply.FlyHigh_FishAngle == nil ) then
				ply.FlyHigh_FishAngle = targetang
			end
			ply.FlyHigh_FishAngle = LerpAngle( FrameTime() * self["SPEED_FISHLERP"] * ply:GetWalkSpeed() / self["SPEED_MIN"], ply.FlyHigh_FishAngle, targetang )
		ang = ply.FlyHigh_FishAngle

		pos = pos + (ang:Forward() * 20)
		pos = pos + (ang:Up() * 20)
		MODEL:SetPos(pos)
		MODEL:SetAngles(ang)

		MODEL:SetModelScale(0.5, 0)
		MODEL:SetRenderOrigin(pos)
		MODEL:SetRenderAngles(ang)
			MODEL:SetupBones()
			MODEL:DrawModel()
		MODEL:SetRenderOrigin()
		MODEL:SetRenderAngles()
		MODEL:SetModelScale(1, 0)
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Third person view!
		local view = {}
		view.origin = pos-(angles:Forward()*200) - angles:Up()*50
		view.angles = angles
		view.fov = fov
		view.drawviewer = true

		return view
	end,
	PlayerLeave = function( self, ply )
		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_FLYHIGH )
			end
		end
	end,

	-- Custom functions
	CreateClientModel = function( self )
		MODEL = ClientsideModel( self["MODEL_FISH"] )
		MODEL:SetNoDraw( true )
		MODEL:SetPos( Vector( 0, 0, 0 ) )
	end,
} )
