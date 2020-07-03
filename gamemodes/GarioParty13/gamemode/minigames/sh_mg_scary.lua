--
-- Gario Party 13
-- 30/06/20
--
-- Game: Scary Game
--

local NAME = "Scary Game"

local PILLARS = {
	{ Vector( -4180, 4870, 2320 ), Angle( 90, 0, 0 ), 5 },
	{ Vector( -4750, 4870, 2300 ), Angle( 90, 0, 0 ), 4 },
	{ Vector( -4750, 5770, 2270 ), Angle( 90, 0, 0 ), 4 },
	{ Vector( -4175, 5772, 2370 ), Angle( 90, 0, 0 ), 3.1 },
	{ Vector( -4480, 5570, 2300 ), Angle( 90, 0, 0 ), 4 },
	{ Vector( -4280, 5270, 2260 ), Angle( 90, 0, 0 ), 5 },
	{ Vector( -4680, 5170, 2350 ), Angle( 90, 0, 0 ), 3 },
	{ Vector( -4480, 5070, 2400 ), Angle( 90, 0, 0 ), 3 },
}
local PILLAR_HEIGHT = 120
local PILLAR_RADIUS = 30

local WIN_SCORE = 5

-- Resources
if ( SERVER ) then
	resource.AddFile( "materials/eye.png" )
	resource.AddFile( "sound/boo.wav" )
	resource.AddFile( "sound/scared.wav" )
	resource.AddFile( "sound/fall.wav" )
	resource.AddFile( "sound/pop.wav" )
end
Sound_Boo = Sound( "boo.wav" )
if ( CLIENT ) then
	--Material_Mouth = Material( "mouth.png", "noclamp smooth" )
	Material_Eye = Material( "eye.png", "noclamp smooth" )
end

