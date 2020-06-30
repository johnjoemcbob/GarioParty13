--
-- Gario Party 13
-- 30/06/20
--
-- Game: Donut County
--

GM.AddGame( "Donut County", "", {
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	Instructions = "Move around and drop things into your hole to grow!",

	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded
	end,
	PlayerJoin = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply

		if ( SERVER ) then
			ply.Hole = ents.Create( "gp13_donuthole" )
				ply.Hole:SetPos( Vector( math.random( -2065, 84 ), math.random( -714, 1119 ), -145.5 ) )
				ply.Hole:SetOwner( ply )
			ply.Hole:Spawn()
		end
	end,
	PlayerSpawn = function( self, ply )
		-- Runs on CLIENT and SERVER realms!
		-- ply
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
			if ( ply.Hole != nil ) then
				ply.Hole:Remove()
				ply.Hole = nil
			end
		end
	end,
} )
