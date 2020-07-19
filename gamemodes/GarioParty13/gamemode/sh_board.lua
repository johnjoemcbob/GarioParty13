--
-- Gario Party 13
-- 30/06/20
--
-- Shared Board
--

local HOOK_PREFIX = HOOK_PREFIX .. "Board_"

GP13_BOARD_SCALE		= 100
GP13_BOARD_POS			= Vector( 0, 0, 0 )
GP13_BOARD_SPACE_MODEL	= "models/hunter/misc/roundthing2.mdl"
GP13_BOARD_SPACE_LINE	= "models/hunter/blocks/cube025x05x025.mdl"

BOARD_MOVETIME 	= 0.2
local LERPSPEED_ANGLE = 5

local SOUND_BOARD_MOVE	= {
	"player/footsteps/duct1.wav",
	"player/footsteps/duct2.wav",
	"player/footsteps/duct3.wav",
	"player/footsteps/duct4.wav",
}

SPACE_TYPE_DEFAULT	= 0
SPACE_TYPE_NEGATIVE	= 1

Board = Board or {}
local LastSpaceAdded = nil
local spaces = 0
local function setupboard()
	Board.Data = {}
	Board:AddSpace( 0, 0, SPACE_TYPE_DEFAULT )
	Board:AddSpaceFromLast( 1, 1, SPACE_TYPE_DEFAULT )
		Board:AddSpaceFromLast( 1, 1, SPACE_TYPE_NEGATIVE )
		Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT )
		Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT )
		Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_NEGATIVE )
		-- First corner
		local path = Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT,
			{ Vector( 1, 0 ), Vector( 0, 1 ) } )
		Board:StartDownPath( path )
			Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT )
			Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT )
			Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_NEGATIVE )
			Board:AddSpaceFromLast( 1, 0, SPACE_TYPE_DEFAULT )
			-- Left of map
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_NEGATIVE )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
			local path_left = Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT,
				{ Vector( 0, 1 ), Vector( -1, 0 ) } )
			-- Left of map
			Board:StartDownPath( path_left )
				Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_NEGATIVE )
				Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_NEGATIVE )
					-- Row 3
					Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
					Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
					Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_NEGATIVE )
					Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
					-- Back to Row 2
					Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
					Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_NEGATIVE )
					Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
					Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
			-- Row 2
			Board:StartDownPath( path_left )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_NEGATIVE )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_NEGATIVE )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_NEGATIVE )
				Board:AddSpaceFromLast( -1, 0, SPACE_TYPE_DEFAULT )
				-- Back to start
				Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_NEGATIVE )
				Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
				Board:AddSpaceFromLast( 0, -1, SPACE_TYPE_DEFAULT )
		Board:StartDownPath( path )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_NEGATIVE )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_DEFAULT )
			Board:AddSpaceFromLast( 0, 1, SPACE_TYPE_NEGATIVE )
 
	-- PrintTable( Board.Data )
	-- print( spaces )
end

function Board:StartDownPath( pos )
	LastSpaceAdded = pos
end

function Board:AddSpaceFromLast( x, y, type, connections )
	if ( connections ) then
		for k, con in pairs( connections ) do
			connections[k] = con + LastSpaceAdded + Vector( x, y )
		end
	end

	local current = LastSpaceAdded + Vector( x, y )
	table.Add( Board.Data[LastSpaceAdded.x][LastSpaceAdded.y].Connections, { current } )

	self:AddSpace( current.x, current.y, type, connections )

	return LastSpaceAdded
end

-- Connections are one way by default
function Board:AddSpace( x, y, type, connections )
	if ( !connections ) then
		connections = {}
	end

	Board.Data = Board.Data or {}
	Board.Data[x] = Board.Data[x] or {}
	if ( !Board.Data[x][y] ) then
		Board.Data[x][y] = {}
		Board.Data[x][y].Type = type
		Board.Data[x][y].Connections = connections
		spaces = spaces + 1
	else
		table.Add( Board.Data[x][y].Connections, connections )
	end

	Board.Data[x][y].CurrentPlayers = {}
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			if ( ply:GetNWVector( "BoardPos", Vector( 1, 1 ) ) == Vector( x, y ) ) then
				table.insert( Board.Data[x][y].CurrentPlayers, ply )
			end
		end

	LastSpaceAdded = Vector( x, y )
end

function Board:GetSpace( vec )
	return Board.Data[vec.x][vec.y]
end