GM.AddGame( NAME, "Default", {
	Author = "johnjoemcbob",
	Colour = Color( 255, 255, 0, 255 ),
	TagLine = "Boo! Ah!",
	Instructions = "Knock other players off the platforms to win!",
	Controls = "Left click to BOO!",
	GIF = "http://johnjoemcbob.com/wp-content/uploads/2020/06/garioparty_thumb.gif",
	HideDefaultHUD = true,
	HideLabels = true,
	HideDefaultExtras = {
		["CHudCrosshair"] = true,
	},
	World = {},

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!

		self:StartConstants()
		self:AddTitle( "Models" )
			self:AddConstant( "MODEL_PILLAR", "MODEL"	, "models/XQM/cylinderx2large.mdl", {}, function( self, val )
				if ( SERVER ) then
					self:RemoveWorld()
					self:AddWorld()
				end
			end )
			self:AddConstant( "MODEL_SHEET"	, "MODEL"	, "models/props_phx/construct/metal_dome360.mdl" )
		self:AddTitle( "Player" )
			self:AddConstant( "PLAYER_SIZE"	, "NUMBER"	, 0.5, { Range = { 0.001, 100 } }, function( self, val )
				for ply, v in pairs( self.Players ) do
					ply:SetModelScale( val )
				end
			end )
		self:AddTitle( "Visuals" )
			self:AddConstant( "HIDEWORLD"	, "BOOL"	, true )
			self:AddConstant( "3D_CAPTIONS"	, "BOOL"	, true )
			self:AddConstant( "DRAWDISTANCE", "NUMBER"	, 3000 )
			self:AddConstant( "CAM_DISTANCE", "NUMBER"	, 150 )
			self:AddConstant( "ANGLE_CLAMP"	, "NUMBER"	, 0 )
		self:AddTitle( "Visuals - Face" )
			self:AddConstant( "MOUTH_SPEED"	, "NUMBER"	, 5 )
			self:AddConstant( "MOUTH_SIZE"	, "NUMBER"	, 32 )
			self:AddConstant( "MOUTH_OPEN"	, "NUMBER"	, 2 )
			self:AddConstant( "EYE_SIZE"	, "NUMBER"	, 128 )
		self:AddTitle( "Controls" )
			self:AddConstant( "PUSHRANGE"	, "NUMBER"	, 150 )
			self:AddConstant( "PUSHFORCE"	, "NUMBER"	, 100 )
			self:AddConstant( "PUSHUPFORCE"	, "NUMBER"	, 300 )
			self:AddConstant( "JUMP_POWER"	, "NUMBER"	, 300, {}, function( self, val )
				if ( SERVER ) then
					for ply, _ in pairs( self.Players ) do
						ply:SetJumpPower( val )
					end
				end
			end )
		self:AddTitle( "Gameplay" )
			self:AddConstant( "KILL_Z"		, "NUMBER"	, 2500 )
			self:AddConstant( "FALL_Z"		, "NUMBER"	, 2600 )
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded

		if ( SERVER ) then
			self:RemoveWorld()
			self:AddWorld()
		end
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			ply.ClientAngle = Angle( 0, 0, 0 )
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			ply:SetModel( "models/player/charple.mdl" )
			ply:SetModelScale( 0.01 )
			ply:SetModelScale( self["PLAYER_SIZE"], 0.5 )
			ply:SetMaterial( "models/debug/debugwhite" )
			ply:SetColor( GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )] )

			ply:SetJumpPower( self["JUMP_POWER"] )
			ply:SetHealth( 10000 )

			-- Spawn point
			local possible = table.shallowcopy( PILLARS )
			while ( #possible > 0 ) do
				local index = math.random( 1, #possible )
				local pillar = possible[index]
				local success = ply:TrySpawn( pillar[1] + Vector( 0, 0, PILLAR_HEIGHT * pillar[3] ) )
				if ( success ) then
					break
				else
					table.RemoveByValue( possible, pillar )
				end
			end
			ply:EmitSound( "pop.wav", 75, math.random( 80, 150 ) )

			ply.Fallen = false
			ply:SetNWEntity( "ScaredBy", ply )
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
			-- If below a certain y, play fall sound and kill
			if ( ply:GetPos().z <= self["KILL_Z"] ) then
				-- Update scores!
				local scare = ply:GetNWEntity( "ScaredBy", ply )
				if ( scare and scare:IsValid() and scare != ply ) then
					local new = scare:GetNWInt( "Score", 0 ) + 1
					scare:SetNWInt( "Score", new )
					if ( new >= WIN_SCORE ) then
						self:Win( ply )
					end
				else
					ply:SetNWInt( "Score", ply:GetNWInt( "Score", 0 ) - 1 )
				end
				ply.ScareBy = nil

				local texts = { "bye", "see ya", "later", "ciao", }
				if ( self["3D_CAPTIONS"] ) then
					GAMEMODE.AddWorldText( ply:GetPos(), Vector( 0, 0, 1 ) * 10, Angle( 0, 0, 0 ), 0.3, texts[math.random( 1, #texts )], COLOUR_WHITE, 0.5 )
				end

				ply:Spawn()
			elseif ( ply:GetPos().z <= self["FALL_Z"] and !ply.Fallen ) then
				ply:EmitSound( "fall.wav", 75, math.random( 100, 170 ) )
				if ( self["3D_CAPTIONS"] ) then
					GAMEMODE.AddWorldText( ply:EyePos() - Vector( 0, 0, 150 ), Vector( 0, 0, 1 ) * -250, Angle( 0, 0, 80 ), 1.5, "Aaaaaaaaaaa", COLOUR_WHITE, 1, true )
				end
				ply:SetModelScale( 0.01, 0.5 )
				ply.Fallen = true
			end
		end
	end,
	KeyPress = function( self, ply, key )
		if ( key == IN_ATTACK ) then
			ply:EmitSound( "boo.wav", 75, math.random( 100, 120 ) )

			ply:SetNWFloat( "LastBoo", CurTime() )

			-- Find other players in front of self to push
			local dir = ply:EyeAngles():Forward()
				dir.z = 0
				dir = dir:GetNormalized()
			local pos = ply:EyePos() --+ dir * self["PUSHRANGE"]
				-- debugoverlay.Sphere( pos, self["PUSHRANGE"], 2, Color( 255, 0, 255, 1 ), true )
			for k, ent in pairs( ents.FindInSphere( pos, self["PUSHRANGE"] ) ) do
				if ( ent:IsValid() and ent:IsPlayer() and ent != ply ) then
					local vel = dir * self["PUSHFORCE"]
						if ( ent:IsOnGround() ) then
							vel = vel + Vector( 0, 0, 1 ) * self["PUSHUPFORCE"]
						end
					ent:SetVelocity( vel )
					ent:SetNWEntity( "ScaredBy", ply )
					timer.Simple( 0.1, function()
						ent:EmitSound( "scared.wav", 75, math.random( 80, 150 ) )

						if ( self["3D_CAPTIONS"] ) then
							GAMEMODE.AddWorldText( ent:EyePos(), -dir * 15, Angle( 0, 0, 0 ), 1, "Ah!", COLOUR_WHITE, 0.2 )
						end
					end )
				end
			end

			if ( self["3D_CAPTIONS"] ) then
				GAMEMODE.AddWorldText( ply:EyePos() + ply:EyeAngles():Right() * 40, dir * 150, Angle( 0, 0, 0 ), 1, "Boo!", COLOUR_WHITE, 0.2 )
			end
		end
	end,
	OnPlayerHitGround = function( self, ply, inWater, onFloater, speed )
		-- Delay a little so when they land they still stare at the player if not moving
		timer.Simple( 0.5, function()
			ply:SetNWEntity( "ScaredBy", ply )
		end )
	end,
	GetFallDamage = function( self, ply, speed )
		return 0
	end,
	PlayerFootstep = function( self, ply, pos, foot, sound, volume, rf )
		if ( SERVER ) then
			if ( ply:GetPos().z > self["FALL_Z"] ) then
				local dir = -ply:GetVelocity():GetNormalized() + Vector( 0, 0, 1 )
				if ( self["3D_CAPTIONS"] ) then
					GAMEMODE.AddWorldText( ply:GetPos() + Vector( 0, 0, 3 ), dir * 10, Angle( 0, 0, 0 ), 0.2, math.random( 1, 2 ) == 1 and "tip" or "tap", COLOUR_WHITE, 0.5 )
				end
			end
		end
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()

		local x = 64
		local y = ScrH() - 64
		local size = 32
		for ply, k in pairs( self.Players ) do
			local txt = "" .. ply:GetNWInt( "Score", 0 )
			local font = "DermaLarge"
			local border = 16
			local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
			self:DrawGhost( x, y - height / 2, size, colour )
			draw.SimpleText( txt, font, x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			y = y - size * 4
		end
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PreDrawOpaqueRenderables = function( self )
		-- Don't draw the world?
		if ( self["HIDEWORLD"] ) then
			render.Clear( 0, 0, 0, 255 )
			render.ClearDepth()
		end
		-- Turn back on in PostPlayerDraw!
		--render.SuppressEngineLighting( true )

		-- Now draw the pillars again after the world blank to stretch them downwards
		--cam.IgnoreZ( true )
		for k, pillar in pairs( PILLARS ) do
			local colour = Color( 255, 255, 255, 255 )
			GAMEMODE.RenderCachedModel( self["MODEL_PILLAR"], pillar[1] - Vector( 0, 0, PILLAR_HEIGHT ) * pillar[3], pillar[2], Vector( 1, 1, 1 ) * pillar[3], nil, colour, RENDERGROUP_OPAQUE, function( ent )
				ent:SetMaterial( "models/debug/debugwhite" )
			end )
		end
		--cam.IgnoreZ( false )
	end,
	PostDrawOpaqueRenderables = function( self )
		-- Now draw the pillar top surfaces
		for k, pillar in pairs( PILLARS ) do
			local pos = pillar[1] + Vector( 0, 0, PILLAR_HEIGHT ) / 1.3329 * pillar[3]
			cam.Start3D2D( pos, Angle( 0, -90, 0 ), 1 )
				surface.SetDrawColor( Color( 255, 255, 255, 1 ) )
				draw.NoTexture()
				draw.Circle( 0, 0, 1 * pillar[3] * PILLAR_RADIUS, 64, 0 )
			cam.End3D2D()
		end
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply

		local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
		surface.SetDrawColor( colour )
		draw.NoTexture()

		--render.SuppressEngineLighting( false )

		-- Draw drop shadow
		local tr = util.TraceLine( {
			start = ply:GetPos(),
			endpos = ply:GetPos() + Vector( 0, 0, 1 ) * -10000,
			filter = ply
		} )
		local pos = tr.HitPos + Vector( 0, 0, 0.1 )
		if ( pos.z > self["KILL_Z"] ) then
			local dist = 1 - ( ply:GetPos().z - pos.z ) / 300
			cam.Start3D2D( pos, Angle( 0, -90, 0 ), 1 )
				draw.Circle( 0, 0, 4 * ply:GetModelScale() * dist, 64, 0 )
			cam.End3D2D()
		end

		-- Draw sheet
		local attach_id = ply:LookupAttachment('eyes')
		if not attach_id then return end

		local attach = ply:GetAttachment(attach_id)

		if not attach then return end

		local pos = attach.Pos + Vector( 0, 0, -40 ) * ply:GetModelScale()
			if ( !ply.ClientAngle ) then
				ply.ClientAngle = Angle( 0, 0, 0 )
			end
		local scaredby = ply:GetNWEntity( "ScaredBy", ply )
		if ( scaredby != ply ) then
			local target = ( scaredby:GetPos() - pos ):GetNormalized():Angle()
				target.p = math.Clamp( target.p, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
				target.r = math.Clamp( target.r, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
			ply.ClientAngle = LerpAngle( FrameTime() * 5, ply.ClientAngle, target )
		elseif ( ply == LocalPlayer() and ply:GetPos().z <= self["FALL_Z"] ) then
			local target = LocalPlayer():EyeAngles()
				target:RotateAroundAxis( target:Up(), 180 )
				target.p = math.Clamp( target.p, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
				target.r = math.Clamp( target.r, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
			ply.ClientAngle = LerpAngle( FrameTime() * 15, ply.ClientAngle, target )
		else
			local vel = ply:GetVelocity()
			vel.z = 0
			vel = vel:GetNormalized()
			if ( vel:LengthSqr() > 0.5 ) then
				local target = vel:Angle()
					target.p = math.Clamp( target.p, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
					target.r = math.Clamp( target.r, -self["ANGLE_CLAMP"], self["ANGLE_CLAMP"] )
				ply.ClientAngle = LerpAngle( FrameTime() * 5, ply.ClientAngle, target )
			end
		end
		local ang = Angle( ply.ClientAngle.p, ply.ClientAngle.y, ply.ClientAngle.r )
		
		GAMEMODE.RenderCachedModel( self["MODEL_SHEET"], pos, ang, Vector( 0.7, 0.7, 1.2 ) * ply:GetModelScale(), nil, colour, RENDERGROUP_OPAQUE, function( ent )
			ent:SetMaterial( "models/debug/debugwhite" )
		end )

		-- Draw face
		--if ( ply != LocalPlayer() ) then
			local scale = 0.2 * ply:GetModelScale()
			local dir = -ang:Forward()
				--if ( !ply:IsOnGround() ) then
				--	dir = -dir
				--end
			local pos = pos + Vector( 0, 0, 1 ) * 20 * ply:GetModelScale()
				pos = pos - dir * 33 * ply:GetModelScale()
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
			local eyesize = 1

			ang:RotateAroundAxis( ang:Up(), 180 - 20 )
			ang:RotateAroundAxis( ang:Right(), 90 )
			ang:RotateAroundAxis( dir, 90 )
			cam.Start3D2D( pos, ang, scale )
				-- Mouth
				local progress = 1 - ( CurTime() - ply:GetNWFloat( "LastBoo", 0 ) ) * self["MOUTH_SPEED"]
				local size = 0.2 + math.Clamp( progress, 0, 1 ) * self["MOUTH_OPEN"]
					if ( ply:GetPos().z <= self["FALL_Z"] or scaredby != ply ) then
						size = 1.5 + math.sin( CurTime() * 10 ) * 0.3
						eyesize = 1.2 --+ math.sin( CurTime() * 10 ) * 0.3
						if ( ply:GetPos().z <= self["FALL_Z"] ) then
							eyesize = 1.4
						end
					end
				--local texture = surface.GetTextureID( "decals/smile" )
				--surface.SetMaterial( Material_Mouth )
				--surface.DrawTexturedRectRotated( math.cos( CurTime() ) * 16, math.sin( CurTime() ) * 16, size * self["MOUTH_SIZE"], size * self["MOUTH_SIZE"], 0 )
				local segs = 32
				local x, y = math.cos( CurTime() ) * 16, math.sin( CurTime() ) * 16
				local rad = size * self["MOUTH_SIZE"]
				draw.Circle( x, y, rad, segs, 0 )
				surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
				draw.CircleSegment( x, y, rad, segs, 8, 0, 100, false )

				-- Two eyes
				if ( !ply.EyeLerp ) then
					ply.EyeLerp = {}
					ply.EyeLerp[-1] = 0
					ply.EyeLerp[ 1] = 0
				end
				local x = 0
				local y = ply:GetVelocity().z / 4
				for i = -1, 1, 2 do
					local speed
						if ( ( i < 0 and y < 0 ) or ( i > 0 and y > 0 ) ) then
							speed = 1
						else
							speed = -1
						end
					ply.EyeLerp[i] = Lerp( FrameTime() * ( 5 + speed ), ply.EyeLerp[i], y )

					local texture = surface.GetTextureID( "decals/eye" )
					surface.SetMaterial( Material_Eye )
					surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
					surface.DrawTexturedRectRotated( i * 64 + math.cos( CurTime() + i ) * i * 4, ply.EyeLerp[i] + -64 + math.sin( CurTime() + i ) * i * 16, self["EYE_SIZE"] *eyesize , self["EYE_SIZE"] * eyesize, 0 )
				end
			cam.End3D2D()
		--end
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Third person view!
		local view = {}
		local fallextra = 4
		view.origin = pos-(angles:Forward()*self["CAM_DISTANCE"]) + angles:Up()*-20
		view.angles = angles
		view.fov = fov
		view.drawviewer = true
		view.zfar = self["DRAWDISTANCE"]

		return view
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	
	-- Custom functions
	AddWorld = function( self )
		-- Pillars
		for k, pillar in pairs( PILLARS ) do
			local ent = GAMEMODE.CreateProp( self["MODEL_PILLAR"], pillar[1], pillar[2], false )
				ent:SetMaterial( "models/debug/debugwhite" )
				GAMEMODE.ScaleEnt( ent, pillar[3], false )
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
	DrawGhost = function( self, x, y, size, colour )
		surface.SetDrawColor( colour )
		draw.NoTexture()
		draw.EllipsesSegment( x, y + size * 1.6, size * 2, size, 128, size, 25, 50, false )
	end,
} )

-- Hot reload helper
if ( GAMEMODE and GAMEMODE.Games[NAME] ) then
	GAMEMODE.Games[NAME]:RemoveWorld()
end
