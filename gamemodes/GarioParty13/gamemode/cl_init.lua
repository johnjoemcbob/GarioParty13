--
-- Gario Party 13
-- 28/06/20
--
-- Main Clientside
--

include( "shared.lua" )

include( "cl_util.lua" )
include( "cl_modelcache.lua" )
include( "cl_scene.lua" )

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

-- More in sh_util.lua
function draw.Circle( x, y, radius, seg, rotate )
	local cir = GAMEMODE.GetCirclePoints( x, y, radius, seg, rotate )
	surface.DrawPoly( cir )
end

function draw.CircleSegment( x, y, radius, seg, thickness, offset, percent, drawlater )
	if ( thickness == 0 ) then
		return draw.Circle( x, y, radius, seg )
	end

	local shapes = {}

	local minseg = seg * offset / 100
	local maxseg = seg * ( percent + offset ) / 100
	local numsegrow = maxseg - minseg + 1 -- Extra one each row

	local cirtotal, cirtotalx, cirtotaly = 0, 0, 0

	for currentseg = minseg, maxseg - 1 do
		local cir = {}
			-- 1
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
			-- 3
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
			-- 4
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1

			-- 1
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 4
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 2
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
		if ( not drawlater ) then
			surface.DrawPoly( cir )
		else
			table.insert( shapes, cir )
		end
	end

	local centerx, centery
		centerx = cirtotalx / cirtotal
		centery = cirtotaly / cirtotal
	return centerx, centery, shapes
	-- local a = math.rad( ( ( minseg / seg ) * -360 ) )
	-- return ( x + math.sin( a ) * ( radius - thickness ) ), ( y + math.cos( a ) * ( radius - thickness ) )
end

function draw.StencilBasic( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable( true )
		render.SetStencilWriteMask( 255 )
		render.SetStencilTestMask( 255 )
		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_REPLACE )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
		render.SetBlend( 0 ) --makes shit invisible
		render.SetStencilReferenceValue( 10 )
			mask()
		render.SetBlend( 1 )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
			inner()
	render.SetStencilEnable( false )
end

local current_colmods = {}
	function render.SetColourModulation( col )
		render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
	end
	function render.GetColourModulation()
		if ( #current_colmods == 0 ) then
			return COLOUR_WHITE
		end
		return current_colmods[#current_colmods]
	end

	function render.PushColourModulation( col )
		render.SetColourModulation( col )
		table.insert( current_colmods, col )
	end

	function render.PopColourModulation()
		if ( #current_colmods == 0 ) then
			render.SetColourModulation( COLOUR_WHITE )
		else
			local last = #current_colmods
			render.SetColourModulation( current_colmods[last] )
			table.remove( current_colmods, last )
		end
	end

concommand.Add( "ggcj_getpos", function( ply, cmd, args )
	print( GetPrettyVector( ply:GetPos() ) )
end )

concommand.Add( "ggcj_getent", function( ply, cmd, args )
	-- TODO get trace ent and displays
end )

concommand.Add( "ggcj_getprops", function( ply, cmd, args )
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
