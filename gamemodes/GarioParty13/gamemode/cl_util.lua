--
-- Gario Party 13
-- 28/06/20
--
-- Clientside Utils
--

-- From: https://codea.io/talk/discussion/3430/has-somebody-an-ellipse-mesh-code
function draw.Ellipses( x, y, radius, width, seg, rotate )
    local offx = 0
	local offy = 0
	local rotate = -math.rad( rotate )
    local verts = {}
	local add = 360 / seg
    for i = 1, seg do
		local i = i * add
        table.insert( verts, { x = x + offx, y = y + offy } )

        angle = math.rad( i-add )
        offx = width*math.cos( angle ) 
        offy = radius*math.sin( angle )
			local newx = offx * math.cos( rotate ) - offy * math.sin( rotate );
			local newy = offx * math.sin( rotate ) + offy * math.cos( rotate );
        table.insert( verts, { x = x + newx, y = y + newy } )

        angle = math.rad( i )
        offx = width*math.cos( angle ) 
        offy = radius*math.sin( angle )
			local newx = offx * math.cos( rotate ) - offy * math.sin( rotate );
			local newy = offx * math.sin( rotate ) + offy * math.cos( rotate );
        table.insert( verts, { x = x + newx, y = y + newy } )

		offx = newx
		offy = newy
    end
	surface.DrawPoly( verts )
end

-- More in shared.lua
function draw.Circle( x, y, radius, seg, rotate )
	local cir = GAMEMODE.GetCirclePoints( x, y, radius, seg, rotate )
	surface.DrawPoly( cir )
end

function draw.EllipsesSegment( x, y, radius, width, seg, thickness, offset, percent, drawlater )
	if ( thickness == 0 ) then
		return draw.Ellipses( x, y, radius, seg )
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
				x = x + math.sin( a ) * ( width - thickness ),
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
				x = x + math.sin( a ) * ( width ),
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
				x = x + math.sin( a ) * ( width ),
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
				x = x + math.sin( a ) * ( width - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 4
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( width ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 2
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( width - thickness ),
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
end

function draw.CircleSegment( x, y, radius, seg, thickness, offset, percent, drawlater )
	return draw.EllipsesSegment( x, y, radius, radius, seg, thickness, offset, percent, drawlater )
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

function GM.AddModel( mdl, pos, ang, floatscale, mat, col, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end
	if ( !col ) then col = COLOUR_WHITE end

	local model = ClientsideModel( mdl, ren )
		model:SetPos( pos )
		model:SetAngles( ang )
		model:SetModelScale( floatscale )
		model:SetMaterial( mat )
		model:SetColor( col )
		model.Pos = pos
		model.Ang = ang
		-- model.RenderBoundsMin, model.RenderBoundsMax = model:GetRenderBounds()
	return model
end

function GM.AddAnim( mdl, anim, pos, ang, floatscale, mat, col, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end
	if ( !col ) then col = COLOUR_WHITE end

	local animprop = ents.CreateClientside( "base_anim" )
		animprop:SetModel( mdl )
		animprop:SetPos( pos )
		animprop:SetAngles( ang )
		animprop:SetModelScale( floatscale )
		animprop:SetMaterial( mat )
		animprop:SetColor( col )
		animprop.MyAnim = anim
		animprop.MyPlaybackRate = 1
		animprop.NextPlay = 0

		animprop.IsPaused = false
	animprop:Spawn()
		animprop:SetSolid( SOLID_NONE )
		animprop:ResetSequence( animprop:LookupSequence( animprop.MyAnim ) )
	animprop:Activate()

	return animprop
end

function GM.RenderScale( ent, vecscale )
	local mat = Matrix()
		mat:Scale( vecscale )
	ent:EnableMatrix( "RenderMultiply", mat )
end
