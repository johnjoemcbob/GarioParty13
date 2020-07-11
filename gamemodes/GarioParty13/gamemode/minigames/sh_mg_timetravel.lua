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
local SKYBOX = {
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
}
local PROPS = {
	{
		Model = {
			"models/maxofs2d/logo_gmod_b.mdl",
			"",
		},
		Pos = {
			Vector( -2319, -3208, 981 ),
			Vector( 0, 0, 0 ), -- Offset
		},
		Angle = {
			Angle( 0, 0, 0 ),
			Angle( 0, 0, 0 ), -- Offset
		},
		Scale = 2,
	},
}

local SOUNDS = {
	"ambient/machines/teleport1.wav",
	"ambient/machines/teleport3.wav",
	"ambient/machines/teleport4.wav",
}
local SOUND_WALLRUN = "physics/body/body_medium_scrape_smooth_loop1.wav"

local FOGS = {
	0,
	0.7,
}

local TIME_PRESENT	= 0
local TIME_FUTURE	= 1

GM.AddGame( NAME, "Default", {
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "",
	Instructions = "",
	Controls = "Right click to time travel!",
	GIF = "https://i.imgur.com/6oIr4ew.gif",
	World = {},

	SetupDataTables = function( self )
		-- Runs on CLIENT and SERVER realms!
	end,
	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			self:RemoveWorld()
			self:AddWorld()

			self:TimeTravel( ply )
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			-- TODO Better spawn points
			ply:SetPos( POS )

			timer.Simple( 0, function()
				ply:SetWalkSpeed( 400 )
				ply:SetRunSpeed( 800 )
				ply:SetJumpPower( 400 )
			end )
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
		if ( ( tr_ground.HitWorld or tr_ground.Entity != ply.WallRunFloor ) and hor >= 7000 ) then
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
								ply.WallRunFloor:SetColor( Color( 0, 0, 0, 0 ) )
							end
							ply.WallRunFloor.z = pos.z

							ply.WallLoopSound = ply:StartLoopingSound( SOUND_WALLRUN, 75, math.random( 80, 120 ), 0.3 )
						end
						ply.OnWall = true
					end

					-- Update wall running floor pos
					if ( SERVER ) then
						--pos.z = ply.WallRunFloor.z
						ply.WallRunFloor:SetPos( pos )
					end
					ply.WallRunDirection = sign

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
				if ( ply.WallLoopSound ) then
					ply:StopLoopingSound( ply.WallLoopSound )
					ply.WallLoopSound = nil
				end
			end
			ply.OnWall = false
		end
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
	GetFallDamage = function( ply, speed )
		return 0
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
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
	CalcView = function( self, ply, pos, angles, fov )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
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

		local col = COLOUR_WHITE
		render.FogColor( col.r, col.g, col.b )

		return true
	end,
	PreDrawOpaqueRenderables = function( self )
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
				GAMEMODE.RenderCachedModel(
					mdl,
					pos + Vector( 0, 0, HEIGHT ) * time,
					obj.Angle,
					Vector( 1, 1, 1 ) * obj.Scale
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
		view.zfar = 2000

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
			end
		end )

		self:OnTimeTravel( ply )
		self:SendStartTimeTravel( ply )

		ply.LastTimeTravel = CurTime()
	end,
	OnTimeTravel = function( self, ply )
		if ( SERVER ) then
			ply:ViewPunch( Angle( -5, 0, 0 ) )
			ply:SetFOV( ply.OldFOV + FOV_PULL, TIME_BEFORE )
			ply:EmitSound( SOUNDS[math.random( 1, #SOUNDS )], 75, math.random( 80, 120 ), 1 )
		end
		if ( CLIENT ) then
			ply.DoFTarget = 9
			DOF_Start()
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
			end
		end )
	end,
	GetTimeZone = function( self, ply )
		--return ply:GetNWInt( "TimeTravel", TIME_PRESENT )
		return ( ply:GetPos().z >= POS.z + HEIGHT ) and TIME_FUTURE or TIME_PRESENT
	end,
} )

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	GM.Games[NAME].SendStartTimeTravel = function( self, ply )
		-- Communicate to client
		net.Start( NETSTRING )
		net.Send( ply )
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		GAMEMODE.Games[NAME]:OnTimeTravel( LocalPlayer() )
	end )
end

-- Hotreload helper
if ( SERVER ) then
	local self = GAMEMODE.Games[NAME]
	self:RemoveWorld()
	self:AddWorld()
end
