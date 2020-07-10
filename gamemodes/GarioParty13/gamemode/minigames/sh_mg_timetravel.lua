--
-- Gario Party 13
-- 10/07/20
--
-- Game: Time Travel
--

local POS		= Vector( -2273, -2819, 768 )
local HEIGHT	= 1280 - 768
local OFF		= 0

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

local FOGS = {
	0,
	0.7,
}

local TIME_PRESENT	= 0
local TIME_FUTURE	= 1

GM.AddGame( "Time Travel", "Default", {
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
		end
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	KeyPress = function( self, ply, key )
		print( "hi" )
		if ( key == IN_ATTACK2 ) then
			-- TIME TRAVEL HERE
			--if ( ply:GetPos().z > POS.z + HEIGHT ) then
			if ( self:GetTimeZone( ply ) == TIME_FUTURE ) then
				-- In future, go to past
				ply:SetPos( ply:GetPos() + Vector( 0, 0, -HEIGHT - OFF ) )
				self:TimeTravel( ply, TIME_PRESENT )
			else
				-- In past, go to future
				ply:SetPos( ply:GetPos() + Vector( 0, 0, HEIGHT - OFF ) )
				self:TimeTravel( ply, TIME_FUTURE )
			end
		end
	end,
	KeyRelease = function( self, ply, key )
		if ( key == IN_ATTACK ) then
		end
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
	TimeTravel = function( self, ply, time )
		local current = self:GetTimeZone( ply )
		local target = time or TIME_PRESENT
			if ( time == nil and current == TIME_PRESENT ) then
				target = TIME_FUTURE
			end
		ply:SetNWInt( "TimeTravel", target )
	end,
	GetTimeZone = function( self, ply )
		--return ply:GetNWInt( "TimeTravel", TIME_PRESENT )
		return ( ply:GetPos().z >= HEIGHT * 2 ) and TIME_FUTURE or TIME_PRESENT
	end,
} )

-- Hotreload helper
if ( SERVER ) then
	local self = GAMEMODE.Games["Time Travel"]
	self:RemoveWorld()
	self:AddWorld()
end
