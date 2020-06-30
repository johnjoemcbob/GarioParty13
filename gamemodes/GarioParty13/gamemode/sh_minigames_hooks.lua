--
-- Gario Party 13
-- 30/06/20
--
-- Shared Minigame Hooks
--

local HOOK_PREFIX = HOOK_PREFIX .. "Minigames_"

hook.Add( "OnPlayerHitGround", HOOK_PREFIX .. "OnPlayerHitGround", function( ply, inWater, onFloater, speed )
	local game = ply:GetGame()
	if ( game and game.OnPlayerHitGround ) then
		game:OnPlayerHitGround( ply, inWater, onFloater, speed )
	end
end )

hook.Add( "PlayerFootstep", HOOK_PREFIX .. "PlayerFootstep", function( ply, pos, foot, sound, volume, rf )
	local game = ply:GetGame()
	if ( game and game.PlayerFootstep ) then
		return game:PlayerFootstep( ply, pos, foot, sound, volume, rf )
	end
end )

if ( SERVER ) then
	hook.Add( "InitPostEntity", HOOK_PREFIX .. "InitPostEntity", function()
		GAMEMODE.IsPostInit = true
	
		for k, game in pairs( GAMEMODE.Games ) do
			if ( game.SetupDataTables ) then
				game:SetupDataTables()
			end
			game:Init()
		end
	end )

	hook.Add( "PlayerSpawn", HOOK_PREFIX .. "PlayerSpawn", function( ply )
		-- Ignore overwrites by Loadout etc
		timer.Simple( 0, function()
			ply:StripWeapons()

			ply:GetGame():PlayerSpawn( ply )
		end )
	end )

	hook.Add( "Think", HOOK_PREFIX .. "Think", function()
		for k, game in pairs( GAMEMODE.Games ) do
			if ( game.Think ) then
				game:Think()
			end
		end
	
		for k, ply in pairs( player.GetAll() ) do
			if ( ply:GetGame() and ply:GetGame().PlayerThink ) then
				ply:GetGame():PlayerThink( ply )
			end
		end
	end )

	hook.Add( "KeyPress", HOOK_PREFIX .. "KeyPress", function( ply, key )
		local game = ply:GetGame()
		if ( game and game.KeyPress ) then
			game:KeyPress( ply, key )
		end
	end )

	hook.Add( "KeyRelease", HOOK_PREFIX .. "KeyRelease", function( ply, key )
		local game = ply:GetGame()
		if ( game and game.KeyRelease ) then
			game:KeyRelease( ply, key )
		end
	end )

	hook.Add( "PlayerButtonDown", HOOK_PREFIX .. "PlayerButtonDown", function( ply, button )
		local game = ply:GetGame()
		if ( game and game.PlayerButtonDown ) then
			game:PlayerButtonDown( ply, button )
		end
	end )

	hook.Add( "GetFallDamage", HOOK_PREFIX .. "GetFallDamage", function( ply, speed )
		local game = ply:GetGame()
		if ( game and game.GetFallDamage ) then
			return game:GetFallDamage( ply, speed )
		end
		return 10
	end )

	hook.Add( "PlayerDeath", HOOK_PREFIX .. "PlayerDeath", function( victim, inflictor, attacker )
		if ( victim:GetGame() and victim:GetGame().PlayerDeath ) then
			victim:GetGame():PlayerDeath( victim, inflictor, attacker )
		end
		if ( attacker:IsValid() and attacker:IsPlayer() and attacker:GetGame() and attacker:GetGame().PlayerGotKill ) then
			attacker:GetGame():PlayerGotKill( victim, inflictor, attacker )
		end
	end )
end

