--
-- Gario Party 13
-- 28/06/20
--
-- Shared Player States
--

PlayerStates = PlayerStates or {}

STATE_ERROR = "ERROR"

-- Load all states, add to download (called at bottom)
function includeanddownload()
	local dir = "player_states/"
	local files = {
		"sh_ps_joined",
		"sh_ps_spectate",
		"sh_ps_play",
	}
	for k, file in pairs( files ) do
		local path = dir .. file .. ".lua"
		if ( SERVER ) then
			AddCSLuaFile( path )
		end
		include( path )
	end
end

-- Define add state function
function AddPlayerState( name, data )
	PlayerStates[name] = data
end

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_PlayerState"
local NETSTRING_REQUEST = HOOK_PREFIX .. "Net_PlayerState_Request"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_REQUEST )

	function BroadcastPlayerState( ply, oldstate, newstate )
		-- Communicate to client
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteString( oldstate )
			net.WriteString( newstate )
		net.Broadcast()
	end
	
	net.Receive( NETSTRING_REQUEST, function( lngth, ply )
		local state = net.ReadString()

		ply:SwitchState( state )
	end )
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()
		local oldstate = net.ReadString()
		local newstate = net.ReadString()

		-- Start/Finish clientside
		if ( oldstate != STATE_ERROR ) then
			PlayerStates[oldstate]:OnFinish( ply )
		end
		PlayerStates[newstate]:OnStart( ply )
	end )

	function RequestSwitchPlayerState( state )
		-- Communicate to client
		net.Start( NETSTRING_REQUEST )
			net.WriteString( state )
		net.SendToServer()
	end
end

function PlayerStates:GetPlayers( state )
	local tab = PlayerStates.CachedPlayers or {}
		if ( !tab[state] ) then
			tab[state] = {}
			for k, v in pairs( player.GetAll() ) do
				if ( v:GetStateName() == state ) then
					table.insert( tab[state], v )
				end
			end
		end
	return tab[state]
end

-- Player meta functions
local meta = FindMetaTable( "Player" )
if ( SERVER ) then
	-- First, Initial state setup
	function meta:SetState( state )
		self:SetNWString( "PlayerState", state )
	end
	-- Start and finish properly
	function meta:SwitchState( state, nofade )
		if ( self:GetStateName() == state ) then return end

		local oldstate = self:GetStateName()
		if ( oldstate != STATE_ERROR ) then
			self:GetState():OnFinish( self )
		end
		self:SetState( state )
		self:GetState():OnStart( self )

		if ( !nofade ) then
			self:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0, 255 ), 1, 0 )
		end

		-- Send to clients too
		BroadcastPlayerState( self, oldstate, state )
	end
end
if ( CLIENT ) then
	function meta:SwitchState( state )
		RequestSwitchPlayerState( state )
	end
end
function meta:GetState()
	return PlayerStates[self:GetStateName()]
end
function meta:GetStateName()
	return self:GetNWString( "PlayerState", STATE_ERROR )
end
function meta:HideFPSController()
	if ( !self.LastFPSController ) then
		self.LastFPSController = {
			self:GetPos(),
			self:EyeAngles()
		}
		if ( SERVER ) then
			self:ExitVehicle()
			self:SetPos( Vector( 947, -630, -144 ) )
			self:Lock()
		end
	end
end
function meta:ShowFPSController()
	if ( self.LastFPSController ) then
		if ( SERVER ) then
			self:UnLock()
		end
		self:SetPos( self.LastFPSController[1] )
		self:SetEyeAngles( self.LastFPSController[2] )
		self.LastFPSController = nil
	end
end

-- Gamemode hooks
hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerStates_PlayerInitialSpawn", function( ply )
	ply:SetState( STATE_ERROR )
	ply:SwitchState( PLAYER_STATE_JOINED )
end )

hook.Add( "Think", HOOK_PREFIX .. "PlayerStates_Think", function()
	PlayerStates.CachedPlayers = nil

	for k, ply in pairs( player.GetAll() ) do
		if ( ply:GetStateName() != STATE_ERROR ) then
			ply:GetState():OnThink( ply )
		end
	end
end )

-- Show current state on HUD
-- if ( CLIENT ) then
-- 	hook.Add( "HUDPaint", HOOK_PREFIX .. "PlayerStates_HUDPaint", function()
-- 		draw.SimpleText( LocalPlayer():GetStateName(), "DermaDefault", ScrW() - 80, 150, COLOUR_WHITE )
-- 	end )
-- end

-- Last, after necessary functions are defined
includeanddownload()
