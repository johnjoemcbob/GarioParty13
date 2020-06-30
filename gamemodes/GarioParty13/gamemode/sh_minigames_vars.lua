--
-- Gario Party 13
-- 30/06/20
--
-- Shared Minigame Variables
--

local NET_INT_COLOUR_BITS = 9
function SetNetFromVarType( type, varval )
	if ( type == "MODEL" ) then
		net.WriteString( varval )
	elseif ( type == "BOOL" ) then
		net.WriteBool( varval )
	elseif ( type == "NUMBER" ) then
		net.WriteFloat( varval )
	elseif ( type == "VECTOR" ) then
		net.WriteVector( varval )
	elseif ( type == "COLOUR" ) then
		net.WriteInt( varval.r, NET_INT_COLOUR_BITS )
		net.WriteInt( varval.g, NET_INT_COLOUR_BITS )
		net.WriteInt( varval.b, NET_INT_COLOUR_BITS )
		net.WriteInt( varval.a, NET_INT_COLOUR_BITS )
	end
end

function GetNetFromVarType( type )
	if ( type == "MODEL" ) then
		return net.ReadString()
	elseif ( type == "BOOL" ) then
		return net.ReadBool()
	elseif ( type == "NUMBER" ) then
		return net.ReadFloat()
	elseif ( type == "VECTOR" ) then
		return net.ReadVector()
	elseif ( type == "COLOUR" ) then
		return Color( net.ReadInt( NET_INT_COLOUR_BITS ), net.ReadInt( NET_INT_COLOUR_BITS ), net.ReadInt( NET_INT_COLOUR_BITS ), net.ReadInt( NET_INT_COLOUR_BITS ) )
	end
end

if ( SERVER ) then
	util.AddNetworkString( HOOK_PREFIX .. "RequestVariableChange" )
	util.AddNetworkString( HOOK_PREFIX .. "ConfirmVariableChange" )

	net.Receive( HOOK_PREFIX .. "RequestVariableChange", function( lngth, ply )
		local varname = net.ReadString()
			if ( !ply:GetGame() or !ply:GetGame().CustomVariables[varname] ) then return end
		local type = ply:GetGame().CustomVariables[varname].Type
		local varval = GetNetFromVarType( type )

		ConfirmVariableChange( ply:GetGameName(), type, varname, varval )
	end )

	function ConfirmVariableChange( game, type, varname, varval, isloading )
		-- Clamp
		if ( GAMEMODE.Games[game].CustomVariables[varname].Range ) then
			varval = math.Clamp( varval, GAMEMODE.Games[game].CustomVariables[varname].Range[1], GAMEMODE.Games[game].CustomVariables[varname].Range[2] )
		end

		GAMEMODE.Games[game][varname] = varval
		if ( GAMEMODE.Games[game].CustomVariables[varname].ChangeCallback ) then
			GAMEMODE.Games[game].CustomVariables[varname].ChangeCallback( GAMEMODE.Games[game], varval )
		end
		if ( !isloading ) then
			GAMEMODE.Games[game]:SaveConstant( varname )
		end

		net.Start( HOOK_PREFIX .. "ConfirmVariableChange" )
			net.WriteString( game )
			net.WriteString( varname )
			SetNetFromVarType( type, varval )
		net.Broadcast()
	end
end

if ( CLIENT ) then
	local meta_ply = FindMetaTable( "Player" )
	function meta_ply:RequestVariableChange( varname, varval )
		if ( self:GetGame()[varname] == varval ) then return end
		if ( self.RequestVariableChangeCooldown and self.RequestVariableChangeCooldown > CurTime() ) then
			self.RequestVariableChangeCooldown = 0
			return
		end

		-- Clamp
		if ( self:GetGame().CustomVariables[varname].Range ) then
			varval = math.Clamp( varval, self:GetGame().CustomVariables[varname].Range[1], self:GetGame().CustomVariables[varname].Range[2] )
		end

		net.Start( HOOK_PREFIX .. "RequestVariableChange" )
			net.WriteString( varname )
			local type = self:GetGame().CustomVariables[varname].Type
			SetNetFromVarType( type, varval )
		net.SendToServer()

		self.RequestVariableChangeCooldown = 0 -- CurTime() + 1
	end

	net.Receive( HOOK_PREFIX .. "ConfirmVariableChange", function( lngth )
		local game = net.ReadString()
		local varname = net.ReadString()
		local type = GAMEMODE.Games[game].CustomVariables[varname].Type
		local varval = GetNetFromVarType( type )

		GAMEMODE.Games[game][varname] = varval
		if ( GAMEMODE.Games[game].CustomVariables[varname].ChangeCallback ) then
			GAMEMODE.Games[game].CustomVariables[varname].ChangeCallback( GAMEMODE.Games[game], varval )
		end
		if ( GAMEMODE.Games[game].CustomVariables[varname].OnNetChange ) then
			GAMEMODE.Games[game].CustomVariables[varname].OnNetChange( GAMEMODE.Games[game], varval )
		end
		LocalPlayer().RequestVariableChangeCooldown = CurTime() + 0.1
	end )
end
