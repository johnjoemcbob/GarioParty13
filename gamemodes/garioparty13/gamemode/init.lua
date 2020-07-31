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
AddCSLuaFile( "cl_scoreboard.lua" )

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
	hook.Run( "PlayerFullLoad", ply )
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

	SaveJSONs()
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

-- Generate jsons
function SaveJSONs()
	file.CreateDir( HOOK_PREFIX .. "/scenes/" )
	SaveJSON( HOOK_PREFIX .. "/scenes/", "city.json", [[{
		"base": {
			"2": "[-50 0 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"road2": {
			"2": "[-82.4 -195.78872 0]",
			"1": "models/props_phx/huge/road_curve.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"road3": {
			"2": "[-50 235 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"road4": {
			"2": "[-50 470 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"road5": {
			"2": "[-50 705 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"road6": {
			"2": "[-50 940 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"car1": {
			"2": "[-50 -80 25]",
			"1": "models/props_vehicles/truck001a.mdl",
			"3": "{0 80 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"car2": {
			"2": "[-50 120 0]",
			"1": "models/combine_apc.mdl",
			"3": "{0 10 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"car3": {
			"2": "[-50 220 0]",
			"1": "models/props_vehicles/car003a_physics.mdl",
			"3": "{0 10 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"car4": {
			"2": "[-40 250 0]",
			"1": "models/props_vehicles/car002b_physics.mdl",
			"3": "{30 30 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"car5": {
			"2": "[-50 360 25]",
			"1": "models/props_vehicles/truck003a.mdl",
			"3": "{0 -100 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"car6": {
			"2": "[-60 480 25]",
			"1": "models/props_vehicles/car002a_physics.mdl",
			"3": "{0 100 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"train1": {
			"2": "[-70 680 30]",
			"1": "models/props_trainstation/train003.mdl",
			"3": "{90 10 0}",
			"Scale": "[0.4 0.4 0.4]"
		},
		"generator1": {
			"2": "[170 780 30]",
			"1": "models/props_vehicles/generatortrailer01.mdl",
			"3": "{0 -50 0}",
			"Scale": "[1 1 1]"
		},
		"ammo1": {
			"2": "[0 -320 40]",
			"1": "models/Items/ammocrate_ar2.mdl",
			"3": "{0 -50 0}",
			"Scale": "[3 3 3]"
		},
		"sign1": {
			"2": "[900 720 90]",
			"1": "models/props_lab/bewaredog.mdl",
			"3": "{0 -150 0}",
			"Scale": "[3 3 3]"
		},
		"chess1": {
			"2": "[590 480 0]",
			"1": "models/props_lab/chess.mdl",
			"3": "{0 -150 0}",
			"Scale": "[8 8 8]"
		},
		"boot1": {
			"2": "[890 -680 200]",
			"1": "models/props_junk/Shoe001a.mdl",
			"3": "{0 -150 0}",
			"Scale": "[50 50 50]"
		},
		"mug1": {
			"2": "[1090 1280 200]",
			"1": "models/props_junk/garbage_coffeemug001a.mdl",
			"3": "{0 -150 0}",
			"Scale": "[100 100 100]"
		},
		"background_buildings": {
			"2": "[800 550 0]",
			"1": "models/props_buildings/row_res_1_fullscale.mdl",
			"3": "{0 90 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"background_buildings2": {
			"2": "[600 1050 0]",
			"1": "models/props_buildings/row_res_1_fullscale.mdl",
			"3": "{0 -20 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"background_buildings3": {
			"2": "[300 -450 0]",
			"1": "models/props_buildings/row_res_2_fullscale.mdl",
			"3": "{0 40 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"ground": {
			"2": "[-940 -940 -2]",
			"1": "models/hunter/plates/plate8x8.mdl",
			"3": "{0 0 0}",
			"Scale": "[5 5 1]",
			"Material": "models/debug/debugwhite",
			"Colour": "[5 100 30]"
		},
		"ground2": {
			"2": "[940 -940 -2]",
			"1": "models/hunter/plates/plate8x8.mdl",
			"3": "{0 0 0}",
			"Scale": "[5 5 1]",
			"Material": "models/debug/debugwhite",
			"Colour": "[5 100 30]"
		},
		"ground3": {
			"2": "[940 940 -2]",
			"1": "models/hunter/plates/plate8x8.mdl",
			"3": "{0 0 0}",
			"Scale": "[5 5 1]",
			"Material": "models/debug/debugwhite",
			"Colour": "[5 100 30]"
		},
		"ground4": {
			"2": "[-940 940 -2]",
			"1": "models/hunter/plates/plate8x8.mdl",
			"3": "{0 0 0}",
			"Scale": "[5 5 1]",
			"Material": "models/debug/debugwhite",
			"Colour": "[5 100 30]"
		},
		"sky": {
			"2": "[0 0 -200]",
			"1": "models/props_phx/construct/metal_tube.mdl",
			"3": "{0 0 0}",
			"Scale": "[100 100 100]",
			"Material": "models/debug/debugwhite",
			"Colour": "[0 255 255]"
		},
		"carousel": {
			"2": "[400 275 0]",
			"1": "models/props_c17/playground_carousel01.mdl",
			"3": "{0 -30 0}",
			"Scale": "[1 1 1]"
		},
		"slide": {
			"2": "[300 200 0]",
			"1": "models/props_c17/playgroundslide01.mdl",
			"3": "{0 -220 0}",
			"Scale": "[0.5 0.5 0.5]"
		},
		"seesaw_legs": {
			"2": "[320 100 0]",
			"1": "",
			"3": "{0 5 0}",
			"Scale": "[1 1 1]"
		},
		"seesaw": {
			"2": "[320 100 19.6]",
			"1": "models/props_c17/playground_teetertoter_seat.mdl",
			"3": "{0 5 -10}",
			"Scale": "[1 1 1]"
		},
		"crane_legs": {
			"2": "[450 600 0]",
			"1": "models/cranes/crane_frame.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"crane_body": {
			"2": "[450 600 43]",
			"1": "models/cranes/crane_docks.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"trees1": {
			"2": "[540 30 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -30 0}",
			"Scale": "[2 2 2]"
		},
		"trees2": {
			"2": "[700 -200 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[2 2 2]"
		},
		"trees3": {
			"2": "[900 800 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[2 2 2]"
		},
		"trees4": {
			"2": "[450 800 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -80 0}",
			"Scale": "[2 2 2]"
		},
		"trees5": {
			"2": "[-150 -100 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -20 0}",
			"Scale": "[2 2 2]"
		},
		"trees6": {
			"2": "[-110 300 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 10 0}",
			"Scale": "[2 2 2]"
		},
		"trees7": {
			"2": "[200 -350 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 120 0}",
			"Scale": "[2 2 2]"
		},
		"rock1": {
			"2": "[200 -350 0]",
			"1": "models/props_wasteland/rockgranite02c.mdl",
			"3": "{0 120 0}",
			"Scale": "[2 2 2]"
		},
		"rock2": {
			"2": "[300 550 0]",
			"1": "models/props_wasteland/rockgranite02c.mdl",
			"3": "{0 20 0}",
			"Scale": "[2 2 2]"
		},
		"rock3": {
			"2": "[100 350 0]",
			"1": "models/props_wasteland/rockgranite03c.mdl",
			"3": "{0 20 0}",
			"Scale": "[2 2 2]"
		},
		"rock4": {
			"2": "[250 0 -40]",
			"1": "models/props_wasteland/rockgranite01c.mdl",
			"3": "{0 70 0}",
			"Scale": "[1 1 1]"
		},
		"rock5": {
			"2": "[350 800 0]",
			"1": "models/props_wasteland/rockcliff01k.mdl",
			"3": "{0 70 0}",
			"Scale": "[1 1 1]"
		},
		"background_trees1": {
			"2": "[1400 1400 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[4 10 4]"
		},
		"background_trees2": {
			"2": "[1700 700 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 10 0}",
			"Scale": "[4 10 5]"
		},
		"background_trees3": {
			"2": "[1700 -500 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -10 0}",
			"Scale": "[4 10 4]"
		},
		"background_trees4": {
			"2": "[1400 -1500 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -30 0}",
			"Scale": "[4 10 6]"
		},
		"background_building": {
			"2": "[700 0 0]",
			"1": "models/props_phx/huge/evildisc_corp.mdl",
			"3": "{0 30 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"background_tower": {
			"2": "[520 -470 0]",
			"1": "models/props_phx/huge/tower.mdl",
			"3": "{0 70 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"server1": {
			"2": "[470 50 0]",
			"1": "",
			"3": "{0 70 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"server2": {
			"2": "[230 350 0]",
			"1": "",
			"3": "{0 -50 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"server3": {
			"2": "[70 500 0]",
			"1": "",
			"3": "{0 -70 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"server4": {
			"2": "[630 750 0]",
			"1": "",
			"3": "{0 -10 0}",
			"Scale": "[0.1 0.1 0.1]"
		}
	}
	]] )
	SaveJSON( HOOK_PREFIX .. "/scenes/", "win.json", [[{
		"base": {
			"2": "[0 0 0]",
			"1": "models/props_phx/huge/road_medium.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"background_buildings": {
			"2": "[800 550 0]",
			"1": "models/props_buildings/row_res_1_fullscale.mdl",
			"3": "{0 90 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"2": {
			"2": "[-32.4 -195.78872 0]",
			"1": "models/props_phx/huge/road_curve.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.2 0.2 0.2]"
		},
		"ground": {
			"2": "[0 0 -2]",
			"1": "models/hunter/plates/plate8x8.mdl",
			"3": "{0 0 0}",
			"Scale": "[10 10 1]",
			"Material": "models/debug/debugwhite",
			"Colour": "[50 80 30]"
		},
		"sky": {
			"2": "[0 0 -200]",
			"1": "models/props_phx/construct/metal_tube.mdl",
			"3": "{0 0 0}",
			"Scale": "[100 100 100]",
			"Material": "models/debug/debugwhite",
			"Colour": "[0 255 255]"
		},
		"carousel": {
			"2": "[400 275 0]",
			"1": "models/props_c17/playground_carousel01.mdl",
			"3": "{0 -30 0}",
			"Scale": "[1 1 1]"
		},
		"slide": {
			"2": "[300 200 0]",
			"1": "models/props_c17/playgroundslide01.mdl",
			"3": "{0 -220 0}",
			"Scale": "[0.5 0.5 0.5]"
		},
		"seesaw_legs": {
			"2": "[320 100 0]",
			"1": "models/props_c17/playground_teetertoter_stan.mdl",
			"3": "{0 5 0}",
			"Scale": "[1 1 1]"
		},
		"seesaw": {
			"2": "[320 100 19.6]",
			"1": "models/props_c17/playground_teetertoter_seat.mdl",
			"3": "{0 5 -10}",
			"Scale": "[1 1 1]"
		},
		"crane_legs": {
			"2": "[450 600 0]",
			"1": "models/cranes/crane_frame.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"crane_body": {
			"2": "[450 600 43]",
			"1": "models/cranes/crane_docks.mdl",
			"3": "{0 0 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"trees1": {
			"2": "[500 0 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -30 0}",
			"Scale": "[2 2 2]"
		},
		"trees2": {
			"2": "[700 -200 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[2 2 2]"
		},
		"trees3": {
			"2": "[900 800 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[2 2 2]"
		},
		"background_trees1": {
			"2": "[1400 1400 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 30 0}",
			"Scale": "[4 10 4]"
		},
		"background_trees2": {
			"2": "[1700 700 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 10 0}",
			"Scale": "[4 10 5]"
		},
		"background_trees3": {
			"2": "[1700 -500 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -10 0}",
			"Scale": "[4 10 4]"
		},
		"background_trees4": {
			"2": "[1400 -1500 0]",
			"1": "models/props_foliage/tree_springers_card_01_skybox.mdl",
			"3": "{0 -30 0}",
			"Scale": "[4 10 6]"
		},
		"background_building": {
			"2": "[700 0 0]",
			"1": "models/props_phx/huge/evildisc_corp.mdl",
			"3": "{0 30 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"background_tower": {
			"2": "[500 150 0]",
			"1": "models/props_phx/huge/tower.mdl",
			"3": "{0 70 0}",
			"Scale": "[0.1 0.1 0.1]"
		},
		"podium_1st": {
			"2": "[200 50 20]",
			"1": "models/hunter/blocks/cube025x05x025.mdl",
			"3": "{0 -20 90}",
			"Scale": "[4 4 4]"
		},
		"podium_2nd": {
			"2": "[216 94 -5]",
			"1": "models/hunter/blocks/cube025x05x025.mdl",
			"3": "{0 -20 90}",
			"Scale": "[4 4 4]"
		},
		"podium_3rd": {
			"2": "[184 6 -20]",
			"1": "models/hunter/blocks/cube025x05x025.mdl",
			"3": "{0 -20 90}",
			"Scale": "[4 4 4]"
		},
		"place1": {
			"2": "[170 35 68]",
			"1": "",
			"3": "{0 160 0}",
			"Scale": "[1 1 1]"
		},
		"place2": {
			"2": "[187 80 43]",
			"1": "",
			"3": "{0 170 0}",
			"Scale": "[1 1 1]"
		},
		"place3": {
			"2": "[150 -7 27]",
			"1": "",
			"3": "{0 145 0}",
			"Scale": "[1 1 1]"
		}
	}
	]] )
end
