--
-- Gario Party 13
-- 30/05/20
--
-- Clientside Model Caching
--

GM.CachedModels = {}

-- Return cached model, create if non-existent
function GM.GetCachedModel( model, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end

	if ( !GAMEMODE.CachedModels[ren] ) then
		GAMEMODE.CachedModels[ren] = {}
	end
	if ( !GAMEMODE.CachedModels[ren][model] ) then
		GAMEMODE.CachedModels[ren][model] = GAMEMODE.AddModel( model, Vector(), Angle(), 1, nil, Color( 255, 255, 255, 255 ), ren )
		GAMEMODE.CachedModels[ren][model]:SetNoDraw( true )
		GAMEMODE.CachedModels[ren][model]:SetRenderMode( RENDERMODE_TRANSALPHA )
	end

	return GAMEMODE.CachedModels[ren][model]
end

function GM.RenderCachedModel( model, pos, ang, sca, mat, col, ren, extra )
	if ( !col ) then
		col = Color( 255, 255, 255, 255 )
	end

	local ent = GAMEMODE.GetCachedModel( model, ren )
	render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		GAMEMODE.RenderScale( ent, sca )
		ent:SetupBones()

		ent:SetMaterial( mat )
		if ( extra ) then
			extra( ent )
		end
		ent:DrawModel()
	render.SetColorModulation( 1, 1, 1 )

	return ent
end

function GM.AddModel( mdl, pos, ang, scale, mat, col, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end

	local model = ClientsideModel( mdl, ren )
		model:SetPos( pos )
		model:SetAngles( ang )
		model:SetModelScale( scale )
		model:SetMaterial( mat )
		model:SetColor( col )
		model.Pos = pos
		model.Ang = ang
		-- model.RenderBoundsMin, model.RenderBoundsMax = model:GetRenderBounds()
	return model
end

function GM.RenderScale( ent, scale )
	local mat = Matrix()
		mat:Scale( scale )
	ent:EnableMatrix( "RenderMultiply", mat )
end
