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

function GM.RenderCachedModel( model, pos, ang, vecsca, mat, col, ren, extra )
	if ( !col ) then
		col = Color( 255, 255, 255, 255 )
	end

	local ent = GAMEMODE.GetCachedModel( model, ren )
	render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		GAMEMODE.RenderScale( ent, vecsca )
		ent:SetupBones()

		ent:SetMaterial( mat )
		if ( extra ) then
			extra( ent )
		end
		ent:DrawModel()
	render.SetColorModulation( 1, 1, 1 )

	return ent
end
