local ipairs = ipairs
local IsValid = IsValid
local pairs = pairs
local random = math.random
local file_Exists = file.Exists
local table_Count = table.Count
local team_SetUp = team.SetUp
local net = net
local ents_FindByClass = ents.FindByClass

local modulePrefix = "Lambda_TeamSystem_"
local defaultTeamList = {
    [ "Based Bros" ] = {
        name = "Based Bros",
        color = Vector( 1, 0, 0 )
    },
    [ "Counter-Minges" ] = {
        name = "Counter-Minges",
        color = Vector( 0, 0.2471, 1 )
    },
    [ "Eeveelutioners" ] = {
        name = "Eeveelutioners",
        color = Vector( 0, 1, 1 )
    },
    [ "ARCLIGHT" ] = {
        name = "ARCLIGHT",
        color = Vector( 0.6039, 0.2392, 1 )
    }
}

if !file_Exists( "lambdaplayers/teamlist.json", "DATA" ) then
    LAMBDAFS:WriteFile( "lambdaplayers/teamlist.json", defaultTeamList, "json", false )
end

LambdaTeams = LambdaTeams or {}

function LambdaTeams:GetTeamColor( teamName )
    local data = LambdaTeams.TeamData[ teamName ]
    return ( data and data.color )
end

function LambdaTeams:GetPlayerTeam( ply )
    if IsValid( ply ) then
        if ply:IsPlayer() then
            local plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
            return ( plyTeam != "" and plyTeam )
        end
        return ( ply.l_TeamName )
    end
end

