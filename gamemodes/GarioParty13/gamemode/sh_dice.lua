--
-- Gario Party 13
-- 02/07/20
--
-- Shared Dice
--

local HOOK_PREFIX = HOOK_PREFIX .. "Dice_"

Dice = Dice or {}

DICE_MODEL = "models/hunter/blocks/cube025x025x025.mdl"
DICE_SCALE = 5

-- Net
local NETSTRING = HOOK_PREFIX .. "Net"
local NETSTRING_RESULT = HOOK_PREFIX .. "Net_Result"
local NETSTRING_RESULT_INT = 5
local NETSTRING_REQUEST = HOOK_PREFIX .. "Net_Request"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_RESULT )
	util.AddNetworkString( NETSTRING_REQUEST )

	function Dice:BroadcastStart( ply )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
		net.Broadcast()
	end

	function Dice:BroadcastResult( ply, result )
		-- Communicate to all clients
		net.Start( NETSTRING_RESULT )
			net.WriteEntity( ply )
			net.WriteInt( result, NETSTRING_RESULT_INT )
		net.Broadcast()
	end

	net.Receive( NETSTRING_REQUEST, function( lngth, ply )
		if ( Dice.Current and ( ply == Dice.Current or Dice.Current:IsBot() ) ) then
			Dice:Hit()
		end
	end )
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()

		Dice:Roll( ply )
	end )

	net.Receive( NETSTRING_RESULT, function( lngth )
		local ply = net.ReadEntity()
		local result = net.ReadInt( NETSTRING_RESULT_INT )

		-- Display the correct result side to all
		Dice.Result = result
		ply.BoardModel.Moves = result

		-- Animate player hitting it
		ply.BoardModel:ResetSequence( "cheer1" )
		ply.BoardModel.NextPlay = CurTime() + 1
		ply.TempDice = nil

		-- Hide soon
		timer.Simple( 1, function()
			Dice.Current = nil
			Turn.State = TURN_MOVE
		end )
	end )

	function Dice:RequestHit()
		-- Communicate to server
		net.Start( NETSTRING_REQUEST )
		net.SendToServer()
	end
end

function Dice:Roll( ply )
	self.Current = ply
	self.Result = nil

	if ( SERVER ) then
		self:BroadcastStart( ply )
	end
end

function Dice:Hit()
	-- TODO, stop rolling
	local result = math.random( 1, 6 )
	self.Result = result

	-- Communicate result to all
	self:BroadcastResult( self.Current, self.Result )

	self.Current = nil
end

if ( CLIENT ) then
	hook.Add( "PreDrawEffects", HOOK_PREFIX .. "_PreDrawEffects", function()
		if ( Dice.Current ) then
			-- Render cube above player's head
			local pos = Dice.Current.BoardModel:GetPos()
				pos = pos + Vector( 0, 0, 120 )
				pos = pos + Vector( 0, 0, 1 ) * math.sin( CurTime() ) * 10
			local ang = Dice.Current.BoardModel:GetAngles()
				ang:RotateAroundAxis( ang:Up(), math.cos( CurTime() ) * 10 )
			GAMEMODE.RenderCachedModel( DICE_MODEL, pos, ang, Vector( 1, 1, 1 ) * DICE_SCALE )

			-- Render front side of cube
			local num = math.random( 1, 6 )
				if ( Dice.Result ) then
					num = Dice.Result
				end
			local pos = pos
				pos = pos + ang:Forward() * 6 * DICE_SCALE
			local ang = ang
				ang:RotateAroundAxis( ang:Up(), 90 )
				ang:RotateAroundAxis( ang:Forward(), 90 )
			cam.Start3D2D( pos, ang, 1 )
				draw.SimpleTextOutlined( num, "DermaLarge", 0, 0, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOUR_BLACK )
			cam.End3D2D()
		end
	end )
end
