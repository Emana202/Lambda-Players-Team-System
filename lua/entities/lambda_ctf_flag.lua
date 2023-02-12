AddCSLuaFile()

ENT.Base = "base_anim"
ENT.IsLambdaFlag = true

local vec_white = Vector(1,1,1)
local CurTime = CurTime

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "FlagName" )
    self:NetworkVar( "String", 1, "TeamName" )

    self:NetworkVar( "Entity", 0, "FlagHolderEnt" )

    self:NetworkVar( "Bool", 0, "IsCaptureZone" )
    self:NetworkVar( "Bool", 1, "IsPickedUp" )
    self:NetworkVar( "Bool", 2, "IsAtHome" )

    self:NetworkVar( "Int", 0, "ReturnTime" )
    
    self:NetworkVar( "Vector", 0, "TeamColor" )
end

if ( SERVER ) then

    local IsValid = IsValid
    local net = net
    local SpriteTrail = util.SpriteTrail
    local TraceLine = util.TraceLine
    local downtracetbl = {}
    local dropZ = Vector( 0, 0, 32756 )
    local returnZ = Vector( 0, 0, 15 )
    local keynames = { "A", "B", "C", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    local color_glacier = Color( 130, 164, 192 )
    local timer_Simple = timer.Simple
    local spawnOffset = Vector( 0, 0, 15 )
    local FindInSphere = ents.FindInSphere
    local ipairs = ipairs
    local random = math.random
    local ents_Create = ents.Create
    local IsValidModel = util.IsValidModel
    local returnTime = GetConVar( "lambdaplayers_teamsystem_ctf_returntime" )
    local ignorePlys = GetConVar( "ai_ignoreplayers" )

    function ENT:Initialize()
        local customMdl = self.CustomModel
        if customMdl and IsValidModel( customMdl ) then
            self:SetModel( customMdl )
        else
            self:SetModel( "models/lambdaplayers/ctf_flag/briefcase.mdl" )
        end

        timer_Simple( 0, function() self:SetPos( self:GetPos() + spawnOffset ) end )

        self.CaptureZone = ents_Create( "base_anim" )
        self.CaptureZone:SetModel( "models/props_combine/combine_mine01.mdl" )
        self.CaptureZone:SetPos( self:GetPos() )
        self.CaptureZone:Spawn()
        self.CaptureZone.Flag = self
        self.CaptureZone.IsLambdaCaptureZone = true
        self:DeleteOnRemove( self.CaptureZone )

        self.FlagHolder = NULL
        self:SetFlagHolderEnt( NULL )
        
        self.FlagHolderName = nil
        self.FlagHolderTeam = nil
        self.FlagHolderColor = nil
        self.FlagDropTime = CurTime()

        self:SetReturnTime( 0 )
        self:SetIsAtHome( true )
        self:SetIsPickedUp( false )
        self:SetIsCaptureZone( self.IsCaptureZone )

        self.PlaceholderAngle = Angle( 0, ( CurTime() * 50 % 360 ), 0 )
        self:SetAngles( self.PlaceholderAngle )

        local flagName = ( ( self.CustomName and self.CustomName != "" ) and self.CustomName )
        self:SetFlagName( flagName or keynames[ random( #keynames ) ] .. self:GetCreationID() )

        local teamName = ( ( self.TeamName and self.TeamName != "" ) and self.TeamName )
        self:SetTeamName( teamName or "Neutral" )

        local teamColor = LambdaTeams:GetTeamColor( teamName )
        local color = ( teamColor and teamColor:ToColor() or color_white )
        self:SetTeamColor( color:ToVector() )
        self:SetColor( color )
        self.CaptureZone:SetColor( color )
    end

    function ENT:SetFlagHolder( ent )
        if ent == false then
            if IsValid( self.FlagHolder ) then 
                self.FlagHolder.l_HasFlag = false 
            end

            self.FlagHolder = NULL
            self:SetFlagHolderEnt( NULL )

            self.FlagHolderName = nil
            self.FlagHolderTeam = nil
            self.FlagHolderColor = nil
            self:SetIsPickedUp( false )
        else
            self.FlagHolder = ent
            self:SetFlagHolderEnt( ent )

            self.FlagHolder.l_HasFlag = true
            self.FlagHolderName = ent:Nick()
            self.FlagHolderTeam = LambdaTeams:GetPlayerTeam( ent )
            self.FlagHolderColor = LambdaTeams:GetTeamColor( self.FlagHolderTeam ):ToColor()

            self:SetIsAtHome( false )
            self:SetIsPickedUp( true )
            if ent.IsLambdaPlayer then ent:CancelMovement() end
        end
    end

    function ENT:OnCaptured()
        local teamName = self:GetTeamName()
        local flagName = self:GetFlagName()
        local teamColor = self:GetTeamColor():ToColor()
        if teamName != "Neutral" then
            LambdaPlayers_ChatAdd( nil, self.FlagHolderColor, self.FlagHolderName, color_glacier, " captured ", teamColor, teamName, color_glacier, "'s ", teamColor, flagName, color_glacier, " flag!" )
        else
            LambdaPlayers_ChatAdd( nil, self.FlagHolderColor, self.FlagHolderName, color_glacier, " captured the ", teamColor, flagName, color_glacier, " flag!" )
        end

        net.Start( "lambda_teamsystem_playclientsound" )
            net.WriteString( "lambdaplayers_teamsystem_ctf_snd_oncapture_" )
            net.WriteBool( true )
            net.WriteString( self.FlagHolderTeam )
            net.WriteString( teamName )
        net.Broadcast()

        self:ReturnToZone()
        if IsValid( self.Trail ) then self.Trail:Remove() end
    end

    function ENT:ReturnToZone()
        self:SetPos( self.CaptureZone:GetPos() + returnZ )
        self:SetIsAtHome( true )
        self:SetFlagHolder( false )
    end 

    function ENT:OnRemove()
        self:SetFlagHolder( false )
    end

    function ENT:Think()
        local holder = self.FlagHolder
        local teamName = self:GetTeamName()
        local flagName = self:GetFlagName()
        local teamColor = self:GetTeamColor():ToColor()

        if !self:GetIsAtHome() and !self:GetIsPickedUp() then 
            local retTime = self:GetReturnTime()
            if retTime != 0 and ( retTime - CurTime() ) <= 1 then
                if teamName != "Neutral" then
                    LambdaPlayers_ChatAdd( nil, teamColor, teamName, color_glacier, "'s ", teamColor, flagName, color_glacier, " flag has returned back to its zone!" )
                else
                    LambdaPlayers_ChatAdd( nil, teamColor, flagName, color_glacier, " flag has returned back to its zone!" )
                end

                net.Start( "lambda_teamsystem_playclientsound" )
                    net.WriteString( "lambdaplayers_teamsystem_ctf_snd_onreturn" )
                    net.WriteBool( false )
                net.Broadcast()

                self:SetReturnTime( 0 )
                self:ReturnToZone()
            end
        else
            self:SetReturnTime( CurTime() + returnTime:GetFloat() + 1.0 )
        end

        for _, ent in ipairs( FindInSphere( self.CaptureZone:GetPos(), 100 ) ) do
            if ent != self and IsValid( ent ) and ent.IsLambdaFlag and ent:GetIsPickedUp() and ent:GetTeamName() != teamName and LambdaTeams:GetPlayerTeam( ent.FlagHolder ) == teamName then
                ent:OnCaptured()
            end
        end

        if self:GetIsPickedUp() then
            if IsValid( holder ) and holder:Alive() then
                local backBone = holder:LookupBone( "ValveBiped.Bip01_Spine2" )
                if backBone then
                    local backPos, backAng = holder:GetBonePosition( backBone )
                    backAng[ 3 ] = backAng[ 3 ] + 90

                    self:SetPos( backPos + backAng:Up() * 6 - backAng:Forward() * 2 )
                    self:SetAngles( backAng )
                else
                    self:SetPos( holder:WorldSpaceCenter() + holder:GetUp() * 10 - holder:GetForward() * 10 )
                    self:SetAngles( holder:GetAngles() + Angle( 90, 0, 180 ) )
                end
            else
                if teamName != "Neutral" then
                    LambdaPlayers_ChatAdd( nil, teamColor, teamName, color_glacier, "'s ", teamColor, flagName, color_glacier, " flag has been dropped!" )
                else
                    LambdaPlayers_ChatAdd( nil, teamColor, flagName, color_glacier, " flag has been dropped!")
                end

                net.Start( "lambda_teamsystem_playclientsound" )
                    net.WriteString( "lambdaplayers_teamsystem_ctf_snd_ondrop" )
                    net.WriteBool( false )
                net.Broadcast()

                self:SetFlagHolder( false )
                if IsValid( self.Trail ) then self.Trail:Remove() end

                downtracetbl.start = self:GetPos()
                downtracetbl.endpos = ( self:GetPos() - dropZ )
                downtracetbl.filter = self
                local downtrace = TraceLine( downtracetbl )
                self:SetPos( downtrace.HitPos - downtrace.HitNormal * self:OBBMins().z )
            end
        else
            self.PlaceholderAngle.y = ( CurTime() * 50 % 360 )
            self:SetAngles( self.PlaceholderAngle )

            if !self.IsCaptureZone then
                for _, ent in ipairs( FindInSphere( self:GetPos(), 100 ) ) do
                    if ent != self and IsValid( ent ) and !ent.l_HasFlag and ( ent.IsLambdaPlayer or ent:IsPlayer() and !ignorePlys:GetBool() ) and ent:Alive() then
                        local entTeam = LambdaTeams:GetPlayerTeam( ent )
                        if entTeam and entTeam != teamName then
                            self:SetFlagHolder( ent )
                            self.Trail = SpriteTrail( self, 0, teamColor, true, 40, 40, 2, ( 1 / ( 40 - 40 ) * 0.5 ) , "trails/laser" )

                            if teamName != "Neutral" then
                                LambdaPlayers_ChatAdd( nil, self.FlagHolderColor, self.FlagHolderName, color_glacier, " took ", teamColor, teamName, color_glacier, "'s ", teamColor, flagName, color_glacier, " flag!" )
                            else
                                LambdaPlayers_ChatAdd( nil, self.FlagHolderColor, self.FlagHolderName, color_glacier, " took the ", teamColor, flagName, color_glacier, " flag!" )
                            end

                            net.Start( "lambda_teamsystem_playclientsound" )
                                net.WriteString( "lambdaplayers_teamsystem_ctf_snd_onpickup_" )
                                net.WriteBool( true )
                                net.WriteString( teamName )
                                net.WriteString( self.FlagHolderTeam )
                            net.Broadcast()

                            break
                        end
                    end
                end
            end
        end

        self:NextThink( CurTime() )
        return true
    end

end

if ( CLIENT ) then

    local cam = cam
    local DrawText = draw.DrawText
    local floor = math.floor
    local angAxisVec = Vector( 0, 0, 1 )
    local drawAng = Angle( 0, 0, 90 )
    local drawVec = Vector( 0, 0, 0 )

    function ENT:Draw3DText( text, pos, ang, scale )
        local color = self:GetTeamColor():ToColor()

        cam.IgnoreZ( true )
            cam.Start3D2D(pos, ang,scale)
                cam.IgnoreZ( true )
                DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
            cam.End3D2D()

            ang:RotateAroundAxis( angAxisVec, 180 )

            cam.Start3D2D(pos, ang, scale)
                cam.IgnoreZ( true )
                DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
            cam.End3D2D()
        cam.IgnoreZ( false )
    end

    function ENT:Draw()
        if !self:GetIsPickedUp() then
            drawAng[ 2 ] = ( CurTime() * 5 % 360 )

            local maxsZ = self:OBBMaxs().z
            drawVec[ 3 ] = ( 40 + maxsZ )
            self:Draw3DText( self:GetTeamName(), ( self:GetPos() + drawVec ), drawAng, 0.5 )

            drawVec[ 3 ] = ( 30 + maxsZ )
            self:Draw3DText( "[" .. self:GetFlagName() .. "]" .. ( self:GetIsCaptureZone() and ": CAPTURE ZONE" or "" ), ( self:GetPos() + drawVec ), drawAng, 0.5 )

            if !self:GetIsAtHome() then
                local returnTime = self:GetReturnTime()
                drawVec[ 3 ] = ( 20 + maxsZ )
                self:Draw3DText( "Returns in: " .. floor( returnTime - CurTime() ), ( self:GetPos() + drawVec ), drawAng, 0.5 )
            end
        end

        local ply = LocalPlayer()
        if !self:GetIsCaptureZone() and ( ply != self:GetFlagHolderEnt() or ply:ShouldDrawLocalPlayer() ) then
            self:DrawModel()
        end
    end

end