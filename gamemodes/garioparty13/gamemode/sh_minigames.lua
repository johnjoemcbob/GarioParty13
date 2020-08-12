--
-- Gario Party 13
-- 30/06/20
--
-- Shared Minigames
--

GM.Games = {}
GM.GamesToLoad = {}

local HOOK_PREFIX = HOOK_PREFIX .. "Minigame_"

-- Load all states, add to download (called at bottom)
function includeanddownload()
	local dir = "minigames/"
	local files = {
		"default",
		"sh_mg_boats",
		"sh_mg_flyhigh",
		"sh_mg_scary",
		"sh_mg_screencheat",
		"sh_mg_goose",
		"sh_mg_donut",
		"sh_mg_teeth",
		"sh_mg_rooftoprampage",
		"sh_mg_timetravel",
		"sh_mg_skyview",
	}
	for k, file in pairs( files ) do
		local path = dir .. file .. ".lua"
		if ( SERVER ) then
			AddCSLuaFile( path )
		end
		include( path )
	end
end

function GM.AddGame( name, base, data )
	if ( !GM.Games ) then GM.Games = {} end

	-- Add name to all games
	data.Name = name

	-- Find base
	--print( name )
	GM.Games[name] = {}
		-- Base item
		-- print( "base; " .. base )
		if ( base and base != "" ) then
			-- print( GAMEMODE.Games[base] )
			if ( !GM.Games[base] ) then
				print( "hasn't loaded base: " .. base .. " yet... waiting..." )
				table.insert( GM.GamesToLoad, { name, base, data } )
				return false
			end
			GM.Games[name] = table.shallowcopy( GM.Games[name] )
			data.base = GM.Games[base]

			-- Pass unique down to inherit table
			for key, value in pairs( data.base ) do
				if ( data[key] == nil ) then
					-- print( key .. " " .. tostring( data[key] ) )
					data[key] = value
				end
			end
		end
	table.Merge( GM.Games[name], data )
	-- PrintTable( GAMEMODE.Games[name] )

	-- Initialize
	GM.Games[name].Players = {}
	if ( GM.IsPostInit or ( GAMEMODE and GAMEMODE.IsPostInit ) ) then
		if ( GM.Games[name].SetupDataTables ) then
			GM.Games[name]:SetupDataTables()
		end
		GM.Games[name]:Init()
	end

	return true
end

local meta_ply = FindMetaTable( "Player" )
function meta_ply:SetGame( game )
	-- if ( game != "Default" ) then
	-- 	if ( !GAMEMODE.GamesInited ) then
	-- 		-- Try a late init AGAIN
	-- 		for k, igame in pairs( GAMEMODE.Games ) do
	-- 			if ( igame.SetupDataTables ) then
	-- 				igame:SetupDataTables()
	-- 			end
	-- 			igame:Init()
	-- 		end
	-- 		GAMEMODE.GamesInited = true
	-- 	end
	-- end

	-- Leave old
	local old = self:GetGame()
	if ( old != nil ) then
		old:PlayerLeave( self )
		self:ResetOnLeaveGame()
		old.Players[self] = nil
	end

	-- Update var
	self:SetNWString( HOOK_PREFIX .. "Game", game )
	--self.CurrentMinigame = game
	if ( SERVER ) then
		ConfirmGameChange( self, game )
	end

	-- Join new
	if ( self:GetGame() ) then
		if ( !self:GetGame().CustomVariables or #self:GetGame().CustomVariables == 0 ) then
			if ( self:GetGame().SetupDataTables ) then
				self:GetGame():SetupDataTables()
			end
		end

		self:GetGame().Won = false
		self:GetGame().Players[self] = true
		self:StoreOnJoinGame()
		self:GetGame():PlayerJoin( self )
		if ( !self:Alive() ) then
			-- Ensure the player is alive before starting the minigame!
			self:Spawn()
		end
		self:GetGame():PlayerSpawn( self )
		-- timer.Simple( 0.5, function()
		-- 	-- TODO TEMP
		-- 	-- Trying to fix sometimes not spawning into first minigame properly,
		-- 	-- Just retry a bit later :)
		-- 	self:GetGame():PlayerSpawn( self )
		-- end )
		self.WonLastGame = false
		self:SetNWInt( "Score", 0 )
	end
end

function meta_ply:GetGame()
	local name = self:GetGameName()
		if ( name == nil ) then
			return nil
		end
	return GAMEMODE.Games[name]
end

function meta_ply:GetGameName()
	local game = self:GetNWString( HOOK_PREFIX .. "Game", "" )
	--local game = self.CurrentMinigame
		if ( game == "" ) then
			game = nil
		end
	return game
end

