--
-- Gario Party 13
-- 30/06/20
--
-- Game: Donut County
--

local PROPS = {}
local PROPS_NUMBER_TO_SPAWN = 5

local AREA = {
	Vector( 1800, -2100, 1160 ),
	Vector( 800, -1100, 1160 ),
}

local NAME = "Donut County"
GM.AddGame( NAME, "Default", {
	Playable = true,
	UnderConstruction = true,
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "Shluuuuurp",
	Instructions = "Move around and drop things into your hole to grow!",
	Controls = "Movement keys to.. move!",
	GIF = "https://i.imgur.com/coUppee.gif",
	World = {},

	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded

		if ( SERVER ) then
			self:RemoveWorld()
			self:AddWorld()
		end

		self.StartTime = CurTime()
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

		if ( SERVER ) then
			-- Set player as close by to help with driving? or something? idk
			ply:SetPos( Vector( 1298, -1585, 1600 ) )

			ply.Hole = ents.Create( "gp13_donuthole" )
				ply.Hole:SetPos( Vector( 1298, -1585, 1200 ) )
				ply.Hole:SetOwner( ply )
			ply.Hole:Spawn()
			timer.Simple( 0.4, function()
				ply.Hole:SetPos( Vector( 1298, -1585, 1137 )
				+ Vector( math.random( -100, 100 ), math.random( -100, 100 ), 0 )
			)
			end )
		end

		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				timer.Simple( 0.4, function()
					local ent = nil
						for k, v in pairs( ents.FindByClass( "gp13_donuthole" ) ) do
							print( v:GetOwner() )
							if ( v:GetOwner() == LocalPlayer() ) then
								ent = v
								break
							end
						end
					LocalPlayer().Donut = ent
					Music:Play( MUSIC_TRACK_DONUT, LocalPlayer().Donut )
				end )
			end
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	Think = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- Each update tick for this game, no reference to any player

		if ( self.StartTime + CONVAR_MINIGAME_TIMER:GetFloat() <= CurTime() ) then
			if ( GAMEMODE:GetStateName() == STATE_MINIGAME and GAMEMODE.GameStates[STATE_MINIGAME].Minigame == NAME ) then
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
		end
	end,
	PlayerThink = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
		
		local colour = LocalPlayer():GetColour()

		-- Timer
		local font = "DermaLarge"
		local width = ScrW() / 4
		local height = ScrH() / 16
		local x = ScrW() / 2
		local y = height
		local border = height / 8
		local elapsed = ( CurTime() - self.StartTime )
		local time = CONVAR_MINIGAME_TIMER:GetFloat() - elapsed
		local percent = time / CONVAR_MINIGAME_TIMER:GetFloat()
		if ( time >= 0 ) then
			surface.SetDrawColor( COLOUR_BLACK )
			surface.DrawRect( x - width / 2, y - height / 2, width, height )
			surface.SetDrawColor( colour )
			surface.DrawRect( x - width / 2, y - height / 2, width * percent, height )
			draw.SimpleText( math.ceil( time ), font, x, y, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		-- Scores
		local size = ScrH() / ( #PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) * 8 )
		local x = size * 2
		local y = ScrH() - size * 2
		--for ply, k in pairs( self.Players ) do
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			local txt = "" .. ply:GetNWInt( "Score", 0 )
			local font = "DermaLarge"
			local colour = ply:GetColour()
			local border = 16
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
	PostPlayerDraw = function( self, ply )
		-- Runs on CLIENT realm!
		-- ply
	end,
	PreDrawSkyBox = function( self )
		return true
	end,
	CalcView = function( self, ply, pos, angles, fov )
		-- Third person view!
		local angles = LocalPlayer():EyeAngles()
		local view = {}
		view.origin = pos-(angles:Forward()*150) + Vector( 0, 0, 1 )*0
		view.angles = angles
		view.fov = fov
		view.drawviewer = true
		view.zfar = 1000

		return view
	end,
	PlayerLeave = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_DONUT, ply.Donut )
			end
		end

		if ( SERVER ) then
			if ( ply.Hole != nil ) then
				ply.Hole:Remove()
				ply.Hole = nil
			end
		end
	end,

	-- Custom functions
	AddWorld = function( self )
		-- Props
		for k, size in pairs( PROPS ) do
			local tospawn = PROPS_NUMBER_TO_SPAWN * #PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
				if ( k == 1 ) then
					tospawn = tospawn * 2
				end
			for prop = 1, tospawn do
				local ent = GAMEMODE.CreateProp(
					size[math.random( 1, #size )],
					Vector( math.random( AREA[1].x, AREA[2].x ), math.random( AREA[1].y, AREA[2].y ), AREA[1].z ),
					Angle( 0, math.random( 0, 360 ), 0 ),
					true
				)
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
} )

PROPS = {
	["SMALL"] = {
		"models/props_junk/PopCan01a.mdl",
		"models/props_junk/CinderBlock01a.mdl",
	},
	["MEDIUM"] = {
		"models/props_junk/metalgascan.mdl",
		"models/props_junk/plasticbucket001a.mdl",
	},
	["LARGE"] = {
		"models/props_interiors/Furniture_Couch02a.mdl",
		"models/props_interiors/Furniture_chair03a.mdl",
		"models/props_c17/FurnitureTable001a.mdl",
		"models/props_c17/FurnitureTable002a.mdl",
		"models/props_c17/FurnitureTable003a.mdl",
		"models/props_c17/FurnitureWashingmachine001a.mdl",
		"models/props_c17/FurnitureCouch002a.mdl",
	},
	["MASSIVE"] = {
		"models/props_c17/furnitureStove001a.mdl",
		"models/props_c17/display_cooler01a.mdl",
		"models/props_c17/concrete_barrier001a.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_c17/Lockers001a.mdl",
		"models/props_interiors/VendingMachineSoda01a.mdl",
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
