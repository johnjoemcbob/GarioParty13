--
-- Gario Party 13
-- 05/08/20
--
-- Game: Skyview
--

SkyView = {}
SkyView.Config = {}

local NAME = "Skyview"
local HOOK_PREFIX = HOOK_PREFIX .. NAME .."_"

local POS		= Vector( -2273, -2819, 768 )

local PROP_COOLDOWN	= 0.2
local PROP_REMOVETIME = 2
local DOUBLEJUMP_TIME = 0.5

local SPAWNS = {
	Vector( -2657, -3081, 256 ),
	Vector( -2710, -2695, 256 ),
	Vector( -2312, -2613, 256 ),
	Vector( -1982, -2548, 256 ),
	Vector( -1882, -2910, 256 ),
	Vector( -1930, -3216, 256 ),
	Vector( -2196, -2996, 256 ),
	Vector( -2179, -2611, 256 ),
	Vector( -2445, -2907, 256 ),
	Vector( -2534, -2584, 256 ),
	Vector( -2800, -2352, 256 ),
	Vector( -2834, -2728, 256 ),
	Vector( -2239, -3001, 256 ),
}

GM.AddGame( NAME, "Default", {
	Playable = true,
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "Reach for the sky!",
	Instructions = "Kill the other grapplers to win",
	Controls = "Primary fire to shoot props\nSecondary fire to shield\nUse to grapple",
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
			local success = false
			while ( #possible > 0 ) do
				local index = math.random( 1, #possible )
				local pos = possible[index] + Vector( 0, 0, 5 )
				success = ply:TrySpawn( pos )
				if ( success ) then
					break
				else
					table.RemoveByValue( possible, pos )
				end
			end
			if ( !success ) then
				-- Failsafe!
				ply:SetPos( SPAWNS[1] + Vector( 0, 0, 10 ) )
			end

			-- Late init speed to overwrite base
			timer.Simple( 0, function()
				ply:SetWalkSpeed(700)
				ply:SetRunSpeed(600)
				ply:SetJumpPower(400)
				ply:SetGravity(1.1)
			end )
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
			if ( ply:Alive() ) then
				-- Run shield think logic
				self:Think_Shield( ply )

				-- If on the grapple hook & reeling in, jumping can launch you into the air
				if (
					ply:KeyDown( IN_JUMP ) and
					ply.Grapple and ply.GrappleHook and IsValid( ply.GrappleHook ) and
					( ply.GrappleHook.GrappleAttached ~= false )
				) then
					-- Jump
					ply:SetVelocity( Vector( 0, 0, 400 ) )

					-- Increase the velocity of the attached item (if it's an entity)
					if ( type( ply.GrappleHook.GrappleAttached ) == "Entity" ) then
						local phys = ply.GrappleHook.GrappleAttached:GetPhysicsObject()
						if ( phys and IsValid( phys ) ) then
							phys:SetVelocity(
								phys:GetVelocity() / ply.GrappleHook.InvertSpeedMultiplier
							)
						end
					end
					-- Remove the hook
					self:RemoveGrapple( ply )
				elseif ply:KeyDown(IN_JUMP) and !ply.Jumped then
					-- Stat track the normal jump
					if ply.JumpTime == 0 then
						ply.JumpTime = CurTime()+DOUBLEJUMP_TIME
						--ply:SetVelocity(Vector(0,0,300))
						ply.InAir = true
						ply.Jumped = false
					end

					-- Stat track and control the double jump
					if ( ply.InAir and ( CurTime() >= ply.JumpTime ) ) then
						ply.Jumped = true
						ply:SetVelocity(Vector(0,0,300))
						ply.JumpTime = 0
					end
				-- Set ability to normal/double jump if on ground and not grappling
				elseif ply:OnGround() and ( ( not ply.Grapple ) or ( not ply.GrappleHook ) or ( not IsValid( ply.GrappleHook ) ) or ( not ply.GrappleHook.GrappleAttached) ) then
					ply.InAir = false
					ply.Jumped = false
					ply.JumpTime = 0
				elseif ( not ply:OnGround() ) then
					ply.InAir = true
				end
			else
				-- Don't remove the shield on player death, to allow for it rolling around
				-- (Cleans up after SkyView.Config.RemovePropTime)
				ply.Shield = nil
			end
		end
	end,
	KeyPress = function( self, ply, key )
		if ply:Alive() then
			if key == IN_USE then
				self:AddGrapple( ply )
				ply.InAir = true
				ply.Jumped = true
			end
			if key == IN_ATTACK and !ply.ShieldMade and !ply.Grapple then
				if !ply.PropCD or ply.PropCD == 0 or ply.PropCD > 0 and CurTime() >= ply.PropCD then
					local prop = ents.Create( "sky_physprop" )
						local pos = ply:GetPos()
						local fireangle = ply:EyeAngles()
						local forward = fireangle:Forward()
						local throwPos = ply:EyePos() + ( forward * 50 )
						local throwVelocity = ( forward * 3000 + ply:GetVelocity() )
						prop:SetPos( throwPos )
						prop:SetAngles( fireangle )
						prop.Owner = ply
					prop:Spawn()

					-- Throw the prop, setting its owner
					prop:Throw( throwPos, throwVelocity, ply )
					prop:SetPropOwner(ply)

					ply.PropCD = CurTime() + PROP_COOLDOWN
				end
			end
		end
	end,
	KeyRelease = function( self, ply, key )
		if ply:Alive() then
			if key == IN_USE then
				self:RemoveGrapple( ply )
			end
		end
	end,
	PlayerDeath = function( self, victim, inflictor, attacker )
		-- Runs on SERVER realm!
		-- victim/attacker

		local attacker = inflictor.Owner
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
	GetFallDamage = function( ply, speed )
		return 0
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()

		-- Scores
		local size = ScrH() / ( #PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) * 8 )
		local x = size * 2
		local y = ScrH() - size * 2
		--for ply, k in pairs( self.Players ) do
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			local txt = "" .. ply:GetNWInt( "Score", 0 )
			local font = "DermaLarge"
			local border = 16
			local colour = ply:GetColour()
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
			self:RemoveGrapple( ply )
		end
		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_TIMETRAVEL )
			end
		end
	end,
	SetupMove = function( self, ply, mv )
	end,
	SetupWorldFog = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
	end,
	PostDrawTranslucentRenderables = function( self, depth, sky )
		-- Don't draw the world?
		-- render.Clear( 0, 0, 0, 255 )
		-- render.ClearDepth()
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- ply.CurrentAngles = ply.CurrentAngles or 0
		-- 	local target = 0
		-- 		if ( ply.OnWall ) then
		-- 			target = TILT_WALL * -ply.WallRunDirection
		-- 		else
		-- 			target = target + ( ply:KeyDown( IN_MOVELEFT ) and -TILT_WALK or 0 )
		-- 			target = target + ( ply:KeyDown( IN_MOVERIGHT ) and TILT_WALK or 0 )
		-- 		end
		-- 	ply.CurrentAngles = Lerp( FrameTime() * 10, ply.CurrentAngles, target )
		-- angles:RotateAroundAxis( angles:Forward(), ply.CurrentAngles )

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

	-- Custom functions
	AddWorld = function( self )
		
	end,
	RemoveWorld = function( self )
		
	end,
	Think_Shield = function( self, ply )
		if ( ply:KeyDown( IN_ATTACK2 ) ) then
			if ( not ply.ShieldMade ) then
				ply.ShieldMade = true
	
				-- Spawn the shield
				local shield = ents.Create("sky_physprop")
					shield:SetModel( "models/props_interiors/VendingMachineSoda01a_door.mdl" )
					shield:SetPos( ply:EyePos() + ply:GetForward() * 50 )
					shield:SetAngles( ply:GetAngles() )
					shield.IsShield = true
					shield.IsActiveShield = true
					shield.MeShield = true
					shield.Owner = ply
				shield:Spawn()
				ply.Shield = shield
	
				-- Make it immovable
				local obj = shield:GetPhysicsObject()
				if ( obj and IsValid( obj ) ) then
					obj:SetMass( 90000 )
				end
			elseif ( ply.Shield and IsValid( ply.Shield ) ) then
				-- Do not remove it when the player is holding it
				ply.Shield.RemoveTime = CurTime() + PROP_REMOVETIME
			end
		elseif ( ( not ply:KeyDown( IN_ATTACK2 ) ) and ply.ShieldMade ) then
			if ( ply.Shield and IsValid( ply.Shield ) ) then
				ply.Shield:Remove()
			end
			ply.ShieldMade = false
		end
		if ply.ShieldMade and ply.Shield and IsValid( ply.Shield ) then
			ply.Shield:SetPos( ply:EyePos() + ply:GetForward() * 50 )
			ply.Shield:SetAngles( ply:GetAngles() )
		end
	end,
	AddGrapple = function( self, ply )
		-- For some reason the old hook is still around, delete
		self:RemoveGrapple( ply )

		-- Create the grapple
		ply.Grapple = true

		-- Find the furthest point away from the player (up to a maximum) to create the hook
		-- This stops it from being shot out of the world, while also firing it from without the player's body
		local distance = 100
		local raytrace = util.TraceLine( {
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * distance,
			filter = {
				ply
			}
		} )
		distance = math.min( 100, distance * raytrace.Fraction )

		-- Create the grapple hook physics object, which will fly forward of the player
		ply.GrappleHook = ents.Create( "sky_grapple" )
			ply.GrappleHook.Direction = ply:EyeAngles():Forward()
			ply.GrappleHook:SetPos( ply:EyePos() + ( ply.GrappleHook.Direction * distance ) )
			ply.GrappleHook.Owner = ply
			col = ply:GetPlayerColor()
				col = Color( col.x * 255, col.y * 255, col.z * 255 )
			ply.GrappleHook:SetColor( col )
		ply.GrappleHook:Spawn()
	end,
	RemoveGrapple = function( self, ply )
		-- Delete the grapple
		ply.Grapple = false

		if ( ply.GrappleHook and IsValid( ply.GrappleHook ) ) then
			-- Entity defined function to play a grapple retract animation before removal
			ply.GrappleHook:HookRemove()
		end

		-- Enable gravity on the player
		ply:SetGravity( 1.1 )
		ply:SetMoveType( MOVETYPE_WALK )
	end,
} )

-- Hotreload helper
if ( SERVER ) then
	if ( GAMEMODE ) then
		local self = GAMEMODE.Games[NAME]
		self:RemoveWorld()
		self:AddWorld()
	end
end

/////////////////////////////////////////////////////////////////////////
SkyView.Config.FirstPerson = true --Set to true to use firstperson
--[[
	On the topic of First Person in this gamemode:
	- If first person is enabled, the props will shoot where you are looking. 
	- If first person is disabled, the props will shoot where you are facing.
]]--
SkyView.Config.ReflectNum = 1 --Set how much it reflects
--[[
	The lower it is, the less crazy it is.
--]]
SkyView.Config.RemovePropTime = 3 --Set how quick it removes props after spawned in
--[[
	The thing with this is that the higher it is, the more lag your server will have.
]]--
SkyView.Config.DoubleJumpTime = 0.3 --Set how long the player can double jump after jumping (In seconds, 0.3 is miliseconds)
--[[
	The lower this is, the quicker players will be able to double jump
--]]
SkyView.Config.PropSpawnCoolDown = 0.5 --Set how long until a player can spawn another prop
--[[
	For more chaos, decrease this variable
--]]
SkyView.Config.StatTracking = true --Set whether or not the gamemode should track positions of player jumps, deaths, etc
--[[
	Turning this on may increase server lag
--]]
SkyView.Config.ShowHalos = true --Set whether or not the players should have halos
--[[
	
--]]
SkyView.Config.MaxPropsPerPlayer = 5 --Max number of props belonging to a player in the world at once
--[[
	The higher this is, the more likely the server is to lag/crash
--]]
SkyView.Config.MaxLivesPerPlayer = 5 --Max number of lives per player per round
--[[
	The higher this is, the longer rounds will last; and the more likely the server is to lag/crash
--]]
SkyView.Config.SpawnInvulnerabilityTime = 2 --How long players should be invulnerable to damage for after spawning
--[[
	
--]]
SkyView.Config.RoundEndTime = 20 --The gloat time at the end of rounds before the new one begins
--[[
	This needs to be longer than 16 seconds in order to play the outro music
--]]

-- Fire-able props
GM.PropDescriptions =
{
	["models/props_c17/FurnitureBathtub001a.mdl"] = { 1, "Bath", Color( 39, 174, 96 ) },
	["models/props_borealis/bluebarrel001.mdl"] = { 2, "Barrel", Color( 155, 89, 182 ) },
	["models/props_c17/furnitureStove001a.mdl"] = { 3, "Stove", Color( 41, 128, 185 ) },
	["models/props_c17/FurnitureFridge001a.mdl"] = { 4, "Fridge", Color( 52, 73, 94 ) },
	["models/props_c17/oildrum001.mdl"] = { 1, "Oil Drum", Color( 22, 160, 133 ) },
	["models/props_c17/oildrum001_explosive.mdl"] = { 1, "Explosive Drum", Color( 230, 126, 34 ) },
	["models/props_junk/PlasticCrate01a.mdl"] = { 1, "Crate", Color( 231, 76, 60 ) },
	["models/props_c17/FurnitureSink001a.mdl"] = { 1, "Sink", Color( 26, 188, 156 ) },
	["models/props_c17/FurnitureCouch001a.mdl"] = { 1, "Couch", Color( 46, 204, 113 ) },
	["models/Combine_Helicopter/helicopter_bomb01.mdl"] = { 1, "Bomb", Color( 52, 152, 219 ) },
	["models/props_combine/breenglobe.mdl"] = { 1, "Globe", Color( 142, 68, 173 ) },
	["models/props_combine/breenchair.mdl"] = { 1, "Chair", Color( 44, 62, 80 ) },
	["models/props_docks/dock01_cleat01a.mdl"] = { 1, "Cleate", Color( 241, 196, 15 ) },
	["models/props_interiors/VendingMachineSoda01a.mdl"] = { 1, "Vending Machine", Color( 243, 156, 18 ) },
	["models/props_interiors/Furniture_Couch01a.mdl"] = { 1, "Couch", Color( 211, 84, 0 ) },
	["models/props_junk/plasticbucket001a.mdl"] = { 1, "Bucket", Color( 192, 57, 43 ) },
	["models/props_lab/filecabinet02.mdl"] = { 1, "File Cabinet", Color( 189, 195, 199 ) },
	["models/props_trainstation/trashcan_indoor001a.mdl"] = { 1, "Bin", Color( 149, 165, 166 ) },
	["models/props_vehicles/apc_tire001.mdl"] = { 1, "Tire", Color( 127, 140, 141 ) },
	["models/props_wasteland/light_spotlight01_lamp.mdl"] = { 1, "Spotlight", Color( 210, 82, 127 ) },
	["models/props_junk/TrafficCone001a.mdl"] = { 1, "Cone", Color( 144, 198, 149 ) }
}