function meta_ply:ResetOnLeaveGame()
	if ( SERVER ) then
		-- Not the best check, but the first game joined fills these with garbage values so lets check for that and ignore
		if ( self.OldModel == "models/player.mdl" ) then return end

		self:SetWalkSpeed( self.OldWalkSpeed )
		self:SetRunSpeed( self.OldRunSpeed )
		self:SetJumpPower( self.OldJumpPower )
		self:SetGravity( self.OldGravity )
		self:SetFOV( self.OldFOV )
		self:SetModel( self.OldModel )
		self:SetMaterial( nil )
		self:SetColor( self.OldColour )
		self:SetModelScale( 1 )
		self:ResetHull()
		self:SetHealth( self:GetMaxHealth() )
		self:StripWeapons()
	end
end

function meta_ply:StoreOnJoinGame()
	if ( SERVER ) then
		self.OldWalkSpeed = self:GetWalkSpeed()
		self.OldRunSpeed = self:GetRunSpeed()
		self.OldJumpPower = self:GetJumpPower()
		self.OldGravity = self:GetGravity()
		self.OldModel = self:GetModel()
		self.OldColour = self:GetColor()
		self.OldFOV = self:GetFOV()
	end
end

function meta_ply:HideFPSController()
	if ( !self.LastFPSController ) then
		self.LastFPSController = {
			self:GetPos(),
			self:EyeAngles()
		}
		if ( SERVER ) then
			self:ExitVehicle()
			self:SetPos( Vector( 947, -630, -144 ) )
			self:SetMoveType( MOVETYPE_NONE )
		end
	end
end
function meta_ply:ShowFPSController()
	if ( self.LastFPSController ) then
		if ( SERVER ) then
			self:SetMoveType( MOVETYPE_WALK )
			if ( self:GetStateName() == PLAYER_STATE_PLAY ) then
				self:UnSpectate()
			end
		end
		self:SetPos( self.LastFPSController[1] )
		self:SetEyeAngles( self.LastFPSController[2] )
		self.LastFPSController = nil
	end
end

local NETSTRING_REQUESTALL = HOOK_PREFIX .. "RequestGameChangeAll"
if ( SERVER ) then
	util.AddNetworkString( HOOK_PREFIX .. "RequestGameChange" )
	util.AddNetworkString( HOOK_PREFIX .. "ConfirmGameChange" )
	util.AddNetworkString( NETSTRING_REQUESTALL )

	net.Receive( HOOK_PREFIX .. "RequestGameChange", function( lngth, ply )
		local gamename = net.ReadString()

		ply:SetGame( gamename )
	end )

	net.Receive( NETSTRING_REQUESTALL, function( lngth, ply )
		local gamename = net.ReadString()

		-- Add all players to play state
		for k, v in pairs( player.GetAll() ) do
			v:SwitchState( PLAYER_STATE_PLAY )
		end

		-- Start minigame
		GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame = gamename
		GAMEMODE:SwitchState( STATE_MINIGAME_INTRO )
	end )

	function ConfirmGameChange( ply, togame )
		net.Start( HOOK_PREFIX .. "ConfirmGameChange" )
			net.WriteEntity( ply )
			net.WriteString( togame )
		net.Broadcast()
	end

	function meta_ply:TrySpawn( point )
		local valid = true
			for k, ent in pairs( ents.FindInSphere( point, 20 ) ) do
				if ( ent:IsPlayer() ) then
					valid = false
					break
				end
			end
		if ( valid ) then
			self:SetPos( point )
		end
		return valid
	end

	concommand.Add( "gp_drag", function( ply, cmd, args )
		if ( ply:IsAdmin() ) then
			for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				v:UnSpectate()
				v:SetGame( ply:GetGameName() )
			end
		end
	end )

	hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerInitialSpawn", function( ply )
		ply:SetGame( "Default" )
	end )
	hook.Add( "PlayerDisconnected", HOOK_PREFIX .. "PlayerDisconnected", function( ply )
		ply:SetGame( "Default" )
	end )
end

if ( CLIENT ) then
	function meta_ply:RequestGameChange( togame )
		net.Start( HOOK_PREFIX .. "RequestGameChange" )
			net.WriteString( togame )
		net.SendToServer()
	end

	function GM.RequestMinigameChangeAll( togame )
		GAMEMODE.GameStates[STATE_MINIGAME].Minigame = togame

		net.Start( NETSTRING_REQUESTALL )
			net.WriteString( togame )
		net.SendToServer()
	end

	net.Receive( HOOK_PREFIX .. "ConfirmGameChange", function( lngth )
		local ply = net.ReadEntity()
		local gamename = net.ReadString()

		-- Initial server start fix
		if ( ply == nil or !ply:IsValid() ) then
			-- Wait for server on first load/join
			timer.Simple( 3, function()
				if ( ply.SetGame ) then
					ply:SetGame( gamename )
				end
			end )
		else
			ply:SetGame( gamename )
		end
	end )
end

-- Last, after necessary functions are defined
includeanddownload()