local layouts = {
	[1] = {
		{ Vector( 0, 0 ) },
	},
	[4] = {
		{ Vector( -1, -1 ) },
		{ Vector( 1, -1 ) },
		{ Vector( -1, 1 ) },
		{ Vector( 1, 1 ) },
	},
	[9] = {
		{ Vector( 0, 0 ) },
		{ Vector( 1, 0 ) },
		{ Vector( 0, -1 ) },
		{ Vector( 0, 1 ) },
		{ Vector( -1, -1 ) },
		{ Vector( 1, -1 ) },
		{ Vector( -1, 1 ) },
		{ Vector( 1, 1 ) },
		{ Vector( -1, 0 ) },
	},
}

-- Net
local NETSTRING = HOOK_PREFIX .. "Net"
local NET_INT = 5
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	function Board:BroadcastMove( ply, pos, remaining )
		ply:SetNWVector( "BoardPos", pos )
		self.MoveStart = CurTime()

		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteVector( pos )
			net.WriteInt( remaining, NET_INT )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()
		local pos = net.ReadVector()
		local remaining = net.ReadInt( NET_INT )

		Dice.Current = nil
		Turn.State = TURN_MOVE
		Board:Move( ply, pos )
		Board.Moves = remaining
	end )
end

if ( CLIENT ) then
	hook.Add( "Tick", HOOK_PREFIX .. "Tick", function()
		if ( GAMEMODE:GetStateName() == STATE_BOARD ) then
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				-- Create player avatar
				if ( !ply.BoardModel or !ply.BoardModel:IsValid() ) then
					local pos = GP13_BOARD_POS
					local ang = Angle( 0, 0, 0 )
					ply.BoardModel = GAMEMODE.AddAnim( ply:GetModel(), "run_all_01", pos, ang, 1 )
				end

				-- Target position and angle
				local pos, ang

				-- Move
				if ( ply.BoardFromPos != ply.BoardTargetPos ) then
					-- Time progress
					local progress = math.Clamp( ( CurTime() - Board.MoveStart ) / BOARD_MOVETIME, 0, 1 )
					if ( progress == 1 ) then
						ply.BoardFromPos = ply.BoardTargetPos
						LocalPlayer():EmitSound( SOUND_BOARD_MOVE[math.random( 1, #SOUND_BOARD_MOVE )] )
						
					end

					pos = ply.BoardFromExact
					local targetpos = Board:GetTargetPos( ply )
					pos = LerpVector( progress, pos, targetpos )
					local target  = ( targetpos - pos ):Angle()
						target.p = 0
						target.r = 0
					ply.BoardModel.Angle = ply.BoardModel.Angle or target
					ply.BoardModel.Angle = LerpAngle( FrameTime() * LERPSPEED_ANGLE, ply.BoardModel.Angle, target )
					ang = ply.BoardModel.Angle

					-- Loop run animation
					if ( ply.BoardModel.NextPlay <= CurTime() ) then
						ply.BoardModel:ResetSequence( "swimming_all" )
						--ply.BoardModel:ResetSequence( "walk_suitcase" )
						--ply.BoardModel:ResetSequence( "sit" )
						ply.BoardModel.Delay = ply.BoardModel:SequenceDuration()
						ply.BoardModel.NextPlay = CurTime() + ply.BoardModel.Delay
					end

					-- Sounds
					-- ply.BoardModel.NextAudio = ply.BoardModel.NextAudio or 0
					-- if ( ply.BoardModel.NextAudio <= CurTime() ) then
					-- 	LocalPlayer():EmitSound( SOUND_BOARD_MOVE[math.random( 1, #SOUND_BOARD_MOVE )] )
					-- 	ply.BoardModel.NextAudio = CurTime() + 0.4
					-- end
				else
					if ( ply.BoardModel.NextPlay <= CurTime() ) then
						-- Loop idle animation
						ply.BoardModel:ResetSequence( "idle_all_01" )
						--ply.BoardModel:ResetSequence( "man_gun" )
						ply.BoardModel.Delay = ply.BoardModel:SequenceDuration()
						ply.BoardModel.NextPlay = CurTime() + ply.BoardModel.Delay
					end

					-- Still lerp in case needs to get out of way of moving player
					pos = ply.BoardModel:GetPos()
					local targetpos = Board:GetTargetPos( ply )
					pos = LerpVector( FrameTime() * 5, pos, targetpos )

					-- Face camera
					ang = Angle( 0, 180, 0 )
				end

				-- Update transform
				ply.BoardModel:SetPos( pos )
				ply.BoardModel:SetAngles( ang )

				-- Animate
				--ply.BoardModel:SetCycle( math.sin( CurTime() * 10 ) + 1 )
				ply.BoardModel:FrameAdvance()
				--ply.BoardModel:SetAutomaticFrameAdvance( true )
			end
		end
	end )

	function Board:GetTargetPos( ply )
		if ( !ply.BoardTargetPos ) then
			--ply.BoardTargetPos = Vector( 1, 1 )
			Board:Move( ply, Vector( 1, 1 ) )
		end

		local target = ply.BoardTargetPos
			local count = #self.Data[target.x][target.y].CurrentPlayers
			local index = table.indexOf( self.Data[target.x][target.y].CurrentPlayers, ply )
		local offset = Vector( 0, 0 )
			if ( index != -1 ) then
				local layout
					-- Find closest layout
					local min = -1
					for int, lay in pairs( layouts ) do
						if ( count <= int and ( min == -1 or int < min ) ) then
							min = int
						end
					end
					if ( min == -1 ) then
						min = 1
					end
					layout = layouts[min]
				offset = layout[index][1]
			end
		return ( GP13_BOARD_POS + Vector( target.y, target.x ) * GP13_BOARD_SCALE + offset * 32 )
	end

	function Board:Move( ply, pos )
		-- Unregister from old space
		if ( ply.BoardTargetPos ) then
			table.RemoveByValue( self.Data[ply.BoardTargetPos.x][ply.BoardTargetPos.y].CurrentPlayers, ply )
		end

		-- Start move
		self.MoveStart = CurTime()
		ply.BoardFromPos = ply.BoardTargetPos or Vector( 1, 1 )
		ply.BoardFromExact = ply.BoardModel:GetPos()
		ply.BoardTargetPos = pos
		ply.BoardModel.NextPlay = 0

		-- Register to new space
		table.insert( self.Data[ply.BoardTargetPos.x][ply.BoardTargetPos.y].CurrentPlayers, ply )
	end

	function Board:Render()
		-- Note: Board scene is rendered from sh_gs_board.lua state
		render.SetLightingMode( 2 )
			-- Board spaces
			for x, ys in pairs( Board.Data ) do
				for y, space in pairs( ys ) do
					local pos = GP13_BOARD_POS + Vector( y, x ) * GP13_BOARD_SCALE
					local ang = Angle( 0, 0, 0 )
					local sca = Vector( 1, 0.4, 0.1 )
					local mat = "models/debug/debugwhite"
					local col = COLOUR_POSITIVE
						if ( space.Type == SPACE_TYPE_NEGATIVE ) then
							col = COLOUR_NEGATIVE
						end

					for k, conn in pairs( space.Connections ) do
						local endpos = GP13_BOARD_POS + Vector( conn.y, conn.x ) * GP13_BOARD_SCALE
						--render.DrawLine( pos, endpos, Color( 255, 255, 0, 255 ) )
						local length = pos:Distance( endpos ) / GP13_BOARD_SCALE * 2.5
						local mid = ( endpos - pos ) / 2
							mid.z = 0
						local ang = mid:Angle() + Angle( 0, 90, 0 )
							mid = mid + ang:Forward() * 6
						local sca = Vector( 1, length, 0.1 )
						GAMEMODE.RenderCachedModel(
							GP13_BOARD_SPACE_LINE,
							pos + mid, ang, sca,
							mat, GAMEMODE.ColourPalette[5]
						)
					end

					GAMEMODE.RenderCachedModel(
						GP13_BOARD_SPACE_MODEL,
						pos, ang, sca,
						mat, col
					)
				end
			end

			-- Player models
			for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				if ( ply.BoardModel ) then
					ply.BoardModel:DrawModel()
					
					-- Draw remaining moves
					if ( Turn.Current == ply and Board.Moves and Board.Moves > 0 ) then
						local num = Board.Moves
						local ang = Angle( 0, -90, 90 )
						local pos = ply.BoardModel:GetPos() + Vector( 0, 0, 50 )
							pos = pos + Vector( 0, 0, 120 )
							pos = pos + Vector( 0, 0, 1 ) * math.sin( CurTime() ) * 10
							--pos = pos + ang:Forward() * 6 * DICE_SCALE
						local ang = ang
							--ang:RotateAroundAxis( ang:Up(), 90 )
							--ang:RotateAroundAxis( ang:Forward(), 90 )
						cam.Start3D2D( pos, ang, 1 )
							draw.SimpleTextOutlined( num, "DermaLarge", 0, 0, COLOUR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOUR_BLACK )
						cam.End3D2D()
					end
				end
			end

			render.SetLightingMode( 0 )
		render.SetLightingMode( 0 )
	end
end

setupboard()
