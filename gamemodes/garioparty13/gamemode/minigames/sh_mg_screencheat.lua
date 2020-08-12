--
-- Gario Party 13
-- 30/06/20
--
-- Game: Screencheat
--

local BOUNDS = {
	Vector( -3272, -4552, -256 ),
	Vector( -824, -2648, -256 ),
}
local MODEL_WALL = "models/hunter/plates/plate8x8.mdl"

local ang = Angle( 90, 90, 0 )
local col = GM.ColourPalette[5]
local WALLS = {
	{ Vector( -1352, -2630, -256 ), ang, col },
	{ Vector( -2804, -2630, -256 ), ang, col },
}

GM.AddGame( "Screencheat", "Default", {
	Playable = true,
	Author = "johnjoemcbob",
	Colour = Color( 150, 150, 255, 255 ),
	TagLine = "Watch each other's screens!",
	Instructions = "You can't see the other players!\nWatch their screens to figure out where they are...",
	Controls = "Left click to shoot",
	GIF = "https://i.imgur.com/Y7OIMM7.gif",
	HideLabels = true,
	HideDefaultHUD = true,
	World = {},

	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded

		-- When each player joins, but should all be aroundabout at one time so should be fine??
		if ( SERVER ) then
			self:RemoveWorld()
			self:AddWorld()

			for k, wall in pairs( ents.FindByClass( "func_brush" ) ) do
				wall:SetColor( GAMEMODE.ColourPalette[k] )
			end
		end
	end,
	Destroy = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is stopped

		if ( SERVER ) then
			self:RemoveWorld()
		end
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		self.base:PlayerJoin( ply )

		if ( CLIENT ) then
			ply.exampleRT = GetRenderTarget( "example_rt", ScrW(), ScrH() )
			ply.customMaterial = CreateMaterial( "example_rt_mat", "UnlitGeneric", {
				["$basetexture"] = ply.exampleRT:GetName(),
				["$vertexcolor"] = 1
			} )

			if ( ply == LocalPlayer() ) then
				Music:Play( MUSIC_TRACK_SCREENCHEAT )
			end
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			-- Weapons
			ply:Give( "weapon_shotgun" )
			ply:GiveAmmo( 200, "Buckshot", true )

			ply:SetHealth( 1 )

			-- Spawn point
			ply:SetPos( Vector( math.random( BOUNDS[1].x, BOUNDS[2].x ), math.random( BOUNDS[1].y, BOUNDS[2].y ), -192 ) )
		end
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			if ( !ply:Alive() ) then
				ply:Spawn()
			end
		end

		if ( ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():LastShootTime() == CurTime() ) then
			local pos = ply:EyePos() - Vector( 0, 0, 5 ) + ply:EyeAngles():Forward() * 50

			local effectdata = EffectData()
				effectdata:SetOrigin( pos )
			util.Effect( "gp13_impact", effectdata )

			local effectdata = EffectData()
				effectdata:SetStart( Vector( 0, 0, 0 ) )
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( ply:EyeAngles():Forward() )
				effectdata:SetEntity( ply )
			util.Effect( "gp13_shoot", effectdata )
		end
	end,
	PlayerGotKill = function( self, victim, inflictor, attacker )
		-- Runs on SERVER realm!
		-- victim/attacker

		if ( attacker:IsValid() and attacker:IsPlayer() and attacker != victim ) then
			attacker:SetNWInt( "Score", attacker:GetNWInt( "Score", 0 ) + 1 )

			if ( attacker:GetNWInt( "Score", 0 ) >= CONVAR_MINIGAME_TARGET:GetInt() ) then
				self:Win( attacker )
			end

			GAMEMODE.EmitChainPitchedSound(
				"FlyHigh",
				attacker,
				Sound_OrchestraHit,
				75,
				0.5,
				100,
				20,
				5,
				0,
				20
			)
		end
	end,
	OnPlayerHitGround = function( self, ply, inWater, onFloater, speed )
		--if ( CLIENT ) then
			local effectdata = EffectData()
				effectdata:SetOrigin( ply:GetPos() + Vector( 0, 0, 10 ) )
			util.Effect( "gp13_impact", effectdata )
		--end
	end,
	PreHUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()

		-- Uncomment to remove visual effects
		-- if ( true ) then return false end

		-- Blank first
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )

		local function drawothers( ply, toggle )
			for _, other in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				other:SetNoDraw( !toggle )
				if ( other:GetActiveWeapon():IsValid() ) then
					other:GetActiveWeapon():SetNoDraw( !toggle )
				end
			end
		end
		local plycount = 0
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				if ( ply:GetGameName() == LocalPlayer():GetGameName() ) then
					plycount = plycount + 1
				end
			end
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			if ( ply:GetGameName() == LocalPlayer():GetGameName() ) then
				drawothers( ply, false )
					render.PushRenderTarget( LocalPlayer().exampleRT )
						-- Draw background
						cam.Start2D()
							surface.SetDrawColor( 0, 0, 0, 255 )
							surface.DrawRect( 0, 0, ScrW(), ScrH() )
						cam.End2D()

						-- Draw this player's view
						render.RenderView( {
							origin = ply:EyePos(),
							angles = ply:EyeAngles(),
							x = 0, y = 0,
							w = ScrW(), h = ScrH(),
							fov = 90,
							drawviewmodel = false,
						} )

						-- Floor
						--cam.Start3D( ply:EyePos(), ply:EyeAngles() )
							--self:PostDrawOpaqueRenderables( true, false )
						--cam.End3D()

						-- Draw this player's viewmodel
						if ( ply:GetActiveWeapon():IsValid() ) then
							cam.IgnoreZ( true )
								cam.Start3D( ply:EyePos(), ply:EyeAngles() )
									local model = ply:GetActiveWeapon():GetWeaponViewModel()
									GAMEMODE.RenderCachedModel( model, ply:EyePos() + ply:EyeAngles():Forward() * -5, ply:EyeAngles(), Vector( 1, 1, 1 ), nil, Color( 255, 255, 255, 255 ) )
								cam.End3D()
							cam.IgnoreZ( false )
						end
					render.PopRenderTarget()
				drawothers( ply, false )

				-- Draw the rendered view from the target to the local player's screen
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( LocalPlayer().customMaterial )
				local w, h = ScrW(), ScrH()
				local QUAD = {
					{ 0, 0, w, h }
				}
					if ( plycount > 1 ) then
						QUAD = {}
						local i = math.floor( math.sqrt( plycount - 1 ) ) + 1
						local w = ScrW() / i
						local h = ScrH() / i
						for y = 1, i do
							for x = 1, i do
								table.insert( QUAD, { ( x - 1 ) * w, ( y - 1 ) * h, w, h } )
							end
						end
					end
				surface.DrawTexturedRect( QUAD[k][1], QUAD[k][2], QUAD[k][3], QUAD[k][4] )

				-- Then draw their HUD instance
				self:CheatHUDPaint( ply, QUAD[k] )
			end
		end
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply

		local game = Label( "Score: " .. math.ceil( ply:GetNWFloat( "Score" ) ), row )
		game:SetTextColor( Color( 0, 0, 255, 255 ) )
		game:SizeToContents()
		game:Dock( RIGHT )
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PostDrawOpaqueRenderables = function( self, depth, skybox )
		-- Runs on CLIENT realm!
		-- LocalPlayer()

		local border = 16
		local up = 0.1
		local start = Vector( BOUNDS[1].x - border, BOUNDS[2].y + border, BOUNDS[1].z + up )
		local size = Vector( math.abs( BOUNDS[2].x - BOUNDS[1].x ) + border * 2, math.abs( BOUNDS[2].y - BOUNDS[1].y ) + border * 2, 0 )
		local segs = {
			{ Vector( 0, 0, 0 ), col = 4 },
			{ Vector( size.x, 0, 0 ) / 2, col = 7 },
			{ Vector( 0, -size.y, 0 ) / 2, col = 8 },
			{ Vector( size.x, -size.y, 0 ) / 2, col = 9 },
		}
		for k, seg in pairs( segs ) do
			cam.Start3D2D( start + seg[1], Angle( 0, 0, 0 ), 2 )
				surface.SetDrawColor( GAMEMODE.ColourPalette[seg.col] )
				surface.DrawRect( 0, 0, size.x / 4, size.y / 4 )
			cam.End3D2D()
		end
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				ply:SetNoDraw( false )
			end

			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_SCREENCHEAT )
			end
		end
	end,

	-- Custom functions
	AddWorld = function( self )
		-- Walls
		for k, wall in pairs( WALLS ) do
			local ent = GAMEMODE.CreateProp( MODEL_WALL, wall[1], wall[2], false )
				ent:SetMaterial( "models/debug/debugwhite" )
				ent:SetColor( wall[3] )
				--GAMEMODE.ScaleEnt( ent, wall[3], false )
			table.insert( self.World, ent )
		end
	end,
	RemoveWorld = function( self )
		if ( self.World ) then
			for k, ent in pairs( self.World ) do
				if ( ent:IsValid() ) then
					ent:Remove()
				end
			end
		end
	end,
	CheatHUDPaint = function( self, ply, quad )
		-- Draw player name bottom center
		local colour = ply:GetColour()
		draw.DrawText( ply:GetName(), "DermaLarge", quad[1] + quad[3] / 2 + 2, quad[2] + quad[4] / 16 * 14 + 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		draw.DrawText( ply:GetName(), "DermaLarge", quad[1] + quad[3] / 2, quad[2] + quad[4] / 16 * 14, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )

		-- Draw ammo bottom right
		if ( ply:GetActiveWeapon():IsValid() ) then
			draw.DrawText( ply:GetActiveWeapon():Clip1(), "DermaLarge", quad[1] + quad[3] / 8 * 7 + 2, quad[2] + quad[4] / 16 * 14 + 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
			draw.DrawText( ply:GetActiveWeapon():Clip1(), "DermaLarge", quad[1] + quad[3] / 8 * 7, quad[2] + quad[4] / 16 * 14, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		end

		-- Draw score near middle
		if ( ply:GetActiveWeapon():IsValid() ) then
			surface.SetDrawColor( colour )
			local x = quad[3]
			local y = quad[4]
			local dx = 0
				if ( quad[1] == 0 ) then
					dx = -1
				end
			local dy = 0
				if ( quad[2] == 0 ) then
					dy = -1
				end
			local w, h = 42, 42
			local x, y = x + w * dx, y + h * dy
			surface.DrawRect( x, y, w, h )
			draw.DrawText( ply:GetNWInt( "Score", 0 ), "DermaLarge", x + w / 2, y + h / 2 - 14, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end,
} )
