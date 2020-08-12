--
-- Gario Party 13
-- 30/06/20
--
-- Game: Boats
--

GM.AddGame( "Boats", "", {
	Playable = false,
	Author = "johnjoemcbob",
	Colour = Color( 100, 255, 150, 255 ),
	TagLine = "Yarr!",
	Instructions = "Defeat the enemy boats and conquer the seven seas!",
	Controls = "Forward/Back to raise/lower your masts\nPrimary attack fires portside cannons\nSecondary attack fires starboard cannons",
	GIF = "https://i.imgur.com/lEkurVo.gif",

	Init = function( self )
		-- Runs on CLIENT and SERVER realms!
		-- When game is first loaded
	end,
	Destroy = function( self )
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

		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				timer.Simple( 0.4, function()
					local ent = nil
						for k, v in pairs( ents.FindByClass( "gp13_ship" ) ) do
							print( v:GetOwner() )
							if ( v:GetOwner() == LocalPlayer() ) then
								ent = v
								break
							end
						end
					LocalPlayer().Boat = ent
					Music:Play( MUSIC_TRACK_BOATS, LocalPlayer().Boat )
				end )
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

		if ( CLIENT ) then
			if ( ply == LocalPlayer() ) then
				Music:Pause( MUSIC_TRACK_BOATS, LocalPlayer().Boat )
			end
		end

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
