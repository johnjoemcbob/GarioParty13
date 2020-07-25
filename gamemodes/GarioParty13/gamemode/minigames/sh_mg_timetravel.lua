--
-- Gario Party 13
-- 10/07/20
--
-- Game: Time Travel
--

local NAME = "Time Travel"
local HOOK_PREFIX = HOOK_PREFIX .. NAME .."_"

local POS		= Vector( -2273, -2819, 768 )
local HEIGHT	= 1280 - 768
local OFF		= 0

local FOV_PULL	= 20
local TILT_WALL = 10
local TILT_WALK = 5
local WALLRUN_MINSPEED	= 5000
local SPEED_WALK	= 300
local SPEED_RUN		= 600
local WALLJUMP_DELAYALLOWANCE	= 0.2

local TIME_BEFORE	= 0.1
local TIME_COOLDOWN	= 0.5

local MODEL_WALLRUN = "models/hunter/plates/plate.mdl"
local MODEL_FENCE = {
	"models/props_c17/fence01a.mdl",
	"models/props_c17/fence03a.mdl"
}

local FENCE_OFF = Vector( 0, 0, 55 )
local FENCES = {
	{
		Vector( -2927, -2787, 768 ),
		Angle( 0, 0, 0 ),
		1,
	},
	{
		Vector( -1683, -2622, 768 ),
		Angle( 0, 0, 0 ),
		1,
	},
	{
		Vector( -1679, -2941, 768 ),
		Angle( 0, 0, 0 ),
		1,
	},
	{
		Vector( -2693, -2323, 768 ),
		Angle( 0, 90, 0 ),
		2,
	},
	{
		Vector( -1910, -2320, 768 ),
		Angle( 0, 90, 0 ),
		2,
	},
}
local SKYBOX = {}
local PROPS = {}
-- local FIRES = {
-- 	{
-- 		Model ="models/props_wasteland/cargo_container01.mdl",
-- 		Pos = Vector( -3500, -2000, POS.z ),
-- 		Angle = Angle( 0, 0, 0 ),
-- 	},
-- }

local SOUNDS = {
	"ambient/machines/teleport1.wav",
	"ambient/machines/teleport3.wav",
	"ambient/machines/teleport4.wav",
}
local SOUND_WALLRUN = "physics/body/body_medium_scrape_smooth_loop1.wav"
local SOUND_STUCK	= "hl1/fvox/internal_bleeding.wav"

local PARTICLE_TIMETRAVEL	= "GunshipImpact"
local PARTICLE_LIFESIGN		= "inflator_magic"

local FOGS = {
	0,
	0.7,
}

local SPAWNS = {
	Vector( -2637, -3049, 768 ),
	Vector( -2610, -2512, 768 ),
	Vector( -1938, -3068, 768 ),
	Vector( -2131, -2714, 938 ),
	Vector( -2203, -2509, 938 ),
	Vector( -2016, -2446, 938 ),
	Vector( -1832, -2599, 938 ),
	Vector( -2175, -2457, 768 ),
	Vector( -1879, -2587, 768 ),
	Vector( -1859, -2360, 768 ),
	Vector( -2319, -3026, 768 ),
	Vector( -2717, -2744, 768 ),
	Vector( -2495, -2762, 777 ),
}

local TIME_PRESENT	= 0
local TIME_FUTURE	= 1

-- From: https://github.com/willox/archive/blob/master/gmod-multi-jump-master/lua/autorun/multi_jump.lua
local function GetMoveVector(mv)
	local ang = mv:GetAngles()

	local max_speed = mv:GetMaxSpeed()

	local forward = math.Clamp(mv:GetForwardSpeed(), -max_speed, max_speed)
	local side = math.Clamp(mv:GetSideSpeed(), -max_speed, max_speed)

	local abs_xy_move = math.abs(forward) + math.abs(side)

	if abs_xy_move == 0 then
		return Vector(0, 0, 0)
	end

	local mul = max_speed / abs_xy_move

	local vec = Vector()

	vec:Add(ang:Forward() * forward)
	vec:Add(ang:Right() * side)

	vec:Mul(mul)

	return vec
