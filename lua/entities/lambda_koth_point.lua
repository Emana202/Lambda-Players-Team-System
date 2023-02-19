AddCSLuaFile()

ENT.Base = "base_anim"
ENT.IsLambdaKOTH = true

local vec_white = Vector( 1, 1, 1 )

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "IsCaptured" )

    self:NetworkVar( "String", 0, "PointName" )
    self:NetworkVar( "String", 1, "CapturerName" )
	self:NetworkVar( "String", 2, "ContesterTeam" )

    self:NetworkVar( "Vector", 0, "CapturerColor" )
    self:NetworkVar( "Vector", 1, "ContesterColor" )
    
    self:NetworkVar( "Float", 0, "CapturePercent" )
end

if ( SERVER ) then

	local random = math.random
	local IsValid = IsValid
	local color_glacier = Color( 130, 164, 192 )
	local ipairs = ipairs
	local FindInSphere = ents.FindInSphere
	local ignorePlys = GetConVar( "ai_ignoreplayers" )
	local Clamp = math.Clamp
	local Round = math.Round
	local Rand = math.Rand
	local net = net
	local keynames = { "A", "B", "C", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
	
	local captureRate = GetConVar( "lambdaplayers_teamsystem_koth_capturerate" )
	local captureRange = GetConVar( "lambdaplayers_teamsystem_koth_capturerange" )

	function ENT:Initialize()
	    self:SetModel( "models/props_combine/CombineThumper002.mdl" )
	    self:SetModelScale( 0.3 )
	    
	    self.OldColor = vec_white
        self:SetPointName( self.CustomName or keynames[ random( #keynames ) ] .. self:GetCreationID() )

	    local startTeam = self.SpawnTeam
	    if startTeam then
	    	self:SetIsCaptured( true )
		    self:SetCapturerName( startTeam )
		   	self:SetCapturePercent( 100 )
			self:SetCapturerColor( LambdaTeams:GetTeamColor( startTeam ) )
		else
	    	self:SetIsCaptured( false )
		    self:SetCapturerName( "Neutral" )
		   	self:SetCapturePercent( 0 )
			self:SetCapturerColor( vec_white )
		end
	end

	function ENT:GetCapturerTeamName( ent )
		return ( LambdaTeams:GetPlayerTeam( ent ) or ent:Nick() )
	end

	function ENT:GetCapturerTeamColor( ent )
		local color = LambdaTeams:GetTeamColor( self:GetCapturerTeamName( ent ) )
		if !color then 
			if ent:IsPlayer() then
				local plyClr = string.Explode( " ", ent:GetInfo( "cl_playercolor" ) )
				return Vector( plyClr[ 1 ], plyClr[ 2 ], plyClr[ 3 ] )
			end
			return ( ent:GetPlyColor() )
		end
		return color
	end

	function ENT:IsContested()
		local curTeam = nil
		for _, ent in ipairs( FindInSphere( self:GetPos(), captureRange:GetInt() ) ) do
			if LambdaIsValid( ent ) and ( ent.IsLambdaPlayer or ent:IsPlayer() and !ignorePlys:GetBool() ) and self:Visible( ent ) then
				local entTeam = self:GetCapturerTeamName( ent )
				if !curTeam then curTeam = entTeam continue end
				if entTeam != curTeam then return true end
			end
		end
	    return false
	end

	function ENT:Think()
		local capName = self:GetCapturerName()
		
		self:SetContesterTeam( "" )
		self:SetContesterColor( vec_white )

		if !self:IsContested() then
			local capRate = captureRate:GetFloat()

			for _, ent in ipairs( FindInSphere( self:GetPos(), captureRange:GetInt() ) ) do
				if LambdaIsValid( ent ) and ( ent.IsLambdaPlayer or ent:IsPlayer() and !ignorePlys:GetBool() ) and ent:Alive() and self:Visible( ent ) then
					local entTeam = self:GetCapturerTeamName( ent )
					local capPerc = self:GetCapturePercent()

					if self:GetIsCaptured() then
						if entTeam != capName then
			                if capPerc <= 0 then
			        			for _, lambda in ipairs( GetLambdaPlayers() ) do
						            if lambda:GetIsDead() or self:GetCapturerTeamName( lambda ) != capName or random( 1, 100 ) > lambda:GetVoiceChance() / 2 then continue end
						            lambda:SimpleTimer( Rand( 0.1, 1.0 ), function() lambda:PlaySoundFile( lambda:GetVoiceLine( "death" ) ) end )
						        end

			                    self:SetIsCaptured( false )
			                    self:SetCapturePercent( 0 )
			                    self:SetCapturerName( "Neutral" )
			                    self.OldColor = self:GetCapturerColor()
			                    self:SetCapturerColor( vec_white )

			                    self:EmitSound( "lambdaplayers/koth/holdlost.mp3", 100 )
			                    self:EmitSound( "lambdaplayers/koth/pointneutral.mp3", 65 )
			                    
			                    LambdaPlayers_ChatAdd( nil, color_glacier, "[", self.OldColor:ToColor(), self:GetPointName(), color_glacier, "]", " was brought to neutral" )
			                end

					    	self:SetCapturePercent( Clamp( capPerc - capRate, 0, 100 ) )
						else
					        self:SetCapturePercent( Clamp( capPerc + capRate, 0, 100 ) )
						end
					elseif entTeam != capName then
						local capTeamClr = self:GetCapturerTeamColor( ent )
						
						self:SetContesterTeam( entTeam )
			            self.OldColor = self:GetCapturerColor()
						self:SetContesterColor( capTeamClr )

						if capPerc < 100 then
					    	self:SetCapturePercent( Clamp( capPerc + capRate, 0, 100 ) )
						else
					        for _, lambda in ipairs( GetLambdaPlayers() ) do
					            if lambda:GetIsDead() or self:GetCapturerTeamName( lambda ) != entTeam or ent != lambda and random( 1, 100 ) > lambda:GetVoiceChance() / 2 then continue end
					            lambda:SimpleTimer( Rand( 0.1, 1.0 ), function() lambda:PlaySoundFile( lambda:GetVoiceLine( "kill" ) ) end )
					        end

			                self:SetIsCaptured( true )
		                    self:SetCapturePercent( 100 )
		                    self:SetCapturerName( entTeam )

						    self:EmitSound( "lambdaplayers/koth/captured.mp3", 100 )
						    self:EmitSound( "lambdaplayers/koth/pointcap.mp3", 65 )

						    self:SetCapturerColor( capTeamClr )
						    LambdaPlayers_ChatAdd( nil, color_glacier, "[", self.OldColor:ToColor(), self:GetPointName(), color_glacier, "]"," has been captured by ", self:GetCapturerColor():ToColor(), self:GetCapturerName(), ( self:GetCapturerTeamName( ent ) != ent:Nick() and " (" .. ent:Nick() .. ")" or "" ) )
						end
					end
				end
			end
		end

	    self:NextThink( 0.05 )
	    return true
	end

end

if ( CLIENT ) then

	local cam = cam
	local DrawText = draw.DrawText
	local tostring = tostring
	local CurTime = CurTime
	local angAxisVec = Vector( 0, 0, 1 )
	local drawAng = Angle( 0, 0, 90 )
    local drawVec = Vector( 0, 0, 0 )
    local floor = math.floor
    local string_upper = string.upper
    local LerpVector = LerpVector

	function ENT:Draw3DText( text, pos, ang, scale )
	    local color = self:GetCapturerColor()
        local capPerc = self:GetCapturePercent()
        if !self:GetIsCaptured() then
            color = LerpVector( ( capPerc / 100 ), color, self:GetContesterColor() )
        else
            color = LerpVector( ( ( 100 - capPerc ) / 100 ), color, vec_white )
        end
        color = color:ToColor()

        cam.Start3D2D( pos, ang, scale )
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()

        ang:RotateAroundAxis( angAxisVec, 180 )

        cam.Start3D2D( pos, ang, scale )
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()
	end

	function ENT:Draw()
		local myPos = self:GetPos()
	    drawAng[ 2 ] = ( CurTime() * 20 % 360 )
	    
	    drawVec.z = 100
	    self:Draw3DText( "[POINT " .. string_upper( self:GetPointName() ) .. "] " .. self:GetCapturerName(), myPos + drawVec, drawAng, 0.5 )

	    drawVec.z = 110
	    self:Draw3DText( floor( self:GetCapturePercent() ), myPos + drawVec, drawAng, 0.5 )

	    self:DrawModel()
	end

end