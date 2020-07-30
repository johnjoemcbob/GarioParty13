--
-- Gario Party 13
-- 28/06/20
--
-- Main Serverside
--

-- LUA Downloads
AddCSLuaFile( "shared.lua" )

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_util.lua" )
AddCSLuaFile( "cl_fonts.lua" )
AddCSLuaFile( "cl_music.lua" )
AddCSLuaFile( "cl_modelcache.lua" )
AddCSLuaFile( "cl_scene.lua" )
AddCSLuaFile( "cl_transition.lua" )
AddCSLuaFile( "cl_backgrounds.lua" )

-- LUA Includes
include( "shared.lua" )

-- Resources
resource.AddFile( "data/garioparty13_/scenes/city.json" )
resource.AddFile( "data/garioparty13_/scenes/win.json" )
resource.AddWorkshop( WORKSHOP_ID ) -- This Content
resource.AddWorkshop( "752655103" ) -- Goose
resource.AddWorkshop( "331841113" ) -- Civ

-- Net
util.AddNetworkString( NET_INITJOINSERVER )

net.Receive( NET_INITJOINSERVER, function( len, ply )
	hook.Run( "PlayerFullLoad", self, ply )
end )

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()
	if ( WORKSHOP_ID == "" ) then
		print( "GARIO PARTY 13" )
		print( "WARNING:" )
		print( "WORKSHOP_ID = ''" )
		print( "WORKSHOP_ID NOT SET" )
		print( "NO CONTENT BEING DISTRIBUTED TO CLIENTS" )
		print( "BAD" )
		print( "WARNING" )
	end
end

function GM:InitPostEntity()
	-- Force construct
	if ( game.GetMap() != "gm_construct" ) then
		local msg = "WRONG MAP - SWITCHING"
		print( msg )
		PrintMessage( HUD_PRINTCENTER, msg )
		--timer.Simple( 1, function()
			RunConsoleCommand( "changelevel", "gm_construct" )
		--end )
		return
	end
end

hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerInitialSpawn", function( ply )
	ply.InitialFOV = ply:GetFOV()
	ply:SetNWInt( "Colour", math.min( #player.GetAll(), #GAMEMODE.ColourPalette ) )

	if ( !GAMEMODE.DERIVE_SANDBOX ) then
		ply:SetModel( PLAYERMODELS[math.random( 1, #PLAYERMODELS )] )
	end
end )

hook.Add( "PlayerSpawn", HOOK_PREFIX .. "PlayerSpawn", function( ply )
	timer.Simple( 0, function()
		ply:SetWalkSpeed( 250 )
		ply:SetRunSpeed( 250 )
	end )
end )

function GM:Think()
	
end

function GM:PlayerDisconnected( ply )
	
end
-------------------------
  -- /Gamemode Hooks --
-------------------------
