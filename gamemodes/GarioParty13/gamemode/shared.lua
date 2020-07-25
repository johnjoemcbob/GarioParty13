--
-- Gario Party 13
-- 28/06/20
--
-- Main Shared
--

GM.Name = "Gario Party 13!"
GM.Author = "johnjoemcbob"
GM.Email = ""
GM.Website = ""

-- Base Game
GM.DERIVE_SANDBOX = false
if GM.DERIVE_SANDBOX then
	DeriveGamemode( "Sandbox" ) -- For testing purposes, nice to have spawn menu etc
else
	DeriveGamemode( "base" )
end

-- Globals
GM.Epsilon				= 0.001
GM.GamemodePath			= "gamemodes/GarioParty13/"
GM.ContentPath			= ""

DEBUG_NOSTRIP = false

HOOK_PREFIX			= "GarioParty13_"
WORKSHOP_ID			= ""

TRANSITION_DURATION	= 1

-- COLOURS
COLOUR_BLACK					= Color( 0, 0, 0, 255 )
COLOUR_WHITE					= Color( 255, 255, 255, 255 )
COLOUR_UI_BACKGROUND			= Color( 50, 100, 200, 255 )
COLOUR_UI_BACKGROUND_HIGHLIGHT	= Color( 70, 120, 220, 255 )
COLOUR_UI_BACKGROUND_TRANS		= Color( 255, 255, 255, 50 )
COLOUR_UI_TEXT_DARK				= Color( 80, 80, 80, 255 )
COLOUR_UI_TEXT_MED				= Color( 160, 160, 160, 255 )
COLOUR_UI_TEXT_LIGHT			= Color( 220, 220, 220, 255 )
COLOUR_POSITIVE					= Color( 50, 200, 50, 255 )
COLOUR_NEGATIVE					= Color( 200, 50, 50, 255 )
COLOUR_PLACING					= {
	Color( 200, 200, 50, 255 ),
	Color( 150, 150, 150, 255 ),
	Color( 150, 50, 50, 255 ),
}
GM.ColourPalette				= {
	Color( 0, 184, 148, 255 ),
	Color( 255, 159, 243, 255 ),
	Color( 108, 92, 231, 255 ),
	Color( 0, 206, 201, 255 ),
	Color( 9, 132, 227, 255 ),
	Color( 253, 203, 110, 255 ),
	Color( 225, 112, 85, 255 ),
	Color( 214, 48, 49, 255 ),
	Color( 232, 67, 147, 255 ),
}

PLAYERMODELS = {
	"models/player/alyx.mdl",
	"models/player/breen.mdl",
	"models/player/barney.mdl",
	"models/player/monk.mdl",
	"models/player/kleiner.mdl",
	"models/player/gman_high.mdl",
	"models/player/mossman.mdl",
	"models/player/eli.mdl",

	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",

	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
}

-- Net Strings

-- Resources
Sound_OrchestraHit = Sound( "orch.wav" )

-- Includes (after globals)
if ( SERVER ) then
	AddCSLuaFile( "sh_util.lua" )
	AddCSLuaFile( "sh_worldtext.lua" )
	AddCSLuaFile( "sh_playerstates.lua" )
	AddCSLuaFile( "sh_gamestates.lua" )
	AddCSLuaFile( "sh_board.lua" )
	AddCSLuaFile( "sh_turn.lua" )
	AddCSLuaFile( "sh_dice.lua" )
	AddCSLuaFile( "sh_score.lua" )
	AddCSLuaFile( "sh_minigames.lua" )
	AddCSLuaFile( "sh_minigames_vars.lua" )
	AddCSLuaFile( "sh_minigames_hooks.lua" )
end
include( "sh_util.lua" )
include( "sh_worldtext.lua" )
include( "sh_playerstates.lua" )
include( "sh_gamestates.lua" )
include( "sh_board.lua" )
include( "sh_turn.lua" )
include( "sh_dice.lua" )
include( "sh_score.lua" )
include( "sh_minigames.lua" )
include( "sh_minigames_vars.lua" )
include( "sh_minigames_hooks.lua" )

local meta = FindMetaTable( "Player" )
function meta:GetColour()
	return GAMEMODE.ColourPalette[self:GetNWInt( "Colour", 1 )]
end

function GetLoopedColour( ind )
	return GAMEMODE.ColourPalette[math.max( 0, math.floor( ind % #GAMEMODE.ColourPalette ) )]
end
