--
-- Gario Party 13
-- 18/07/20
--
-- Shared Score
--

local HOOK_PREFIX = HOOK_PREFIX .. "Score_"

SCORE_NAME			= "☗"
STARS_NAME			= "★"
SCORE_SPACE_ADD		= 3
SCORE_SPACE_REMOVE	= -3
SCORE_WIN			= 5

Score = Score or {}

local meta = FindMetaTable( "Player" )
function meta:GetScore()
	return self:GetNWInt( "OverallScore", 0 )
end
function meta:GetStars()
	return self:GetNWInt( "Stars", 0 )
end
function meta:GetPlacingScore( stars, score ) -- Can force values for these, for MinigameOutro
	local stars = stars or self:GetStars()
	local score = score or self:GetScore()
	return ( stars + ( score / 100 ) )
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
				--PrintMessage( HUD_PRINTCENTER, self:Nick() .. "| now: " .. score .. " by: " .. change ) -- TODO TEMP
				if ( change != 0 ) then
					if ( change > 0 ) then
						change = "+" .. change
					end
					PrintMessage( HUD_PRINTCENTER, change )
				end
			end
		return change
	end

	function meta:SetStars( stars )
		if ( !self or !self:IsValid() ) then return end -- Player might leave server

		self:SetNWInt( "Stars", stars )
	end
end

function Score:SetStars( stars )
	for ply, stars in pairs( stars ) do
		ply:SetStars( stars )
	end
end

function Score:GetPlacings()
	local placings = {}
		local scores = {}
			for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				scores[v] = v:GetPlacingScore()
			end
		local placing = 1
		for ply, score in SortedPairsByValue( scores, true ) do
			placings[placing] = ply

			placing = placing + 1
			if ( placing > 3 ) then break end
		end
	return placings
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