local function UpdateTeamDataList( dataTbl )
    LambdaTeams.TeamData = ( dataTbl or LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" ) )
    LambdaTeams.RealTeams = LambdaTeams.RealTeams or {}
    LambdaTeams.RealTeamCount = LambdaTeams.RealTeamCount or 0

    if ( CLIENT ) then
        LambdaTeams.TeamOptions = { [ "None" ] = "" }
        LambdaTeams.TeamOptionsRandom = { [ "None" ] = "", [ "Random" ] = "random" }

        for k, _ in pairs( LambdaTeams.TeamData ) do 
            LambdaTeams.TeamOptions[ k ] = k 
            LambdaTeams.TeamOptionsRandom[ k ] = k
        end
    end

    for k, v in pairs( LambdaTeams.TeamData ) do 
        if !LambdaTeams.RealTeams[ k ] then
            local teamID = ( LambdaTeams.RealTeamCount + 1 )
            team_SetUp( teamID, k, ( v.color and v.color:ToColor() or Color( 255, 255, 100 ) ), false )
            
            LambdaTeams.RealTeams[ k ] = teamID
            LambdaTeams.RealTeamCount = teamID
        end
    end
end
UpdateTeamDataList()

---

local teamsEnabled  = CreateLambdaConvar( "lambdaplayers_teamsystem_enable", 0, true, false, false, "Enables the work of the module.", 0, 1, { name = "Enable Team System", type = "Bool", category = "Team System" } )
local mwsTeam       = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_spawnteam", "", true, false, false, "The team the newly spawned Lambda Players from MWS should be assigned into.", 0, 1, { name = "Spawn Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "MWS" } )
local incNoTeams    = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_includenoteams", 0, true, false, false, "When spawning a Lambda Player from MWS with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "MWS" }  )
CreateLambdaConvar( "lambdaplayers_teamsystem_lambdateam", "", true, true, true, "The team the newly spawned Lambda Players should be assigned into.", 0, 1, { name = "Lambda Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "Team System" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_includenoteams", 0, true, true, true, "When spawning a Lambda Player with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "Team System" }  )
CreateLambdaConvar( "lambdaplayers_teamsystem_playerteam", "", true, true, true, "The lambda team you are currently assigned to.", 0, 1, { name = "Player Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System" }  )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_updateteamlist", function( ply ) 
    UpdateTeamDataList()

    for _, v in ipairs( _LAMBDAConVarSettings ) do
        if v.name == "Player Team" then v.options = LambdaTeams.TeamOptions end
        if v.name == "Lambda Team" then v.options = LambdaTeams.TeamOptionsRandom end
    end

    ply:ConCommand( "spawnmenu_reload" )
end, true, "Refreshes the team list. Use this after adding or removing teams in the panel.", { name = "Refresh Team List", category = "Team System" } )

local attackOthers  = CreateLambdaConvar( "lambdaplayers_teamsystem_attackotherteams", 0, true, false, false, "If Lambda Players should immediately start attacking the members of other teams at their sight.", 0, 1, { name = "Attack On Sight", type = "Bool", category = "Team System" } )
local noFriendFire  = CreateLambdaConvar( "lambdaplayers_teamsystem_nofriendlyfire", 1, true, false, false, "If Lambda Players shouldn't be able to damage their teammates.", 0, 1, { name = "No Friendly Fire", type = "Bool", category = "Team System" } )
local stickTogether = CreateLambdaConvar( "lambdaplayers_teamsystem_sticktogether", 1, true, false, false, "If Lambda Players should stick together with their teammates.", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )
local huntDown      = CreateLambdaConvar( "lambdaplayers_teamsystem_huntdownotherteams", 0, true, false, false, "If Lambda Players should hunt down the members of other teams. 'Attack On Sight' option should be enabled for it to work.", 0, 1, { name = "Hunt Down Enemy Teams", type = "Bool", category = "Team System" } )
local drawTeamName  = CreateLambdaConvar( "lambdaplayers_teamsystem_drawteamname", 1, true, true, false, "Enables drawing team names above your Lambda teammates.", 0, 1, { name = "Draw Team Names", type = "Bool", category = "Team System" } )
local drawHalo      = CreateLambdaConvar( "lambdaplayers_teamsystem_drawhalo", 1, true, true, false, "Enables drawing halos around you Lambda Teammates", 0, 1, { name = "Draw Halos", type = "Bool", category = "Team System" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerate", 0.2, true, false, false, "The speed rate of capturing the KOTH Points.", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - KOTH" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_returntime", 15, true, false, false, "The time Lambda Flag can be in dropped state before returning to its capture zone.", 0, 120, { name = "Time Before Returning", type = "Slider", decimals = 0, category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_enemy", "lambdaplayers/ctf/flagsteal.mp3", true, true, false, "The sound that plays when your team picks up enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_ally", "lambdaplayers/ctf/ourflagstole.mp3", true, true, false, "The sound that plays when enemy team picks up your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_ally", "lambdaplayers/ctf/flagcapture.mp3", true, true, false, "The sound that plays when your team has captured enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_enemy", "lambdaplayers/ctf/ourflagcaptured.mp3", true, true, false, "The sound that plays when enemy team has captured your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_ondrop", "lambdaplayers/ctf/flagdropped.mp3", true, true, false, "The sound that plays when the CTF Flag is dropped.", 0, 1, { name = "Sound - On Flag Drop", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onreturn", "lambdaplayers/ctf/flagreturn.mp3", true, true, false, "The sound that plays when the CTF Flag has returned to its base.", 0, 1, { name = "Sound - On Flag Return", type = "Text", category = "Team System - CTF" } )

---

if ( SERVER ) then

    util.AddNetworkString( "lambda_teamsystem_playclientsound" )
    util.AddNetworkString( "lambda_teamsystem_setplayerteam" )
    util.AddNetworkString( "lambda_teamsystem_updateteamdatalist" )

    local CurTime = CurTime
    local GetNavArea = navmesh.GetNavArea
    local VectorRand = VectorRand
    local ents_GetAll = ents.GetAll
    local ignorePlys = GetConVar( "ai_ignoreplayers" )
    local RandomPairs = RandomPairs
    local table_Random = table.Random
    local timer_Simple = timer.Simple

    net.Receive( "lambda_teamsystem_setplayerteam", function()
        local ply = net.ReadEntity()
        if !IsValid( ply ) then return end

        local teamID = LambdaTeams.RealTeams[ net.ReadString() ]
        if teamID and teamsEnabled:GetBool() then 
            ply:SetTeam( teamID )
            ply.l_IsInLambdaTeam = true
        elseif ply.l_IsInLambdaTeam then
            ply:SetTeam( 1001 )
            ply.l_IsInLambdaTeam = false
        end
    end )

    net.Receive( "lambda_teamsystem_updateteamdatalist", function()
        local dataTbl = util.JSONToTable( net.ReadString() )
        UpdateTeamDataList( dataTbl )
    end )

    local function OnTeamSystemDisable( name, oldVal, newVal )
        for _, ply in ipairs( ents_GetAll() ) do
            if IsValid( ply ) then
                if ply.IsLambdaPlayer then
                    local teamID = LambdaTeams.RealTeams[ ply.l_TeamName ]
                    if teamID and teamsEnabled:GetBool() and ply:GetTeam() == 0 then
                        ply:SetTeam( teamID )
                    elseif ply:GetTeam() != 0 then
                        ply:SetTeam( 0 )
                    end
                elseif ply:IsPlayer() then
                    local teamID = LambdaTeams.RealTeams[ ply:GetInfo( "lambdaplayers_teamsystem_playerteam" ) ]
                    if teamID and teamsEnabled:GetBool() and !ply.l_IsInLambdaTeam then
                        ply:SetTeam( teamID )
                        ply.l_IsInLambdaTeam = true
                    elseif ply.l_IsInLambdaTeam then
                        ply:SetTeam( 1001 )
                        ply.l_IsInLambdaTeam = false
                    end
                end
            end 
        end
    end
    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_enable", modulePrefix .. "OnSystemChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_enable", OnTeamSystemDisable, modulePrefix .. "OnSystemChanged" )

    local function SetLambdasTeam( lambda, teamName, rndNoTeams )
        if !teamsEnabled:GetBool() then return end

        local teamData
        if teamName == "random" then
            if rndNoTeams then
                local teamCount = table_Count( LambdaTeams.TeamData )
                if random( 1, teamCount + 1 ) > teamCount then return end
            end
            teamData = table_Random( LambdaTeams.TeamData )
        else
            teamData = LambdaTeams.TeamData[ teamName ]
        end
        if !teamData then return end

        local teamName = teamData.name
        lambda:SetExternalVar( "l_TeamName", teamName )
        lambda:SetNW2String( "lambda_teamname", teamName )
        lambda:SetNWString( "lambda_teamname", teamName )

        local teamColor = teamData.color
        lambda:SetExternalVar( "l_TeamColor", teamColor:ToColor() )
        lambda:SetPlyColor( teamColor )
        lambda:SetNW2Vector( "lambda_teamcolor", teamColor )
        lambda:SetNWVector( "lambda_teamcolor", teamColor )

        local teamID = LambdaTeams.RealTeams[ teamName ]
        if teamID then lambda:SetTeam( teamID ) end
    end

    local function OnPlayerSpawnedNPC( ply, npc )
        if npc.IsLambdaPlayer then SetLambdasTeam( npc, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ) end
    end

    local function LambdaOnInitialize( self )
        if self.l_MWSspawned then SetLambdasTeam( self, mwsTeam:GetString(), incNoTeams:GetBool() ) end

        function self:IsInMyTeam( ent )
            local myTeam = self.l_TeamName
            if !myTeam then return end

            local entTeam = ( ent:IsPlayer() and ent:GetInfo( "lambdaplayers_teamsystem_playerteam" ) or ent.l_TeamName )
            if !entTeam or entTeam == "" then return end

            return ( entTeam == myTeam )
        end

        function self:GetRandomTeamMember()
            if !self.l_TeamName then return NULL end
            
            for _, tm in RandomPairs( ents_GetAll() ) do
                if tm != self and LambdaIsValid( tm ) and self:IsInMyTeam( tm ) == true and ( !tm:IsPlayer() or tm:Alive() and !ignorePlys:GetBool() ) then
                    return tm
                end
            end
        end

        self.l_NextEnemyTeamSearchT = CurTime() + 1.0
        if self.l_TeamColor then self:SetPlyColor( self.l_TeamColor:ToVector() ) end
    end

    local function LambdaPostRecreated( self )
        if self.l_TeamName then
            self:SetNW2String( "lambda_teamname", self.l_TeamName )
            self:SetNWString( "lambda_teamname", self.l_TeamName )
        end

        if self.l_TeamColor then
            self.l_TeamColor = Color( self.l_TeamColor.r, self.l_TeamColor.g, self.l_TeamColor.b )
            self:SetPlyColor( self.l_TeamColor:ToVector() )
            self:SetNW2Vector( "lambda_teamcolor", self.l_TeamColor:ToVector() )
            self:SetNWVector( "lambda_teamcolor", self.l_TeamColor:ToVector() )
        end
    end

    local function LambdaOnThink( self )
        if !teamsEnabled:GetBool() then return end

        if CurTime() > self.l_NextEnemyTeamSearchT then
            self.l_NextEnemyTeamSearchT = CurTime() + 1.0

            if self.l_TeamName and ( !self:InCombat() or !self:CanSee( self:GetEnemy() ) ) and attackOthers:GetBool() then
                local surroundings = self:FindInSphere( nil, 2000, function( ent )
                    return ( LambdaIsValid( ent ) and self:CanTarget( ent ) and self:IsInMyTeam( ent ) == false and ( !IsValid( self:GetEnemy() ) or self:GetRangeSquaredTo( ent ) < self:GetRangeSquaredTo( self:GetEnemy() ) ) and self:CanSee( ent ) )
                end )
                if #surroundings > 0 then self:AttackTarget( surroundings[ random( #surroundings ) ] ) end
            end
        end

        if self:InCombat() then
            if self.l_HasFlag then 
                if IsValid( self.l_CTF_CaptureZone ) then
                    self.l_movepos = self.l_CTF_CaptureZone:GetPos()
                end
            elseif IsValid( self.l_CTF_Flag ) and self.l_CTF_Flag:GetTeamName() != self.l_TeamName and self:IsInRange( self.l_CTF_Flag, 384 ) and self:CanSee( self.l_CTF_Flag ) then
                self.l_movepos = self.l_CTF_Flag:GetPos()
            end
        end
    end
    
    local function LambdaCanTarget( self, ent )
        if teamsEnabled:GetBool() and self:IsInMyTeam( ent ) == true then return true end
    end
    
    local function LambdaOnInjured( self, dmginfo )
        if !self.l_TeamName or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !IsValid( attacker ) or self:IsInMyTeam( attacker ) != true then return end

        if noFriendFire:GetBool() then return true end
    end
    
    local function LambdaOnOtherInjured( self, victim, dmginfo, tookDamage )
        if !tookDamage or !self.l_TeamName or self:InCombat() or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaIsValid( attacker ) then return end

        if self:IsInMyTeam( victim ) == true and self:CanTarget( attacker ) and ( self:IsInRange( attacker, 500 ) or self:CanSee( attacker ) ) then
            self:AttackTarget( attacker )
        elseif self:IsInMyTeam( attacker ) == true and self:CanTarget( victim ) and ( self:IsInRange( victim, 500 ) or self:CanSee( victim ) ) then
            self:AttackTarget( victim )
        end
    end
    
    local function LambdaOnBeginMove( self, pos )
        if !self.l_TeamName or !teamsEnabled:GetBool() then return end

        local state = self:GetState()
        if state != "Idle" and state != "FindTarget" then return end

        local validFlags, validZones = {}, {}
        for _, flag in ipairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
            if flag:GetTeamName() == self.l_TeamName then 
                validZones[ #validZones + 1 ] = flag.CaptureZone

                if ( !flag.IsAtHome or random( 1, 5 ) == 1 and !flag:GetIsCaptureZone() ) then
                    validFlags[ #validFlags + 1 ] = flag
                end
            elseif !flag:GetIsCaptureZone() then
                validFlags[ #validFlags + 1 ] = flag
            end
        end

        if !self.l_HasFlag then
            if #validFlags > 0 then
                if !IsValid( self.l_CTF_Flag ) or random( 1, 3 ) == 1 then
                    self.l_CTF_Flag = validFlags[ random( #validFlags ) ]
                end
                
                self:SetRun( true )
                self:RecomputePath( self.l_CTF_Flag:GetPos() + Vector( random( -50, 50 ), random( -50, 50 ), 0 ) )
                
                return
            end
        elseif #validZones > 0 then
            if !IsValid( self.l_CTF_CaptureZone ) or random( 1, 4 ) == 1 then
                self.l_CTF_CaptureZone = validZones[ random( #validZones ) ]
            end
           
            self:SetRun( true )
            self:RecomputePath( self.l_CTF_CaptureZone:GetPos() + Vector( random( -50, 50 ), random( -50, 50 ), 0 ) )

            return
        end

        if !IsValid( self.l_KOTH_Entity ) or random( 1, 10 ) == 1 then
            local kothEnts = ents_FindByClass( "lambda_koth_point" )
            if #kothEnts > 0 then self.l_KOTH_Entity = kothEnts[ random( #kothEnts ) ] end
        end

        if IsValid( self.l_KOTH_Entity ) then
            local area = GetNavArea( self.l_KOTH_Entity:GetPos(), 500 )
            self:SetRun( true )
            self:RecomputePath( IsValid( area ) and area:GetRandomPoint() or ( self.l_KOTH_Entity:GetPos() + VectorRand( -500, 500 ) ) )
            return
        end

        local rndDecision = random( 1, 100 )
        if rndDecision < 30 and stickTogether:GetBool() then
            local rndMember = self:GetRandomTeamMember()
            if IsValid( rndMember ) then
                local movePos = ( rndMember:GetPos() + VectorRand( -400, 400 ) )
                local area = GetNavArea( movePos, 400 )
                if IsValid( area ) then movePos = area:GetClosestPointOnArea( movePos ) end

                self:RecomputePath( movePos ) 
            end
        elseif rndDecision > 70 and huntDown:GetBool() and attackOthers:GetBool() then
            for _, ene in RandomPairs( ents_GetAll() ) do
                if LambdaIsValid( ene ) and self:IsInMyTeam( ene ) == false and self:CanTarget( ene ) then
                    local movePos = ( ene:GetPos() + VectorRand( -300, 300 ) )
                    local area = GetNavArea( movePos, 300 )
                    if IsValid( area ) then movePos = area:GetClosestPointOnArea( movePos ) end

                    self:RecomputePath( movePos )
                    break
                end
            end
        end
    end

    local function OnPlayerShouldTakeDamage( ply, attacker )
        if !attacker.IsLambdaPlayer or !teamsEnabled:GetBool() then return end

        local plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        if plyTeam == "" then return end

        local attTeam = attacker.l_TeamName
        if attTeam and attTeam != "" and plyTeam == attTeam and noFriendFire:GetBool() then return false end
    end
    
    local function OnPlayerInitialSpawn( ply )
        timer_Simple( 0, function()
            local teamID = LambdaTeams.RealTeams[ ply:GetInfo( "lambdaplayers_teamsystem_playerteam" ) ]
            if teamID and teamsEnabled:GetBool() then 
                ply:SetTeam( teamID )
                ply.l_IsInLambdaTeam = true
            end
        end )
    end

    hook.Add( "PlayerSpawnedNPC", modulePrefix .. "OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
    hook.Add( "LambdaOnInitialize", modulePrefix .. "LambdaOnInitialize", LambdaOnInitialize )
    hook.Add( "LambdaPostRecreated", modulePrefix .. "LambdaPostRecreated", LambdaPostRecreated )
    hook.Add( "LambdaOnThink", modulePrefix .. "OnThink", LambdaOnThink )
    hook.Add( "LambdaCanTarget", modulePrefix .. "OnCanTarget", LambdaCanTarget )
    hook.Add( "LambdaOnInjured", modulePrefix .. "OnInjured", LambdaOnInjured )
    hook.Add( "LambdaOnOtherInjured", modulePrefix .. "OnOtherInjured", LambdaOnOtherInjured )
    hook.Add( "LambdaOnBeginMove", modulePrefix .. "OnBeginMove", LambdaOnBeginMove )
    hook.Add( "PlayerShouldTakeDamage", modulePrefix .. "OnPlayerShouldTakeDamage", OnPlayerShouldTakeDamage )
    hook.Add( "PlayerInitialSpawn", modulePrefix .. "OnPlayerInitialSpawn", OnPlayerInitialSpawn )

end

if ( CLIENT ) then

    local LocalPlayer = LocalPlayer
    local GetConVar = GetConVar
    local PlaySound = surface.PlaySound
    local file_Find = file.Find
    local string_Replace = string.Replace
    local string_EndsWith = string.EndsWith
    local plyTeam = GetConVar( "lambdaplayers_teamsystem_playerteam" )
    local DrawText = draw.DrawText
    local SimpleTextOutlined = draw.SimpleTextOutlined
    local UIScale = GetConVar( "lambdaplayers_uiscale" )
    local ScrW = ScrW
    local ScrH = ScrH
    local teamNameTraceTbl = {}
    local TraceLine = util.TraceLine
    local GetLambdaPlayers = GetLambdaPlayers
    local table_IsEmpty = table.IsEmpty
    local AddHalo = halo.Add
    local vgui = vgui
    local SortedPairs = SortedPairs
    local AddTextChat = chat.AddText
    local defTeamClr = Vector( 1, 1, 1 )

    net.Receive( "lambda_teamsystem_playclientsound", function()
        local myTeam = plyTeam:GetString()
        if myTeam == "" then return end

        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end

        local teamBased = net.ReadBool()
        if teamBased then
            local targetTeam, attackTeam = net.ReadString(), net.ReadString()
            if myTeam != targetTeam and attackTeam != myTeam then return end
            cvarName = cvarName .. ( myTeam != targetTeam and "ally" or "enemy" )
        end

        local cvar = GetConVar( cvarName )
        if !cvar then return end

        local sndPath = cvar:GetString()
        if sndPath == "" then return end

        if string_EndsWith( sndPath, "*" ) then
            local dirFiles = file_Find( "sound/" .. sndPath, "GAME" )
            sndPath = string_Replace( sndPath .. dirFiles[ random( #dirFiles ) ], "*", "" )
        end

        PlaySound( sndPath )
    end )

    local function OnPlayerLambdaTeamChanged( name, oldVal, newVal )
        net.Start( "lambda_teamsystem_setplayerteam" )
            net.WriteEntity( LocalPlayer() )
            net.WriteString( newVal )
        net.SendToServer()
    end
    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_playerteam", modulePrefix .. "OnPlayerLambdaTeamChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_playerteam", OnPlayerLambdaTeamChanged, modulePrefix .. "OnPlayerLambdaTeamChanged" )

    local function GetLambdaTeamName( self )
        local tName = self:GetNW2String( "lambda_teamname" )
        if !tName or tName == "" then tName = self:GetNWString( "lambda_teamname" ) end
        return tName
    end

    local function GetLambdaTeamColor( self )
        local colorvec = self:GetNW2Vector( "lambda_teamcolor", false )
        if !colorvec then colorvec = self:GetNWVector( "lambda_teamcolor" ) end
        return colorvec:ToColor()
    end

    local function LambdaGetDisplayColor( self )
        if teamsEnabled:GetBool() and GetLambdaTeamName( self ) != "" then return GetLambdaTeamColor( self ) end
    end

    local function OnPreDrawHalos()
        local myTeam = plyTeam:GetString()
        if myTeam == "" or !drawHalo:GetBool() or !teamsEnabled:GetBool() then return end

        for _, tm in ipairs( GetLambdaPlayers() ) do
            local tmTeam = GetLambdaTeamName( tm )
            if tmTeam == "" or tmTeam != myTeam or tm:GetIsDead() or !tm:IsBeingDrawn() then continue end            
            AddHalo( { tm }, GetLambdaTeamColor( tm ), 3, 3, 1, true, false )
        end
    end

    local function OnHUDPaint()
        if teamsEnabled:GetBool() then
            local ply = LocalPlayer()
            
            local traceEnt = ply:GetEyeTrace().Entity
            if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
                local entTeam = GetLambdaTeamName( traceEnt )
                if entTeam != "" then 
                    local color = GetLambdaTeamColor( traceEnt )
                    
                    local friendTbl = traceEnt.l_friends
                    local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )

                    DrawText( "Team: " .. entTeam, "lambdaplayers_displayname", ( ScrW() / 2 ), ( ScrH() / height ) + LambdaScreenScale( 1 + UIScale:GetFloat() ), color, TEXT_ALIGN_CENTER ) 
                end
            end

            local myTeam = plyTeam:GetString()
            if myTeam == "" or !drawTeamName:GetBool() then return end

            teamNameTraceTbl.start = ply:EyePos()
            teamNameTraceTbl.filter = { ply }

            for _, tm in ipairs( GetLambdaPlayers() ) do
                local tmTeam = GetLambdaTeamName( tm )
                if tmTeam != "" and tmTeam == myTeam and !tm:GetIsDead() and tm:IsBeingDrawn() then
                    local textPos = ( tm:GetPos() + tm:GetUp() * 96 )
                    teamNameTraceTbl.endpos = textPos
                    teamNameTraceTbl.filter[ 2 ] = tm
                    if !TraceLine( teamNameTraceTbl ).Hit then
                        local drawPos = textPos:ToScreen()
                        DrawText( myTeam .. "'s Member", "lambdaplayers_displayname", drawPos.x, drawPos.y, GetLambdaTeamColor( tm ), TEXT_ALIGN_CENTER )
                    end
                end
            end
        end
    end

    hook.Add( "HUDPaint", modulePrefix .. "OnHUDPaint", OnHUDPaint )
    hook.Add( "PreDrawHalos", modulePrefix .. "OnPreDrawHalos", OnPreDrawHalos )
    hook.Add( "LambdaGetDisplayColor", modulePrefix .. "LambdaGetDisplayColor", LambdaGetDisplayColor )

    ---

    local function OpenLambdaTeamPanel( ply )
        local frame = LAMBDAPANELS:CreateFrame( "Lambda Team Editor", 500, 400 )

        local leftpanel = LAMBDAPANELS:CreateBasicPanel( frame )
        leftpanel:SetSize( 175, 200 )
        leftpanel:Dock( LEFT )

        local teamlist = vgui.Create( "DListView", leftpanel )
        teamlist:Dock( FILL )
        teamlist:AddColumn( "Teams", 1 )

        local CompileSettings
        local ImportProfile

        local jsonFile = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
        if jsonFile then
            for k, v in SortedPairs( jsonFile ) do
                local line = teamlist:AddLine( k )
                line:SetSortValue( 1, v )
            end
        end

        local function UpdateTeamLine( name, newinfo )
            for _, v in ipairs( teamlist:GetLines() ) do
                local info = v:GetSortValue( 1 )
                if info.name == name then v:SetSortValue( 1, newinfo ) return end
            end

            local line = teamlist:AddLine( newinfo.name )
            line:SetSortValue( 1, newinfo )
        end

        function teamlist:DoDoubleClick( id, line )
            ImportTeam( line:GetSortValue( 1 ) )
            PlaySound( "buttons/button15.wav" )
        end

        function teamlist:OnRowRightClick( id, line )
            local info = line:GetSortValue( 1 )
            local conmenu = DermaMenu( false, leftpanel )

            conmenu:AddOption( "Delete " .. info.name .. "?", function()
                LAMBDAFS:RemoveVarFromKVFile( "lambdaplayers/teamlist.json", info.name, "json" )
                PlaySound( "buttons/button15.wav" )
                AddTextChat( "Deleted " .. info.name .. " from your Team List.")
                teamlist:RemoveLine( id )
            end )
            conmenu:AddOption( "Cancel", function() end )
        end

        local rightpanel = LAMBDAPANELS:CreateBasicPanel( frame )
        rightpanel:SetSize( 310, 200 )
        rightpanel:Dock( RIGHT )

        LAMBDAPANELS:CreateLabel( "Team Name", rightpanel, TOP )
        local teamname = LAMBDAPANELS:CreateTextEntry( rightpanel, TOP, "Enter the team's name here" )

        LAMBDAPANELS:CreateLabel( "Team Color", rightpanel, TOP )
        local teamcolor = LAMBDAPANELS:CreateColorMixer( rightpanel, TOP )

        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Save Team", function()
            local compiledinfo = CompileSettings()
            if !compiledinfo then return end

            AddTextChat( "Saved " .. compiledinfo.name .. " to your Team List!" )
            PlaySound( "buttons/button15.wav" )

            UpdateTeamLine( compiledinfo.name, compiledinfo, true )
            
            local jsonTbl = { [ compiledinfo.name ] = compiledinfo }
            LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/teamlist.json", jsonTbl, "json" ) 
            
            UpdateTeamDataList( jsonTbl )
            net.Start( "lambda_teamsystem_updateteamdatalist" )
                net.WriteString( util.TableToJSON( jsonTbl ) )
            net.SendToServer()
        end )

        CompileSettings = function()
            if teamname:GetText() == "" then 
                AddTextChat( "No name is set for this team!" ) 
                PlaySound( "buttons/button10.wav" )
                return 
            end

            local infotable = {
                name = teamname:GetText(),
                color = teamcolor:GetVector()
            }

            return infotable
        end

        ImportTeam = function( infotable )
            teamname:SetText( infotable.name or "" )
            teamcolor:SetVector( infotable.color or defTeamClr )
        end
    end

    RegisterLambdaPanel( "Teams", "Opens a panel that allows you to create and edit lambda teams.", OpenLambdaTeamPanel )

end