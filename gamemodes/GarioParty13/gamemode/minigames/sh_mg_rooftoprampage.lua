--
-- Tutorial Gamemode
-- 10/07/20
--
-- Game: Rooftop Rampage
--

local NAME = "Rooftop Rampage"

GM.AddGame( NAME, "Goose", {
	Author = "jctwizard",
	Colour = Color( 255, 0, 0, 255 ),
	TagLine = "Bombs Away!",
	Instructions = "Lay explosive eggs when you jump,\nblow up other players to win\nBy @jctwizard!",
	Controls = "Jump to bomb!",
	GIF = "https://i.imgur.com/uSNJNXN.gif",
	HideDefaultHUD = false,
	HideDefaultExtras = {
		["CHudHealth"] = true,
		["CHudCrosshair"] = true,
	},
	Walls = {},

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!
		self.base.SetupDataTables( self ) -- Note the weird use of . instead of : here!

		self:AddConstant( "MODEL_WALL"	, "MODEL"	, "models/props_wasteland/interior_fence002d.mdl" )
		self:AddConstant( "MODEL_ROOF"	, "MODEL"	, "models/hunter/plates/plate5x5.mdl" )
		self:AddConstant( "MODEL_GOOSE"	, "MODEL"	, "models/tsbb/animals/canada_goose.mdl" )
		self:AddConstant( "MODEL_EGG"	, "MODEL"	, "models/props_phx/misc/egg.mdl" )
		self:AddConstant( "MODEL_MELON"	, "MODEL"	, "models/props_junk/watermelon01.mdl" )
		self:AddConstant( "MELON_SIZE"	, "NUMBER"	, 2 )
		self:AddConstant( "HIDEWORLD"	, "BOOL"	, true )
		self:AddConstant( "HIDEWALLS"	, "BOOL"	, true, {}, function( self, varval )
			for k, wall in pairs( self.Walls ) do
				if ( wall and wall:IsValid() and wall:GetModel() == self["MODEL_WALL"] ) then
					wall:SetNoDraw( varval )
				end
			end
		end )
		self:AddConstant( "WALLCOUNT"	, "NUMBER"	, 2 )
		self:AddConstant( "WALL_WIDTH"	, "NUMBER"	, 250 )
		self:AddConstant( "ROOF_WIDTH"	, "NUMBER"	, 380 / 8 * 5 )
		self:AddConstant( "ROOF_ORIGIN"	, "VECTOR"	, Vector(-2220, -2780, 2910) )
		self:AddConstant( "FLOOR_COLOUR", "COLOUR"	, Color( 255, 100, 0, 10 ) )
		self:AddConstant( "ANGLE_CLAMP"	, "NUMBER"	, 20 )
		self:AddConstant( "EGG_FUSE"	, "NUMBER"	, 1 )
		self:AddConstant( "EGG_RANGE"	, "NUMBER"	, 100 )
		self:AddConstant( "SCORE_MAX"	, "NUMBER"	, 5 )
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded

		if ( SERVER ) then
			self:RemoveWalls()
			self:AddWalls()
		end
	end,
	Destroy = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is stopped

		if ( SERVER ) then
			self:RemoveWalls()
		end
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		self.base:PlayerJoin( ply )

		if ( SERVER ) then
			ply.EggTimer = 0

			ply.CurrentModel = self["MODEL_GOOSE"]
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			ply:SetModel( ply.CurrentModel )
			ply:SetSkin( 1 )
			ply:SetColor( GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )] )

			ply:SetHealth( 1 )

			-- Spawn point
			local size = self:GetPlaySpace() / 3
			local attempts = 0
			while ( attempts < 100 ) do
				local success = ply:TrySpawn( self["ROOF_ORIGIN"] + Vector( math.random( -size, size ), math.random( -size , size ), -50 ) )
				if ( success ) then break end
				attempts = attempts + 1
			end
		end 
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		ply:SetEyeAngles( Angle( 0, 0, 0 ) )

		if ( ply.EggTimer == nil ) then
			ply.EggTimer = 0
		end

		if ( ply.EggTimer > 0 ) then
			ply.EggTimer = ply.EggTimer - FrameTime()
		end

		if ( SERVER ) then
			ply:SetNWFloat( "EggTimer", ply.EggTimer )

			ply:SetMoveType( MOVETYPE_WALK )

			-- I added a physical roof!
			--if ( ply:GetPos().z > self["ROOF_ORIGIN"].z + 200 ) then
			--	local clampedPos = ply:GetPos();
			--	clampedPos.z = self["ROOF_ORIGIN"].z + 100
			--	ply:SetPos(clampedPos)
			--end

			if ( ply:Alive() and ply:KeyDown( IN_JUMP ) and ply.EggTimer <= 0 ) then
				ply:EmitSound( "quack.wav", 75, math.random( 50, 150 ) )

				local eggPos = ply:GetPos()
				eggPos.z = self["ROOF_ORIGIN"].z - 60
				local ent = GAMEMODE.CreateProp( self["MODEL_EGG"], eggPos, Angle( 0, 0, 0 ), false )
				ent:SetSolid( SOLID_NONE )
				ent:SetModelScale( 5 )
				ent:SetHealth( 100000 )
				ent:SetColor( GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )] )

				ply:SetNWVector( "EggPos", eggPos )

				ply.EggTimer = self["EGG_FUSE"]

				timer.Simple( self["EGG_FUSE"], function()
					local explosion = ents.Create("env_explosion")
					explosion:SetKeyValue("spawnflags",128)
					explosion:SetPos(ent:GetPos())
					explosion:SetOwner(ply)
					explosion:Spawn()
					explosion:Fire("explode","",0)

					local explosion = ents.Create("env_physexplosion")
					explosion:SetKeyValue("magnitude",self:GetRange())
					explosion:SetPos(ent:GetPos())
					explosion:SetOwner(ply)
					explosion:Spawn()
					explosion:Fire("explode","",0)

					ent:SetHealth( 1 )
					--ent:Remove()
				end )
			end
		end
	end,
	KeyPress = function( self, ply, key )
		-- Overwrite from base
	end,
	KeyRelease = function( self, ply, key )
		-- Overwrite from base
	end,
	PlayerDeath = function( self, victim, inflictor, attacker )
		-- Runs on SERVER realm!
		-- victim/attacker

		local attacker = attacker:GetOwner()

		if ( attacker:IsValid() and attacker != victim and attacker:IsPlayer() ) then
			attacker:SetNWInt( "Score", attacker:GetNWInt( "Score", 0 ) + 1 )

			if ( attacker:GetNWInt( "Score" ) >= self["SCORE_MAX"] ) then
				self:Win( attacker )
				--attacker.CurrentModel = self["MODEL_MELON"]
				--attacker:SetModelScale( 2 ) -- Pssst, commented this out because it makes bad collision between players!

				-- Reset the scores and respawn all the players
				-- for ply, k in pairs( self.Players ) do
				-- 	if ( ply != attacker ) then
				-- 		ply.CurrentModel = self["MODEL_GOOSE"]
				-- 		ply:SetModelScale( 1 )
				-- 	end
				-- 	ply:SetNWInt( "Score", 0 )
				-- 	self:PlayerSpawn( ply )
				-- end
			end
		end
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()

		local size = ScrH() / ( #player.GetAll() * 4 )
		local x = size * 2
		local y = ScrH() - size * 2
		for ply, k in pairs( self.Players ) do
			local txt = "" .. ply:GetNWInt( "Score" )
			local font = "DermaLarge"
			local border = 16
			local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
			--draw.RoundedBox( 8, x - width / 2, y - height / 2, width, height, colour ) -- 0, 0 is Screen top left
			self:DrawEgg( x, y - height / 2, size, 8, colour )
			draw.SimpleText( txt, font, x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			--self:DrawEgg( ScrW() / 2, ScrH() / 2, 64, 8 )
			y = y - size * 4
		end
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PreDrawOpaqueRenderables = function( self )
		-- Don't draw the world? comment out if you don't like it
		if ( self["HIDEWORLD"] ) then
			render.Clear( 0, 0, 0, 255 )
		end

		local size = self:GetPlaySpace() * 1
		cam.Start3D2D( self["ROOF_ORIGIN"] - Vector(0, 0, 50), Angle( 0, 0, 0 ), 1 )
			surface.SetDrawColor( self["FLOOR_COLOUR"] )
			surface.DrawRect( -size / 2, -size / 2, size, size )
		cam.End3D2D()
	end,
	PrePlayerDraw = function( self, ply )
		self:PostPlayerDraw( ply )
		return true
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply

		local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
		surface.SetDrawColor( colour )
		draw.NoTexture()

		-- Draw range around egg bomb
		local eggPos = self["ROOF_ORIGIN"] - ply:GetNWVector( "EggPos", self["ROOF_ORIGIN"] )
		if ( ply:GetNWFloat( "EggTimer", 0) > 0 ) then
			cam.Start3D2D( self["ROOF_ORIGIN"] - Vector(0, 0, 50), Angle( 0, 0, 0 ), 1 )
				draw.CircleSegment( -eggPos.x, eggPos.y, self["EGG_RANGE"], 64, 4, 0, 100, false )
				draw.CircleSegment( -eggPos.x, eggPos.y, self["EGG_RANGE"] * ( 1 - ( ply:GetNWFloat( "EggTimer", 0) / self["EGG_FUSE"] ) ), 64, 1, 0, 100, false )
			cam.End3D2D()
		end

		-- Draw player
		if ( ply:GetModel() == self["MODEL_GOOSE"] ) then
			self:DrawGoose( ply )
		else
			GAMEMODE.RenderCachedModel( ply:GetModel(), ply:GetPos(), ply:GetAngles(), Vector( 1, 1, 1 ) * self["MELON_SIZE"], nil, colour, RENDERGROUP_OPAQUE, function( ent ) ent:SetSkin( 1 ) end )
		end

		-- Draw player circle
		local off = Vector( -20, 0, 0 )
		local pos = ply:GetPos()
			pos.z = self["ROOF_ORIGIN"].z - 62
		cam.Start3D2D( pos, Angle( 0, -90, 0 ), 1 )
			surface.SetDrawColor( colour )
			draw.CircleSegment( 0, 0, 16, 64, 4, 0, 100, false )
		cam.End3D2D()
		-- Draw player name
		pos = pos + off
		cam.IgnoreZ( true )
			cam.Start3D2D( pos, Angle( 0, -90, 0 ), 0.5 )
				draw.DrawText( ply:GetName(), "DermaLarge", 2, 2, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
			cam.End3D2D()
		cam.IgnoreZ( false )
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			self:RemoveRagdoll( ply )
		end
		if ( SERVER ) then
			ply:SetColor( Color( 255, 255, 255, 255 ) )
			
			ply:SetHealth( ply:GetMaxHealth() )
		end
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Top down view!
		local angles = Angle( 90, 0, 0 )
		local view = {}
		view.origin = Vector( -2220, -2780, 3200 )
		view.angles = angles
		view.fov = 90
		view.drawviewer = true

		return view
	end,

	-- Custom functions
	AddWalls = function( self )
		-- Horizontal
		for x = 1, self["WALLCOUNT"] do
			local ent = GAMEMODE.CreateProp( self["MODEL_WALL"], self["ROOF_ORIGIN"] + Vector( x * self["WALL_WIDTH"] - ( ( ( self["WALLCOUNT"] / 2.0 ) + 0.5 ) * self["WALL_WIDTH"] ), -( self["WALLCOUNT"] * self["WALL_WIDTH"] ) / 2.0, 0 ), Angle( 0, 90, 0 ), false )
			table.insert( self.Walls, ent )
			local ent = GAMEMODE.CreateProp( self["MODEL_WALL"], self["ROOF_ORIGIN"] + Vector( x * self["WALL_WIDTH"] - ( ( ( self["WALLCOUNT"] / 2.0 ) + 0.5 ) * self["WALL_WIDTH"] ), ( self["WALLCOUNT"] * self["WALL_WIDTH"] ) / 2.0, 0 ), Angle( 0, 90, 0 ), false )
			table.insert( self.Walls, ent )
		end

		-- Vertical
		for y = 1, self["WALLCOUNT"] do
			local ent = GAMEMODE.CreateProp( self["MODEL_WALL"], self["ROOF_ORIGIN"] + Vector( -( self["WALLCOUNT"] * self["WALL_WIDTH"] ) / 2.0, y * self["WALL_WIDTH"] - ( ( ( self["WALLCOUNT"] / 2.0 ) + 0.5 ) * self["WALL_WIDTH"] ), 0 ), Angle( 0, 0, 0 ), false )
			table.insert( self.Walls, ent )
			local ent = GAMEMODE.CreateProp( self["MODEL_WALL"], self["ROOF_ORIGIN"] + Vector( ( self["WALLCOUNT"] * self["WALL_WIDTH"] ) / 2.0, y * self["WALL_WIDTH"] - ( ( ( self["WALLCOUNT"] / 2.0 ) + 0.5 ) * self["WALL_WIDTH"] ), 0 ), Angle( 0, 0, 0 ), false )
			table.insert( self.Walls, ent )
		end

		-- Roof
		for x = -0.5, 0.5 do
			for y = -0.5, 0.5 do
				local ent = GAMEMODE.CreateProp( self["MODEL_ROOF"], self["ROOF_ORIGIN"] + Vector( x * self["ROOF_WIDTH"], y * self["ROOF_WIDTH"], 60 ), Angle( 0, 0, 0 ), false )
					ent:SetNoDraw( true )
				table.insert( self.Walls, ent )
			end
		end

		-- Hide all walls?c
	end,
	RemoveWalls = function( self )
		if ( self.Walls ) then
			for k, wall in pairs( self.Walls ) do
				if ( wall:IsValid() ) then
					wall:Remove()
				end
			end
		end
	end,
	DrawEgg = function( self, x, y, size, segs, colour )
		surface.SetDrawColor( colour )
		draw.NoTexture()
		draw.Circle( x, y + size, size * 1.4, segs, 0 )
		draw.Ellipses( x, y, size * 1.2, size, segs, 0 )
	end,
	GetPlaySpace = function( self ) return self["WALL_WIDTH"] * self["WALLCOUNT"] end,
	GetRange = function( self ) return 18 * self["EGG_RANGE"] / 50 end,
} )

-- Hot reload helper
if ( GAMEMODE and GAMEMODE.Games[NAME] ) then
	GAMEMODE.Games[NAME]:RemoveWalls()
end
