--
-- Gario Party 13
-- 18/07/20
--
-- Shared Score
--

local HOOK_PREFIX = HOOK_PREFIX .. "Score_"

SCORE_NAME			= "Props"
SCORE_SPACE_ADD		= 3
SCORE_SPACE_REMOVE	= -3
SCORE_WIN			= 5

Score = Score or {}

local meta = FindMetaTable( "Player" )
function meta:GetScore()
	return self:GetNWInt( "OverallScore", 0 )
end
if ( SERVER ) then
	function meta:AddScore( add, novisual )
		if ( !self or !self:IsValid() ) then return end -- Player might leave server

		local old = self:GetScore()
		local score = math.max( 0, old + add )
		local change = score - old
			self:SetNWInt( "OverallScore", score )
			if ( !novisual ) then
				Score:BroadcastChange( self, score ) -- Used to trigger the visual start
				PrintMessage( HUD_PRINTCENTER, self:Nick() .. "| now: " .. score .. " by: " .. change ) -- TODO TEMP
			end
		return change
	end
end

-- Net
local NETSTRING = HOOK_PREFIX .. "Net"
local NET_INT = 11
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	function Score:BroadcastChange( ply, score )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteInt( score, NET_INT )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()
		local score = net.ReadInt( NET_INT )

		-- If visual here, store lastprops before next minigame outro
		ply.LastProps = score

		-- TODO start visual score change
		
	end )
end

-- TODO SCORE PANELS
