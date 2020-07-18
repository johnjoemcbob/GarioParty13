--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

STATE_LOBBY = "Lobby"

local sponsors = {
	"https://media.gmodstore.com/_/competition_banners/2020/gmodstore.png",
	"https://media.gmodstore.com/_/competition_banners/2020/zerochain.png",
	"https://media.gmodstore.com/_/competition_banners/2020/titsrp.png",
	"https://media.gmodstore.com/_/competition_banners/2020/willox.png",
	"https://media.gmodstore.com/_/competition_banners/2020/wisp.png",
	"https://media.gmodstore.com/_/competition_banners/2020/elitelupus.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/diablosbanner.png",
	"https://media.gmodstore.com/_/competition_banners/2020/crident.png",
	"https://media.gmodstore.com/_/competition_banners/2020/hexane.png",
	"https://media.gmodstore.com/_/competition_banners/2020/vcmod.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/fudgy.png",
	"https://media.gmodstore.com/_/competition_banners/2020/tombat-banner.png",
	"https://media.gmodstore.com/_/competition_banners/2020/babl.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/gmodel.png",
	"https://media.gmodstore.com/_/competition_banners/2020/tehbasshunter.png",
	"https://media.gmodstore.com/_/competition_banners/2020/molly-network.png",
}

GM.AddGameState( STATE_LOBBY, {
	OnStart = function( self )
		-- TODO TEMP
		timer.Simple( 10, function() GAMEMODE:SwitchState( STATE_BOARD ) end )
	end,
	OnThink = function( self )
		
	end,
	OnFinish = function( self )
		
	end,
})