end

GM.AddGame( NAME, "Default", {
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "Thanks Anderson!",
	Instructions = "Kill the other time travellers to win!",
	Controls = "Secondary fire to time travel!\nPrimary fire to shoot\nRun at walls to wall run",
	GIF = "https://i.imgur.com/f71CPHF.gif",
	World = {},

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded

		if ( SERVER ) then
			self:RemoveWorld()
			self:AddWorld()
		end

		if ( SERVER ) then
			-- Enemy spawns
			local poses = {
				Vector( -2707, -2504, 1280 ),
				Vector( -2596, -2980, 1280 ),
				Vector( -2040, -3072, 1280 ),
				Vector( -2097, -2616, 1280 ),
				Vector( -1912, -2474, 1280 ),
				Vector( -1956, -2483, 1450 ),
				Vector( -2211, -2495, 1450 ),
				Vector( -2047, -2732, 1450 ),
			}
			local chances = {
				[30] = nil,
				[98] = "npc_antlion",
				[100] = "npc_antlionguard",
			}
			for k, pos in pairs( poses ) do
				local rnd = math.random( 0, 100 )
				for val, class in SortedPairs( chances ) do
					if ( rnd <= val ) then
						if ( class ) then
							local npc = GAMEMODE.CreateEnt( class, nil, pos, Angle( 0, 0, 0 ), true )
							table.insert( self.World, npc )
						end
						break
					end
				end
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

		if ( SERVER ) then
			self:TimeTravel( ply )
		end
		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Play( MUSIC_TRACK_TIMETRAVEL )
			end
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			-- Spawn points
			local possible = table.shallowcopy( SPAWNS )
			while ( #possible > 0 ) do
				local index = math.random( 1, #possible )
				local pos = possible[index]
				local success = ply:TrySpawn( pos )
				if ( success ) then
					break
				else
					table.RemoveByValue( possible, pos )
				end
			end

			ply:SetNWBool( "Stuck", false )

			-- Late init speed to overwrite base
			timer.Simple( 0, function()
				ply:SetWalkSpeed( SPEED_WALK )
				ply:SetRunSpeed( SPEED_RUN )
				ply:SetJumpPower( 400 )
			end )
			
			-- Weapons
			ply:Give( "weapon_pistol" )
			ply:GiveAmmo( 50, "Pistol", true )
			ply:Give( "weapon_smg1" )
			ply:GiveAmmo( 400, "SMG1", true )
		end
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player

		-- if ( CLIENT ) then
		-- 	local ply = LocalPlayer()
		-- 	local current = self:GetTimeZone( ply )
		-- 	if ( current != ply.LastTimeZone ) then
		-- 		self:OnTimeTravel( ply )
		-- 		ply.LastTimeZone = current
		-- 	end
		-- end
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		self:PlayerThinkWallRun( ply )
		self:PlayerThinkStuck( ply )
	end,
	KeyPress = function( self, ply, key )
		if ( key == IN_ATTACK2 ) then
			-- TIME TRAVEL HERE
			--if ( ply:GetPos().z > POS.z + HEIGHT ) then
			if ( self:GetTimeZone( ply ) == TIME_FUTURE ) then
				-- In future, go to past
				self:TimeTravel( ply, Vector( 0, 0, -HEIGHT - OFF ), TIME_PRESENT )
			else
				-- In past, go to future
				self:TimeTravel( ply, Vector( 0, 0, HEIGHT - OFF ), TIME_FUTURE )
			end
		end
	end,
	KeyRelease = function( self, ply, key )
		if ( key == IN_ATTACK ) then
		end
	end,
	PlayerGotKill = function( self, victim, inflictor, attacker )
		-- Runs on SERVER realm!
		-- victim/attacker

		if ( attacker:IsValid() and attacker:IsPlayer() and attacker != victim ) then
			attacker:SetNWInt( "Score", attacker:GetNWInt( "Score", 0 ) + 1 )

			if ( attacker:GetNWInt( "Score", 0 ) >= 5 ) then
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
	GetFallDamage = function( ply, speed )
		return 0
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
		
		local off = ScrW() / 64

		-- Health
		local colour = GAMEMODE.ColourPalette[LocalPlayer():GetNWInt( "Colour" )]
		local percent = LocalPlayer():Health() / LocalPlayer():GetMaxHealth()
		local size = ScrH() / 16
		local width = size * 4
		local x = ScrW() / 2
		local y = ScrH()
		surface.SetDrawColor( COLOUR_BLACK )
		draw.Ellipses( x, y, size, width, 32 )
		if ( LocalPlayer():Alive() and LocalPlayer():Health() > 0 ) then
			surface.SetDrawColor( colour )
			draw.Ellipses( x, y, size * percent * 0.95, width * 0.95, 32 )
		end

		-- Ammo
		local font = "DermaLarge"
		local ammoheight = ScrH() / 16
		local ammowidth = ammoheight * 3
		local x = ScrW() - ammowidth - off
		local y = ScrH() - ammoheight - off
		surface.SetDrawColor( COLOUR_BLACK )
		draw.Ellipses( x, y, ammoheight, ammowidth, 32 )
		local wep = LocalPlayer():GetActiveWeapon()
		if ( LocalPlayer():Alive() and LocalPlayer():Health() > 0 and wep and wep:IsValid() and wep.Clip1 ) then
			local clip = wep:Clip1()
			local ammo = LocalPlayer():GetAmmoCount( wep:GetPrimaryAmmoType() )
			draw.SimpleText( clip .. "/" .. ammo, font, x, y, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		-- Time zone
		local font = "DermaDefault"
		local rad = ScrW() / 16
		local x = ScrW() - rad - off
		local y = ScrH() - rad - off - ammoheight * 2 - off
		surface.SetDrawColor( COLOUR_BLACK )
		draw.Circle( x, y, rad, 32 )
		local target = 90 / 360 * 100
			if ( self:GetTimeZone( LocalPlayer() ) == TIME_FUTURE ) then
				target = 270 / 360 * 100
			end
		target = Angle( target, 0, 0 )
		LocalPlayer().LastTimeAngle = LocalPlayer().LastTimeAngle or target
		LocalPlayer().LastTimeAngle = LerpAngle( FrameTime() * 5, LocalPlayer().LastTimeAngle, target )
		target = LocalPlayer().LastTimeAngle
		surface.SetDrawColor( COLOUR_WHITE )
		draw.CircleSegment( x, y, rad * 0.95, 32, rad, target.p, 53 )
		-- Text
		draw.SimpleText( "FUTURE", font, x, y - rad / 2, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "PRESENT", font, x, y + rad / 2, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		-- Stuck
		if ( LocalPlayer().LastStuck ) then
			local font = "MinigameTitle"
			local x = ScrW() / 2
			local y = ScrH() / 8 * 7
			draw.SimpleText( "WARNING: INTERNAL BLEEDING DETECTED", font, x, y, COLOUR_NEGATIVE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		-- Scores
		local size = ScrH() / ( #PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) * 8 )
		local x = size * 2
		local y = ScrH() - size * 2
		--for ply, k in pairs( self.Players ) do
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			local txt = "" .. ply:GetNWInt( "Score", 0 )
			local font = "DermaLarge"
			local border = 16
			local colour = GAMEMODE.ColourPalette[ply:GetNWInt( "Colour" )]
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
			--self:DrawGhost( x, y - height / 2, size, colour )
			surface.SetDrawColor( colour )
			draw.Circle( x, y, size, 32 )
			draw.SimpleText( txt, font, x, y, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			y = y - size * 4
		end
	end,
	Scoreboard = function( self, ply, row )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PostDrawOpaqueRenderables = function( self )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PrePlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
		if ( SERVER ) then
			-- if ( ply.WallLoopSound ) then
			-- 	ply:StopLoopingSound( ply.WallLoopSound )
			-- 	ply.WallLoopSound = nil
			-- end
			ply:StopSound( SOUND_WALLRUN )
		end
		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_TIMETRAVEL )
			end
		end
	end,
	SetupMove = function( self, ply, mv )
		-- Don't fake jump if already able to
		if ply:OnGround() then
			ply.HasJumped = false
			ply.LastCouldJump = CurTime()
			return
		end

		-- Pressing jump but currently not on ground
		if not mv:KeyPressed( IN_JUMP ) or ply.HasJumped then
			return
		end

		if ( ply.OnWall or ply.LastCouldJump + WALLJUMP_DELAYALLOWANCE >= CurTime() ) then
			local vel = GetMoveVector( mv ) * 2
				vel.z = ply:GetJumpPower()
			mv:SetVelocity( vel )
			ply.HasJumped = true
			--print( "fake jump" )
		end
	end,
	SetupWorldFog = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
		local time = self:GetTimeZone( LocalPlayer() ) + 1
		local fog = FOGS[time]
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( 1200 )
		render.FogEnd( 2000 )
		render.FogMaxDensity( fog )

		local col = Color( 50, 50, 100 )
		render.FogColor( col.r, col.g, col.b )

		return true
	end,
	PostDrawTranslucentRenderables = function( self, depth, sky )
		-- Don't draw the world?
		-- render.Clear( 0, 0, 0, 255 )
		-- render.ClearDepth()

		local time = self:GetTimeZone( LocalPlayer() ) + 1
		for k, obj in pairs( SKYBOX ) do
			local mdl = obj.Model[time]
			if ( mdl != "" ) then
				local pos = obj.Pos[1]
					if ( time == 2 ) then
						pos = pos + obj.Pos[2]
					end
				local ang = obj.Angle
					if ( istable( ang ) ) then
						ang = obj.Angle[1]
						if ( time == 2 ) then
							ang = ang + obj.Angle[2]
						end
					end
				local mat = obj.Material
					if ( mat and istable( mat ) ) then
						mat = obj.Material[time]
					end
				local col = obj.Colour
					if ( col and istable( col ) ) then
						col = obj.Colour[time]
					end
				GAMEMODE.RenderCachedModel(
					mdl,
					pos + Vector( 0, 0, HEIGHT ) * time,
					ang,
					Vector( 1, 1, 1 ) * obj.Scale,
					mat, col
				)
			end
		end
	end,
	CalcView = function( self, ply, pos, angles, fov )
		ply.CurrentAngles = ply.CurrentAngles or 0
			local target = 0
				if ( ply.OnWall ) then
					target = TILT_WALL * -ply.WallRunDirection
				else
					target = target + ( ply:KeyDown( IN_MOVELEFT ) and -TILT_WALK or 0 )
					target = target + ( ply:KeyDown( IN_MOVERIGHT ) and TILT_WALK or 0 )
				end
			ply.CurrentAngles = Lerp( FrameTime() * 10, ply.CurrentAngles, target )
		angles:RotateAroundAxis( angles:Forward(), ply.CurrentAngles )

		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.zfar = 4000

		return view
	end,
	PreDrawSkyBox = function( self )
		return true
	end,
	RenderScreenspaceEffects = function( self )
		if ( LocalPlayer().DoFTarget ) then
			local convar = GetConVar( "pp_dof_spacing" )
			local val = Lerp( FrameTime() * 10, convar:GetFloat(), LocalPlayer().DoFTarget )
			convar:SetFloat( val )
			--print( convar:GetFloat(), LocalPlayer().DoFTarget )

			local tab = {
				["$pp_colour_addr"] = 0,
				["$pp_colour_addg"] = 0,
				["$pp_colour_addb"] = 0,
				["$pp_colour_brightness"] = -0.04,
				["$pp_colour_contrast"] = 1.35,
				["$pp_colour_colour"] = 5,
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 20
			}
			for k, v in pairs( tab ) do
				tab[k] = v * val / 1024
			end
			DrawColorModify( tab )
		end
	end,

	-- Custom functions
	AddWorld = function( self )
		-- Fences
		for y = 0, HEIGHT, HEIGHT do
			for k, fence in pairs( FENCES ) do
				local ent = GAMEMODE.CreateProp( MODEL_FENCE[fence[3]], fence[1] + FENCE_OFF + Vector( 0, 0, y ), fence[2], false )
				table.insert( self.World, ent )
			end
		end

		-- Props
		for time = 1, 2 do
			for k, prop in pairs( PROPS ) do
				local mdl = prop.Model[1]
				if ( mdl != "" ) then
					local pos = prop.Pos[1]
						if ( time == 2 ) then
							pos = pos + prop.Pos[2]
						end
					local ang = prop.Angle[1]
						if ( time == 2 ) then
							ang = ang + prop.Angle[2]
						end
					local ent = GAMEMODE.CreateProp(
						mdl,
						pos + Vector( 0, 0, 1 ) * HEIGHT * ( time - 1 ),
						ang,
						false
					)
					GAMEMODE.ScaleEnt( ent, prop.Scale, false )
					table.insert( self.World, ent )
				end
			end
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
	TimeTravel = function( self, ply, pos, time )
		if ( !ply:Alive() ) then return end
		if ( ply.LastTimeTravel and ply.LastTimeTravel + TIME_COOLDOWN > CurTime() ) then return end

		local current = self:GetTimeZone( ply )
		timer.Simple( TIME_BEFORE, function()
			local target = time or TIME_PRESENT
				if ( time == nil and current == TIME_PRESENT ) then
					target = TIME_FUTURE
				end
			ply:SetNWInt( "TimeTravel", target )

			if ( pos ) then
				ply:SetPos( ply:GetPos() + pos )
				self:CheckStuck( ply )
			end
		end )

		self:OnTimeTravel( ply )
		self:SendStartTimeTravel( ply )

		ply.LastTimeTravel = CurTime()
	end,
	OnTimeTravel = function( self, ply )
		local lifesigns = {}
		local offset = 0

		if ( SERVER ) then
			ply:ViewPunch( Angle( -5, 0, 0 ) )
			ply:SetFOV( ply.OldFOV + FOV_PULL, TIME_BEFORE )
			ply:EmitSound( SOUNDS[math.random( 1, #SOUNDS )], 75, math.random( 80, 120 ), 1 )
		end
		if ( CLIENT ) then
			ply.DoFTarget = 9
			DOF_Start()

			-- Player leave - Particle effects
			for bone = 1, ply:GetBoneCount() do
				local pos = ply:GetBonePosition( bone )
				if ( pos != nil ) then
					--for i = 1, 4 do
						local effectdata = EffectData()
							effectdata:SetOrigin( pos )
						util.Effect( PARTICLE_TIMETRAVEL, effectdata )
					--end
				end
			end

			-- Get all lifesigns from the current timezone [before leaving]
			if ( ply == LocalPlayer() ) then
				local current = self:GetTimeZone( ply )
				offset = HEIGHT
					if ( current == TIME_FUTURE ) then
						offset = -HEIGHT
					end
					local function checkent( ent )
						if ( self:GetTimeZone( ent ) == current ) then
							table.insert( lifesigns, ent )
						end
					end
				for k, v in pairs( ents.FindByClass( "npc_*" ) ) do
					checkent( v )
				end
				for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
					if( v != ply ) then
						checkent( v )
					end
				end
			end
		end
		timer.Simple( TIME_BEFORE, function()
			if ( SERVER ) then
				ply:SetFOV( ply.OldFOV, TIME_BEFORE )
			end
			if ( CLIENT ) then
				ply.DoFTarget = 1024
				timer.Simple( TIME_BEFORE, function()
					ply.DoFTarget = nil
					DOF_Kill()
				end )

				-- Other lifesign - Particle effects
				for k, life in pairs( lifesigns ) do
					for effect = 0, 1 do
						timer.Simple( 0.2 * effect, function()
							if ( life and life:IsValid() ) then
								for bone = 1, life:GetBoneCount() do
									local pos = life:GetBonePosition( bone )
									if ( pos ) then
										pos = pos + Vector( 0, 0, offset + 0 )
										local effectdata = EffectData()
											effectdata:SetOrigin( pos )
											--effectdata:SetRadius( 100 )
										util.Effect( PARTICLE_LIFESIGN, effectdata )
									end
								end
							end
						end )
					end
				end
			end
		end )
	end,
	CheckStuck = function( self )
		for _, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			local stuck = false
				local phys = ply:GetPhysicsObject()
				if ( phys and phys:IsValid() and phys:IsPenetrating() ) then
					stuck = true
				end
			ply:SetNWBool( "Stuck", stuck )
		end
	end,
	GetTimeZone = function( self, ply )
		return ( ply:GetPos().z >= POS.z + HEIGHT - 4 ) and TIME_FUTURE or TIME_PRESENT
	end,
	PlayerThinkWallRun = function( self, ply )
		-- If not on ground
		local onwall = false
		local hor = ply:GetVelocity()
			hor.z = 0
			hor = hor:LengthSqr()
		local pos = ply:GetPos()
		local tr_ground = util.TraceLine( {
			start = pos,
			endpos = pos + Vector( 0, 0, -10 ),
			filter = ply,
		} )
		pos = pos + Vector( 0, 0, 15 ) -- Up the body a little
		if ( ( tr_ground.HitWorld or tr_ground.Entity != ply.WallRunFloor ) and hor >= WALLRUN_MINSPEED ) then
			-- If left/right side has wall
			local dir = ply:EyeAngles():Right()
			local dist = 40
			for sign = -1, 1, 2 do
				local tr = util.TraceLine( {
					start = pos,
					endpos = pos + dir * sign * dist,
					filter = ply,
				} )
				if ( tr.Hit and ( tr.HitWorld or string.find( tr.Entity:GetClass(), "prop_" ) ) ) then
					local pos = ply:GetPos() + Vector( 0, 0, -4 )
					if ( !ply.OnWall ) then
						if ( SERVER ) then
							-- Enter wall
							if ( !ply.WallRunFloor or !ply.WallRunFloor:IsValid() ) then
								ply.WallRunFloor = GAMEMODE.CreateEnt(
									"prop_physics", MODEL_WALLRUN,
									pos, Angle( 0, 0, 0 ),
									false
								)
								ply.WallRunFloor:SetMaterial( "Models/effects/vol_light001" )
								ply.WallRunFloor:SetColor( Color( 0, 0, 0, 255 ) )
							end
							ply.WallRunFloor.z = pos.z

							--ply.WallLoopSound = ply:StartLoopingSound( SOUND_WALLRUN )
							ply:EmitSound( SOUND_WALLRUN, 75, math.random( 80, 120 ), 0.2 )
						end
						ply.OnWall = true
					end

					-- Update wall running floor pos
					if ( SERVER ) then
						--pos.z = ply.WallRunFloor.z
						ply.WallRunFloor:SetPos( pos )
					end
					ply.WallRunDirection = sign
					ply.LastCouldJump = CurTime()

					onwall = true
					break
				end
			end
		end
		if ( !onwall and ply.OnWall ) then
			-- Leave wall
			if ( SERVER ) then
				if ( ply.WallRunFloor and ply.WallRunFloor:IsValid() ) then
					ply.WallRunFloor:SetPos( Vector( 0, 0, 0 ) )
				end
				-- if ( ply.WallLoopSound ) then
				-- 	ply:StopLoopingSound( ply.WallLoopSound )
				-- 	ply.WallLoopSound = nil
				-- end
				ply:StopSound( SOUND_WALLRUN )
			end
			ply.OnWall = false
		end
	end,
	PlayerThinkStuck = function( self, ply )
		if ( SERVER ) then
			if ( ply:GetNWBool( "Stuck", false ) ) then
				-- Check for unstuck first
				local phys = ply:GetPhysicsObject()
				if ( phys and phys:IsValid() and !phys:IsPenetrating() ) then
					ply:SetNWBool( "Stuck", false )
					return
				end

				-- Take damage
				ply.NextStuckDamage = ply.NextStuckDamage or 0
				if ( ply.NextStuckDamage <= CurTime() ) then
					ply:TakeDamage( 1 )
					ply.NextStuckDamage = CurTime() + 0.1
				end
			end
		end
		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				local stuck = ply:GetNWBool( "Stuck", false )
				if ( stuck != ply.LastStuck ) then
					if ( stuck ) then
						ply:EmitSound( SOUND_STUCK )
					else
						ply:StopSound( SOUND_STUCK )
					end
					ply.LastStuck = stuck
				end
			end
		end
	end,
} )

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	GM.Games[NAME].SendStartTimeTravel = function( self, ply )
		-- Communicate to client
		net.Start( NETSTRING )
			net.WriteEntity( ply )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()

		GAMEMODE.Games[NAME]:OnTimeTravel( ply )
	end )
end

SKYBOX = {
	-- Ground
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -2000, -2000, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 101, 23, 255 ),
			Color( 12, 50, 11, 255 ),
		},
	},
	-- Sky - Right
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -1000, -2000, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 90, 0, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 100, 200, 255 ),
			Color( 12, 10, 50, 255 ),
		},
	},
	-- Sky - Left
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -3900, -2000, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 90, 0, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 100, 200, 255 ),
			Color( 12, 10, 50, 255 ),
		},
	},
	-- Sky - Front
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -2000, -100, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 90, 90, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 100, 200, 255 ),
			Color( 12, 10, 50, 255 ),
		},
	},
	-- Sky - Back
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -2000, -3500, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 90, 90, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 100, 200, 255 ),
			Color( 12, 10, 50, 255 ),
		},
	},
	-- Sky - Top
	{
		Model = {
			"models/hunter/plates/plate8x8.mdl",
			"models/hunter/plates/plate8x8.mdl",
		},
		Pos = {
			Vector( -2000, -2000, 1700 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 10,
		Material = {
			"models/debug/debugwhite",
			"models/debug/debugwhite",
		},
		Colour = {
			Color( 25, 100, 200, 255 ),
			Color( 12, 10, 50, 255 ),
		},
	},
	-- Building
	{
		Model = {
			"models/props_buildings/project_building01_skybox.mdl",
			"models/props_buildings/project_destroyedbuildings01_skybox.mdl",
		},
		Pos = {
			Vector( -2824, -1273, 0 ),
			Vector( -10, 150, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 10,
	},
	{
		Model = {
			"models/props_buildings/row_upscale.mdl",
			"models/props_buildings/destroyed_cityblock01h.mdl",
		},
		Pos = {
			Vector( -2224, -1273, 0 ),
			Vector( -15, 5, 240 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 10,
	},
	{
		Model = {
			"models/props_buildings/row_res_2.mdl",
			"models/props_buildings/destroyed_cityblock01g.mdl",
		},
		Pos = {
			Vector( -1100, -2500, 0 ),
			Vector( 20, 10, 215 ), -- Offset
		},
		Angle = {
			Angle( 0, 90, 0 ),
			Angle( 0, 180, 0 ), -- Offset
		},
		Scale = 10,
	},
	{
		Model = {
			"models/props_buildings/row_res_2.mdl",
			"models/props_buildings/destroyed_cityblock01g.mdl",
		},
		Pos = {
			Vector( -3500, -2500, 0 ),
			Vector( -20, 10, 215 ), -- Offset
		},
		Angle = {
			Angle( 0, -90, 0 ),
			Angle( 0, 180, 0 ), -- Offset
		},
		Scale = 10,
	},

	-- Non-collidable props/effects (ivy etc)
	{
		Model = {
			"",
			"models/props_foliage/ivy_01.mdl",
		},
		Pos = {
			Vector( -2920, -2810, 50 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 0.5,
	},
	{
		Model = {
			"",
			"models/props_foliage/ivy_01.mdl",
		},
		Pos = {
			Vector( -1690, -2600, 50 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 180, 0 ),
		Scale = 0.5,
	},
	{
		Model = {
			"",
			"models/props_foliage/ivy_01.mdl",
		},
		Pos = {
			Vector( -1690, -2910, 50 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 180, 0 ),
		Scale = 0.5,
	},
	{
		Model = {
			"",
			"models/props_foliage/ivy_01.mdl",
		},
		Pos = {
			Vector( -1980, -2330, 0 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, -90, 0 ),
		Scale = 1,
	},
	{
		Model = {
			"",
			"models/props_foliage/ivy_01.mdl",
		},
		Pos = {
			Vector( -2750, -2330, 0 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, -90, 0 ),
		Scale = 1,
	},
	{
		Model = {
			"",
			"models/props_foliage/cattails.mdl",
		},
		Pos = {
			Vector( -2750, -2150, 0 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, -90, 0 ),
		Scale = 2,
		Colour = Color( 100, 100, 100, 255 ),
	},
	{
		Model = {
			"",
			"models/props_foliage/bramble001a.mdl",
		},
		Pos = {
			Vector( -2950, -2810, 0 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 1,
	},
	{
		Model = {
			"",
			"models/props_foliage/tree_cliff_01a.mdl",
		},
		Pos = {
			Vector( -2650, -2050, -100 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 1,
	},
	{
		Model = {
			"",
			"models/props_foliage/tree_deciduous_01a.mdl",
		},
		Pos = {
			Vector( -2050, -2050, -100 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 1,
	},
	{
		Model = {
			"models/props_foliage/oak_tree01.mdl",
			"models/props_foliage/oak_tree01.mdl",
		},
		Pos = {
			Vector( -1750, -1750, -250 + POS.z - HEIGHT ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = Angle( 0, 0, 0 ),
		Scale = 1,
	},
}
PROPS = {
	{
		Model = {
			"models/maxofs2d/logo_gmod_b.mdl",
			"",
		},
		Pos = {
			Vector( -2320, -3220, 981 ),
			Vector( 0, 0, -10 ), -- Offset
		},
		Angle = {
			Angle( 0, 90, 0 ),
			Angle( 0, 0, 10 ), -- Offset
		},
		Scale = 2,
	},
	{
		Model = {
			"models/XQM/cylinderx2large.mdl",
			"",
		},
		Pos = {
			Vector( -2321, -2774, 768 + 100 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 0, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	{
		Model = {
			"models/props_phx/construct/metal_wire1x2b.mdl",
			"",
		},
		Pos = {
			Vector( -2321, -2600, 768 + 80 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 0, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	{
		Model = {
			"models/props_phx/construct/metal_wire1x2b.mdl",
			"",
		},
		Pos = {
			Vector( -2321, -2786, 768 + 80 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 90, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	{
		Model = {
			"models/props_phx/construct/metal_wire1x2b.mdl",
			"",
		},
		Pos = {
			Vector( -2321 + 200, -2786, 768 + 80 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 90, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	{
		Model = {
			"models/props_phx/construct/metal_wire1x2b.mdl",
			"",
		},
		Pos = {
			Vector( -2321 + 555, -2786.1, 768 + 80.1 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 90, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	-- Roof big
	{
		Model = {
			"models/props_phx/construct/windows/window4x4.mdl",
			"",
		},
		Pos = {
			Vector( -2321 + 500, -2786 + 80, 768 + 160 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 0, 0, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 3,
	},
	-- Roof small
	{
		Model = {
			"models/props_phx/construct/windows/window1x2.mdl",
			"",
		},
		Pos = {
			Vector( -2321 + 500 + 128, -2786 + 80, 768 + 159.9 ),
			Vector( 0, 50, -100 ), -- Offset
		},
		Angle = {
			Angle( 0, 0, 0 ),
			Angle( 0, -10, 70 ), -- Offset
		},
		Scale = 3,
	},
	-- Left wall
	{
		Model = {
			"models/props_phx/construct/windows/window1x2.mdl",
			"",
		},
		Pos = {
			Vector( -2321, -2786 + 200, 768 + 80 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 0, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
	-- Front wall
	{
		Model = {
			"models/props_phx/construct/windows/window1x2.mdl",
			"",
		},
		Pos = {
			Vector( -2321 + 560, -2786, 768 + 80 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 90, 90, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 4,
	},
}

-- Hotreload helper
if ( SERVER ) then
	if ( GAMEMODE ) then
		local self = GAMEMODE.Games[NAME]
		self:RemoveWorld()
		self:AddWorld()
	end
end
