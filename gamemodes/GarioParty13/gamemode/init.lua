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
AddCSLuaFile( "cl_modelcache.lua" )
AddCSLuaFile( "cl_scene.lua" )
AddCSLuaFile( "cl_transition.lua" )

-- LUA Includes
include( "shared.lua" )

-- Resources
resource.AddFile( "materials/eye.png" )
resource.AddFile( "sound/orch.wav" )
resource.AddFile( "sound/quack.wav" )
resource.AddFile( "sound/boo.wav" )
resource.AddFile( "sound/scared.wav" )
resource.AddFile( "sound/fall.wav" )
resource.AddFile( "sound/pop.wav" )
resource.AddWorkshop( "752655103" ) -- Goose
resource.AddWorkshop( "331841113" ) -- Civ

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()
	
end

function GM:InitPostEntity()
	
end

hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerInitialSpawn", function( ply )
	ply.InitialFOV = ply:GetFOV()
	ply:SetNWInt( "Colour", math.min( #player.GetAll(), #GAMEMODE.ColourPalette ) )
end )

hook.Add( "PlayerSpawn", HOOK_PREFIX .. "PlayerSpawn", function( ply )
	timer.Simple( 0, function()
		ply:SetWalkSpeed( 250 )
		ply:SetRunSpeed( 250 )
	end )
end )

function GM:Think()
	
end

function GM:HandlePlayerJumping( ply, vel )
	
end

function GM:PlayerDisconnected( ply )
	
end
-------------------------
  -- /Gamemode Hooks --
-------------------------
