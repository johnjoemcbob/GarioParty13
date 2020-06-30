--
-- Gario Party 13
-- 30/06/20
--
-- Game: Boats
--

GM.AddGame( "Boats", "", {
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	Instructions = "Use forward/back to raise/lower your masts\nPrimary attack fires portside cannons\nSecondary attack fires starboard cannons",

	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
		if ( SERVER ) then
			self:RemoveShip( ply )
			self:AddShip( ply )
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
	HUDPaint = function( self )
		-- Runs on CLIENT realm!
		-- LocalPlayer()
	end,
	Scoreboard = function( self, ply, row )
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
			self:RemoveShip( ply )
		end
	end,

	-- Custom functions
	AddShip = function( self, ply )
		ply.Ship = ents.Create( "gp13_ship" )
			ply.Ship:SetPos( Vector( math.random( -2105, 690 ), math.random( 2267, 6144 ), -158 ) )
			ply.Ship:SetOwner( ply )
		ply.Ship:Spawn()
	end,
	RemoveShip = function( self, ply )
		if ( ply.Ship != nil ) then
			ply.Ship:Remove()
			ply.Ship = nil
		end
	end,
} )
