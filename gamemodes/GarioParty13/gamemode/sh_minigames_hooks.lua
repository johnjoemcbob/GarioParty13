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

	hook.Add( "PlayerSwitchFlashlight", HOOK_PREFIX .. "PlayerSwitchFlashlight", function( ply, enabled )
		return false
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