if ( CLIENT ) then
	hook.Add( "Initialize", HOOK_PREFIX .. "Initialize", function()
		for k, game in pairs( GAMEMODE.Games ) do
			if ( game.SetupDataTables ) then
				game:SetupDataTables()
			end
			game:Init()
		end
		GAMEMODE.IsPostInit = true
	end )

	hook.Add( "Think", HOOK_PREFIX .. "Think", function()
		for k, game in pairs( GAMEMODE.Games ) do
			game:Think()
		end

		for k, ply in pairs( player.GetAll() ) do
			if ( ply:GetGame() and ply:GetGame().PlayerThink ) then
				ply:GetGame():PlayerThink( ply )
			end
		end
	end )

	hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
		local game = LocalPlayer():GetGame()
	
		-- Game specific
		if ( game and game.PreHUDPaint ) then
			game:PreHUDPaint()
		end
	
		local midx = ScrW() / 2
		local topy = 8 --ScrH() / 32
		local colour_box = Color( 0, 0, 0, 128 )
		local colour = Color( 255, 255, 255, 255 )
	
		-- Draw a background rect to the text
		local width = 256
		local height = 48
		draw.RoundedBox( 8, midx - width / 2, topy, width, height, colour_box ) -- 0, 0 is Screen top left
	
		-- Draw some text at the top of the screen
		if ( LocalPlayer():GetGame() ) then
			local name = LocalPlayer():GetGameName()
			local author = LocalPlayer():GetGame().Author
			draw.SimpleText( name, "DermaLarge", midx, topy, LocalPlayer():GetGame().Colour, TEXT_ALIGN_CENTER )
			draw.SimpleText( "by " .. author, "DermaDefault", midx, topy + 32, colour, TEXT_ALIGN_CENTER )
		end
	
		-- Instructions
		if ( game and game.Instructions and game.Instructions != "" ) then
			-- local x = ScrW()
			local x = 0
			local y = 0
			local txt = game.Instructions
			local font = "DermaDefault"
			local border = 12
			local lineheight = 16
	
			-- Get size
			surface.SetFont( font )
			local width, height = surface.GetTextSize( txt )
				width = width + border
				height = height + border
	
			-- Draw a background rect to the text
			draw.RoundedBox( 2, x - width, y, width, height, colour_box ) -- 0, 0 is Screen top left
			draw.RoundedBox( 2, x - 0, y, width, height, colour_box ) -- 0, 0 is Screen top left
	
			-- Draw some text at the top of the screen
			surface.SetTextColor( 255, 255, 255 )
			local txts = string.Split( txt, '\n' )
			for k, txt in pairs( txts ) do
				surface.SetTextPos( x - width + border / 2, y + border / 4 ) 
				surface.SetTextPos( x - 0 + border / 2, y + border / 4 ) 
				surface.DrawText( txt )
				y = y + lineheight
			end
		end
	
		-- Game specific
		if ( game and game.HUDPaint ) then
			game:HUDPaint()
		end
	end )

	hook.Add( "PreRender", HOOK_PREFIX .. "PreRender", function()
		local game = LocalPlayer():GetGame()
		if ( game and game.PreRender ) then
			return game:PreRender()
		end
	end )

	hook.Add( "PreDrawOpaqueRenderables", HOOK_PREFIX .. "PreDrawOpaqueRenderables", function()
		local game = LocalPlayer():GetGame()
		if ( game and game.PreDrawOpaqueRenderables ) then
			return game:PreDrawOpaqueRenderables()
		end
	end )

	hook.Add( "PostDrawOpaqueRenderables", HOOK_PREFIX .. "PostDrawOpaqueRenderables", function()
		local game = LocalPlayer():GetGame()
		if ( game and game.PostDrawOpaqueRenderables ) then
			return game:PostDrawOpaqueRenderables()
		end
	end )

	hook.Add( "PrePlayerDraw", HOOK_PREFIX .. "PrePlayerDraw", function( ply )
		local game = ply:GetGame()
		if ( game and game.PrePlayerDraw ) then
			return game:PrePlayerDraw( ply )
		end
	end )

	hook.Add( "PreDrawSkyBox", HOOK_PREFIX .. "PreDrawSkyBox", function()
		local game = LocalPlayer():GetGame()
		if ( game and game.PreDrawSkyBox ) then
			return game:PreDrawSkyBox()
		end
	end )

	hook.Add( "PostDrawSkyBox", HOOK_PREFIX .. "PostDrawSkyBox", function()
		local game = LocalPlayer():GetGame()
		if ( game and game.PostDrawSkyBox ) then
			return game:PostDrawSkyBox()
		end
	end )

	hook.Add( "PostPlayerDraw", HOOK_PREFIX .. "PostPlayerDraw", function( ply )
		local game = ply:GetGame()
		if ( game and game.PostPlayerDraw ) then
			game:PostPlayerDraw( ply )
		end
	
		-- Hide labels option in games
		if ( LocalPlayer():GetGame() and LocalPlayer():GetGame().HideLabels == true ) then return end
	
		if ( !IsValid( ply ) ) then return end 
		if ( ply == LocalPlayer() ) then return end -- Don't draw a name when the player is you
		if ( !ply:Alive() ) then return end -- Check if the player is alive
		if ( ply:GetGame() == nil ) then return end
	 
		local Distance = LocalPlayer():GetPos():Distance( ply:GetPos() ) --Get the distance between you and the player
		
		-- if ( Distance < 1000 ) then --If the distance is less than 1000 units, it will draw the name
	 
			local offset = Vector( 0, 0, 75 )
			local ang = LocalPlayer():EyeAngles()
			local pos = ply:GetPos() + offset + ang:Up()
	
			ang:RotateAroundAxis( ang:Forward(), 90 )
			ang:RotateAroundAxis( ang:Right(), 90 )
	
			-- print( 0.025 * Distance )
			local scale = math.min( 0.01 + 0.001 * Distance, 2 )
			local off = Vector( 0, 0, 50 ) * scale
			cam.IgnoreZ( true )
				cam.Start3D2D( pos + off, Angle( 0, ang.y, 90 ), scale )
					local colour = ply:GetGame().Colour
					draw.DrawText( ply:GetName(), "DermaLarge", 2, 2, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
					draw.DrawText( ply:GetGameName(), "DermaLarge", 2, 2 + 24, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
				cam.End3D2D()
			cam.IgnoreZ( false )
		-- end
	end )

	hook.Add( "PostDrawOpaqueRenderables", HOOK_PREFIX .. "PostDrawOpaqueRenderables", function( depth, skybox )
		local game = LocalPlayer():GetGame()
		if ( game and game.PostDrawOpaqueRenderables ) then
			game:PostDrawOpaqueRenderables( depth, skybox )
		end
	end )

	local hide = {
		["CHudHealth"] = true,
		["CHudBattery"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudDamageIndicator"] = true,
	}
	function GM:HUDShouldDraw( name )
		if ( LocalPlayer().GetGame and LocalPlayer():GetGame() and LocalPlayer():GetGame().HideDefaultHUD and hide[ name ] ) then return false end
		if ( LocalPlayer().GetGame and LocalPlayer():GetGame() and LocalPlayer():GetGame().HideDefaultExtras and LocalPlayer():GetGame().HideDefaultExtras[ name ] ) then return false end
	
		return true
	end

	hook.Add( "CalcView", HOOK_PREFIX .. "CalcView", function( ply, pos, angles, fov )
		local game = ply:GetGame()
		if ( game and game.CalcView ) then
			return game:CalcView( ply, pos, angles, fov )
		end
	end )
end
