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

local SOUND_DICE_HIT = "garrysmod/balloon_pop_cute.wav"

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

		if ( result == -1 ) then
			-- Flag to simply hide the dice
			Dice.Result = -1
			Dice.Current = nil
			return
		end

		-- Display the correct result side to all
		Dice.Result = result
		ply.BoardModel.Moves = result

		-- Animate player hitting it
		ply.BoardModel:ResetSequence( "jump_magic" )
		ply.BoardModel.NextPlay = CurTime() + 0.3
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

function Dice:Hit( overwrite )
	local ply = self.Current

	-- Stop rolling
	local result = overwrite or math.random( 1, 6 )
	self.Result = result

	-- Communicate result to all
	self:BroadcastResult( self.Current, self.Result )

	self.Current = nil

	if ( !overwrite or overwrite != -1 ) then
		-- Play hit sound
		timer.Simple( 0.3, function()
			-- TODO NOT GREAT
			for k, v in pairs( player.GetAll() ) do
				v:EmitSound( SOUND_DICE_HIT )
			end
		end )

		-- End dice phase
		timer.Simple( 1, function()
			Turn.State = TURN_MOVE
		end )
	end
end

function Dice:Hide()
	if ( self.Current ) then
		self:BroadcastResult( self.Current, -1 )

		self.Current = nil
	end
end

hook.Add( "KeyPress", HOOK_PREFIX .. "KeyPress", function( ply, key )
	-- Hit dice input
	if ( SERVER ) then
		if ( ply == Turn.Current and ( key == IN_JUMP or key == IN_USE ) ) then
			if ( Dice.Current ) then
				Dice:Hit()
			end
		end
	end
end )

if ( CLIENT ) then
	hook.Add( "PreDrawEffects", HOOK_PREFIX .. "PreDrawEffects", function()
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
