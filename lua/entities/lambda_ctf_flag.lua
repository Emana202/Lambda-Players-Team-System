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
    local traceTbl = { filter = {} }
    local keynames = { "A", "B", "C", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    local color_glacier = Color( 130, 164, 192 )
    local timer_Simple = timer.Simple
    local FindInSphere = ents.FindInSphere
    local ipairs = ipairs
    local random = math.random
    local Rand = math.Rand
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

        timer_Simple( 0, function() self:SetPos( self:GetPos() + vector_up * 15 ) end )

        self.CaptureZone = ents_Create( "base_anim" )
        self.CaptureZone:SetModel( "models/props_combine/combine_mine01.mdl" )
        self.CaptureZone:SetPos( self:GetPos() )
        self.CaptureZone:Spawn()
        self.CaptureZone.Flag = self
        self.CaptureZone.IsLambdaCaptureZone = true
        self:DeleteOnRemove( self.CaptureZone )

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
            if IsValid( self:GetFlagHolderEnt() ) then 
                self:GetFlagHolderEnt().l_HasFlag = false 
            end

            self:SetFlagHolderEnt( NULL )
            self.FlagHolderName = nil
            self.FlagHolderTeam = nil
            self.FlagHolderColor = nil
            self:SetIsPickedUp( false )
        else
            self:SetFlagHolderEnt( ent )
            ent.l_HasFlag = true
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
            LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", self.FlagHolderColor, self.FlagHolderName, color_glacier, " captured ", teamColor, teamName, "'s ", flagName, color_glacier, " flag!" )
        else
            LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", self.FlagHolderColor, self.FlagHolderName, color_glacier, " captured the ", teamColor, flagName, color_glacier, " flag!" )
        end

        local flagHolderTeam = self.FlagHolderTeam
        if LambdaTeams:GetCurrentGamemodeID() == 2 then
            LambdaTeams:AddTeamPoints( flagHolderTeam, 1 )
        end

        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_oncapture_ally", flagHolderTeam )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_oncapture_enemy", teamName )
        
        local flagHolder = self:GetFlagHolderEnt()
        for _, lambda in ipairs( GetLambdaPlayers() ) do
            if lambda:GetIsDead() or flagHolder != lambda and random( 1, 100 ) > lambda:GetVoiceChance() then continue end

            local voiceLine = nil
            local lambdaTeam = lambda.l_TeamName
            
            if lambdaTeam == teamName then
                voiceLine = "death"
            elseif lambdaTeam == flagHolderTeam then
                voiceLine = ( ( flagHolder != lambda and random( 1, 3 ) == 1 ) and "assist" or "kill" )
            end

            if !voiceLine then continue end
            lambda:SimpleTimer( Rand( 0.1, 1.0 ), function() lambda:PlaySoundFile( lambda:GetVoiceLine( voiceLine ) ) end )
        end

        self:ReturnToZone()
        if IsValid( self.Trail ) then self.Trail:Remove() end
    end

    function ENT:ReturnToZone()
        self:SetPos( self.CaptureZone:GetPos() + vector_up * 15 )
        self:SetIsAtHome( true )
        self:SetFlagHolder( false )
    end 

    function ENT:OnRemove()
        self:SetFlagHolder( false )
    end

    function ENT:Think()
        local holder = self:GetFlagHolderEnt()
        local teamName = self:GetTeamName()
        local flagName = self:GetFlagName()
        local teamColor = self:GetTeamColor():ToColor()

        if !self:GetIsAtHome() and !self:GetIsPickedUp() then 
            local retTime = self:GetReturnTime()
            if retTime != 0 and ( retTime - CurTime() ) <= 1 then
                if teamName != "Neutral" then
                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", teamColor, teamName, "'s ", flagName, color_glacier, " flag has returned back to its zone!" )
                else
                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", teamColor, flagName, color_glacier, " flag has returned back to its zone!" )
                end

                LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_onreturn" )

                self:SetReturnTime( 0 )
                self:ReturnToZone()
            end
        else
            self:SetReturnTime( CurTime() + returnTime:GetFloat() + 1.0 )
        end
        
        traceTbl.start = self:WorldSpaceCenter()
        traceTbl.filter[ 1 ] = self
        traceTbl.filter[ 2 ] = self.CaptureZone

        for _, ent in ipairs( FindInSphere( self.CaptureZone:GetPos(), 100 ) ) do
            if ent != self and IsValid( ent ) and ent.IsLambdaFlag and ent:GetIsPickedUp() and ent:GetTeamName() != teamName and LambdaTeams:GetPlayerTeam( ent:GetFlagHolderEnt() ) == teamName then
                traceTbl.endpos = ent:WorldSpaceCenter()

                local visTr = TraceLine( traceTbl )
                if visTr.Entity == ent or !visTr.Hit then
                    ent:OnCaptured()
                end
            end
        end

        if self:GetIsPickedUp() then
            if IsValid( holder ) and holder:Alive() and ( !holder:IsPlayer() or !ignorePlys:GetBool() ) then
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
                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", teamColor, teamName, "'s ", flagName, color_glacier, " flag has been dropped!" )
                else
                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", teamColor, flagName, color_glacier, " flag has been dropped!")
                end
                
                for _, lambda in ipairs( GetLambdaPlayers() ) do
                    if lambda:GetIsDead() or lambda.l_TeamName != teamName then continue end
                    lambda:CancelMovement()

                    if random( 1, 100 ) <= lambda:GetVoiceChance() / 2 then
                        lambda:SimpleTimer( Rand( 0.1, 1.0 ), function() lambda:PlaySoundFile( lambda:GetVoiceLine( "assist" ) ) end )
                    end
                end

                LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_ondrop" )

                self:SetFlagHolder( false )
                if IsValid( self.Trail ) then self.Trail:Remove() end

                traceTbl.endpos = ( self:GetPos() - vector_up * 32756 )
                local downtrace = TraceLine( traceTbl )
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
                            traceTbl.endpos = ent:WorldSpaceCenter()

                            local visTr = TraceLine( traceTbl )
                            if visTr.Entity == ent or !visTr.Hit then
                                self:SetFlagHolder( ent )
                                self.Trail = SpriteTrail( self, 0, teamColor, true, 40, 40, 2, ( 1 / ( 40 - 40 ) * 0.5 ) , "trails/laser" )

                                if teamName != "Neutral" then
                                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", self.FlagHolderColor, self.FlagHolderName, color_glacier, " took ", teamColor, teamName, "'s ", flagName, color_glacier, " flag!" )
                                else
                                    LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", self.FlagHolderColor, self.FlagHolderName, color_glacier, " took the ", teamColor, flagName, color_glacier, " flag!" )
                                end

                                local holderTeam = self.FlagHolderTeam
                                for _, lambda in ipairs( GetLambdaPlayers() ) do
                                    if lambda:GetIsDead() or ent != lambda and random( 1, 100 ) > lambda:GetVoiceChance() / 3 then continue end

                                    local voiceLine = nil
                                    local lambdaTeam = lambda.l_TeamName

                                    if lambdaTeam == teamName then
                                        voiceLine = "panic"
                                        lambda:CancelMovement()
                                    elseif lambdaTeam == holderTeam then
                                        voiceLine = "taunt" 
                                    end

                                    if !voiceLine then continue end
                                    lambda:SimpleTimer( Rand( 0.1, 1.0 ), function() lambda:PlaySoundFile( lambda:GetVoiceLine( voiceLine ) ) end )
                                end

                                LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_onpickup_ally", teamName )
                                LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_ctf_snd_onpickup_enemy", holderTeam )
                                
                                break
                            end
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

        cam.Start3D2D(pos, ang, scale)
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()

        ang:RotateAroundAxis( angAxisVec, 180 )

        cam.Start3D2D(pos, ang, scale)
            DrawText( text, "ChatFont", 0, 0, color, TEXT_ALIGN_CENTER )
        cam.End3D2D()
    end

    function ENT:Draw()
        local isCapZone = self:GetIsCaptureZone()
        local teamName = self:GetTeamName()

        if !self:GetIsPickedUp() then
            local myPos = self:GetPos()
            drawAng[ 2 ] = ( CurTime() * 5 % 360 )

            local maxsZ = self:OBBMaxs().z
            drawVec[ 3 ] = ( 40 + maxsZ )
            self:Draw3DText( self:GetTeamName(), ( myPos + drawVec ), drawAng, 0.5 )

            drawVec[ 3 ] = ( 30 + maxsZ )
            self:Draw3DText( "[" .. self:GetFlagName() .. "]" .. ( isCapZone and ": CAPTURE ZONE" or "" ), ( myPos + drawVec ), drawAng, 0.5 )

            if !self:GetIsAtHome() then
                local returnTime = self:GetReturnTime()
                drawVec[ 3 ] = ( 20 + maxsZ )
                self:Draw3DText( "Returns in: " .. floor( returnTime - CurTime() ), ( myPos + drawVec ), drawAng, 0.5 )
            end
        end

        local ply = LocalPlayer()
        local drawMdl = ( !isCapZone and ( ply != self:GetFlagHolderEnt() or ply:ShouldDrawLocalPlayer() ) )
        self:DrawShadow( drawMdl )
        if drawMdl then self:DrawModel() end
    end

end
