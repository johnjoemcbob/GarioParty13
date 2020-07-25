--
-- Gario Party 13
-- 28/06/20
--
-- Main Clientside
--

include( "shared.lua" )

include( "cl_util.lua" )
include( "cl_fonts.lua" )
include( "cl_music.lua" )
include( "cl_modelcache.lua" )
include( "cl_scene.lua" )
include( "cl_transition.lua" )
include( "cl_backgrounds.lua" )

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()
	LocalPlayer().ViewModelPos = Vector( 0, 0, 0 )
	LocalPlayer().ViewModelAngles = Angle( 0, 0, 0 )
end

function GM:Think()
	
end

function GM:PreRender()
	
end

function GM:PostDrawOpaqueRenderables()
	
end

function GM:HUDPaint()
	
end
-------------------------
  -- /Gamemode Hooks --
-------------------------

concommand.Add( "gp13_getpos", function( ply, cmd, args )
	print( GetPrettyVector( ply:GetPos() ) )
end )

concommand.Add( "gp13_getprops", function( ply, cmd, args )
	-- Get trace entity
	local tr = util.TraceLine( {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:EyeAngles():Forward() * 10000,
		filter = ply,
	} )

	local function add( ent, pos, ang )
		return "	{\n" ..
			"		\"" .. ent:GetModel() .. "\",\n" ..
			"		" .. GetPrettyVector( pos ) .. ",\n" ..
			"		" .. GetPrettyAngle( ang ) .. ",\n" ..
		"	},\n"
	end

	local formatted = "{\n"
	if ( tr.Entity ) then
		-- Add first at zero
		local pos_base = tr.Entity:GetPos()
		local ang_base = tr.Entity:GetAngles()
		local pos = Vector( 0, 0, 0 )
		local ang = Angle( 0, 0, 0 )
		formatted = formatted .. add( tr.Entity, pos, ang )

		-- Find all other props
		for k, ent in pairs( ents.FindByClass( "prop_physics" ) ) do
			if ( ent != tr.Entity ) then
				-- Their position relative to this base ent
				pos = ent:GetPos() - pos_base
				ang = ent:GetAngles() - ang_base
				formatted = formatted .. add( ent, pos, ang )
			end
		end
	end
	formatted = formatted .. "}"

	print( formatted )
end )
