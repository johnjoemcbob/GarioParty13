--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

STATE_JOINED = "Joined"

GM.AddPlayerState( STATE_JOINED, {
	OnStart = function( self, ply )
		print( "start!" )
	end,
	OnThink = function( self, ply )
		
	end,
	OnFinish = function( self, ply )
		print( "finish!" )
	end,
})
