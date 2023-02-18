local ipairs = ipairs
local IsValid = IsValid
local pairs = pairs
local random = math.random
local table_Count = table.Count
local team_SetUp = team.SetUp
local team_SetColor = team.SetColor
local net = net
local ents_GetAll = ents.GetAll
local ents_FindByClass = ents.FindByClass
local table_Copy = table.Copy
local timer_Simple = timer.Simple
local file_Exists = file.Exists
local modulePrefix = "Lambda_TeamSystem_"
local defaultPlyClr = Color( 255, 255, 100 )

local ignorePlys = GetConVar( "ai_ignoreplayers" )

if SERVER and !file_Exists( "lambdaplayers/teamlist.json", "DATA" ) then
    LAMBDAFS:WriteFile( "lambdaplayers/teamlist.json", {
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
    }, "json", false )
end

LambdaTeams = LambdaTeams or {}

function LambdaTeams:UpdateData()
    local teamList = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
    if table_Count( teamList ) == 0 then print( "LAMBDA TEAM SYSTEM WARNING: THERE ARE NO TEAMS REGISTERED!" ) return end
    LambdaTeams.TeamData = teamList
    
    if ( CLIENT ) then
        LambdaTeams.TeamOptions = { [ "None" ] = "" }
        LambdaTeams.TeamOptionsRandom = { [ "None" ] = "", [ "Random" ] = "random" }

        for k, _ in pairs( LambdaTeams.TeamData ) do 
            LambdaTeams.TeamOptions[ k ] = k 
            LambdaTeams.TeamOptionsRandom[ k ] = k
        end
    end

    LambdaTeams.RealTeams = LambdaTeams.RealTeams or {}
    LambdaTeams.RealTeamCount = LambdaTeams.RealTeamCount or 0

    for k, v in pairs( LambdaTeams.TeamData ) do 
        if !LambdaTeams.RealTeams[ k ] then
            local teamID = ( LambdaTeams.RealTeamCount + 1 )
            team_SetUp( teamID, k, ( v.color and v.color:ToColor() or defaultPlyClr ), false )
            
            LambdaTeams.RealTeams[ k ] = teamID
            LambdaTeams.RealTeamCount = teamID
        else
            team_SetColor( LambdaTeams.RealTeams[ k ], ( v.color and v.color:ToColor() or defaultPlyClr ) )
        end
    end
end

LambdaTeams:UpdateData()

---

local teamsEnabled  = CreateLambdaConvar( "lambdaplayers_teamsystem_enable", 0, true, false, false, "Enables the work of the module.", 0, 1, { name = "Enable Team System", type = "Bool", category = "Team System" } )
local mwsTeam       = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_spawnteam", "", true, false, false, "The team the newly spawned Lambda Players from MWS should be assigned into.", 0, 1, { name = "Spawn Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "MWS" } )
local incNoTeams    = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_includenoteams", 0, true, false, false, "When spawning a Lambda Player from MWS with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "MWS" }  )
local mwsTeamLimit  = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to zero for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "MWS" }  )
CreateLambdaConvar( "lambdaplayers_teamsystem_lambdateam", "", true, true, true, "The team the newly spawned Lambda Players should be assigned into.", 0, 1, { name = "Lambda Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "Team System" } )
local playerTeam    = CreateLambdaConvar( "lambdaplayers_teamsystem_playerteam", "", true, true, true, "The lambda team you are currently assigned to.", 0, 1, { name = "Player Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System" }  )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_updateteamlist", function( ply ) 
    LambdaTeams:UpdateData()

    for _, v in ipairs( _LAMBDAConVarSettings ) do
        if v.name == "Player Team" then v.options = LambdaTeams.TeamOptions end
        if v.name == "Lambda Team" then v.options = LambdaTeams.TeamOptionsRandom end
    end

    ply:ConCommand( "spawnmenu_reload" )
end, true, "Refreshes the team list. Use this after editting teams in the team panel.", { name = "Refresh Team List", category = "Team System" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_includenoteams", 0, true, true, true, "When spawning a Lambda Player with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "Team System" }  )
local teamLimit     = CreateLambdaConvar( "lambdaplayers_teamsystem_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to zero for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "Team System" }  )
local attackOthers  = CreateLambdaConvar( "lambdaplayers_teamsystem_attackotherteams", 0, true, false, false, "If Lambda Players should immediately start attacking the members of other teams at their sight.", 0, 1, { name = "Attack On Sight", type = "Bool", category = "Team System" } )
local noFriendFire  = CreateLambdaConvar( "lambdaplayers_teamsystem_nofriendlyfire", 1, true, false, false, "If Lambda Players shouldn't be able to damage their teammates.", 0, 1, { name = "No Friendly Fire", type = "Bool", category = "Team System" } )
local stickTogether = CreateLambdaConvar( "lambdaplayers_teamsystem_sticktogether", 1, true, false, false, "If Lambda Players should stick together with their teammates.", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )
local huntDown      = CreateLambdaConvar( "lambdaplayers_teamsystem_huntdownotherteams", 0, true, false, false, "If Lambda Players should hunt down the members of other teams. 'Attack On Sight' option should be enabled for it to work.", 0, 1, { name = "Hunt Down Enemy Teams", type = "Bool", category = "Team System" } )
local drawTeamName  = CreateLambdaConvar( "lambdaplayers_teamsystem_drawteamname", 1, true, true, false, "Enables drawing team names above your Lambda teammates.", 0, 1, { name = "Draw Team Names", type = "Bool", category = "Team System" } )
local drawHalo      = CreateLambdaConvar( "lambdaplayers_teamsystem_drawhalo", 1, true, true, false, "Enables drawing halos around you Lambda Teammates", 0, 1, { name = "Draw Halos", type = "Bool", category = "Team System" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerate", 0.2, true, false, false, "The speed rate of capturing the KOTH Points.", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - KOTH" } )
local kothCapRange = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerange", 500, true, false, false, "How close player should be to start capturing the point.", 100, 1000, { name = "Capture Range", type = "Slider", decimals = 0, category = "Team System - KOTH" } )

local kothIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_enabled", 1, true, true, false, "If your team's captured KOTH point should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - KOTH" } )
local kothIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - KOTH" } )
local kothIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - KOTH" } )
local kothIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - KOTH" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_returntime", 15, true, false, false, "The time Lambda Flag can be in dropped state before returning to its capture zone.", 0, 120, { name = "Time Before Returning", type = "Slider", decimals = 0, category = "Team System - CTF" } )

local ctfIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_enabled", 1, true, true, false, "If your team's dropped flag or enemy flag carried by your teammate should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - CTF" } )
local ctfIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - CTF" } )
local ctfIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - CTF" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_enemy", "lambdaplayers/ctf/flagsteal.mp3", true, true, false, "The sound that plays when your team picks up enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_ally", "lambdaplayers/ctf/ourflagstole.mp3", true, true, false, "The sound that plays when enemy team picks up your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_ally", "lambdaplayers/ctf/flagcapture.mp3", true, true, false, "The sound that plays when your team has captured enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_enemy", "lambdaplayers/ctf/ourflagcaptured.mp3", true, true, false, "The sound that plays when enemy team has captured your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_ondrop", "lambdaplayers/ctf/flagdropped.mp3", true, true, false, "The sound that plays when the CTF Flag is dropped.", 0, 1, { name = "Sound - On Flag Drop", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onreturn", "lambdaplayers/ctf/flagreturn.mp3", true, true, false, "The sound that plays when the CTF Flag has returned to its base.", 0, 1, { name = "Sound - On Flag Return", type = "Text", category = "Team System - CTF" } )

---

function LambdaTeams:GetTeamColor( teamName, realColor )
    local data = LambdaTeams.TeamData[ teamName ]
    return ( data and data.color and ( !realColor and data.color or data.color:ToColor() ) )
end

function LambdaTeams:GetPlayerTeam( ply )
    if !IsValid( ply ) then return end
    local plyTeam = nil

    if ply.IsLambdaPlayer then
        if ( CLIENT ) then
            plyTeam = ply:GetNW2String( "lambda_teamname" )
            if !plyTeam or plyTeam == "" then plyTeam = ply:GetNWString( "lambda_teamname" ) end
        end
        if ( SERVER ) then
            plyTeam = ply.l_TeamName
        end
    elseif ply:IsPlayer() then
        if ( CLIENT ) then
            plyTeam = playerTeam:GetString()
        end
        if ( SERVER ) then
            plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        end
    end

    return ( plyTeam != "" and plyTeam )
end

function LambdaTeams:AreTeammates( ent, target )
    if !IsValid( ent ) or !IsValid( target ) then return end

    local entTeam = LambdaTeams:GetPlayerTeam( ent )
    if !entTeam then return end

    local targetTeam = LambdaTeams:GetPlayerTeam( target )
    if !targetTeam then return end

    return ( entTeam == targetTeam )
end

function LambdaTeams:GetTeamCount( teamName )
    local count = 0
    for _, v in ipairs( ents_GetAll() ) do
        if LambdaTeams:GetPlayerTeam( v ) == teamName and ( !v:IsPlayer() or !ignorePlys:GetBool() ) then count = count + 1 end
    end
    return count
end

---

if ( SERVER ) then

    util.AddNetworkString( "lambda_teamsystem_playclientsound" )
    util.AddNetworkString( "lambda_teamsystem_setplayerteam" )
    util.AddNetworkString( "lambda_teamsystem_updatedata" )
    util.AddNetworkString( "lambda_teamsystem_sendupdateddata" )

    local CurTime = CurTime
    local GetNearestNavArea = navmesh.GetNearestNavArea
    local VectorRand = VectorRand
    local RandomPairs = RandomPairs
    local table_Random = table.Random
    local tobool = tobool

    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )

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

    net.Receive( "lambda_teamsystem_updatedata", function()
        LambdaTeams:UpdateData()
        net.Start( "lambda_teamsystem_sendupdateddata" ); net.Broadcast()
    end )

    local function OnTeamSystemDisable( name, oldVal, newVal )
        for _, ply in ipairs( ents_GetAll() ) do
            if IsValid( ply ) then
                if ply.IsLambdaPlayer then
                    local teamID = LambdaTeams.RealTeams[ ply.l_TeamName ]
                    if teamID and teamsEnabled:GetBool() and ply:GetTeam() == 0 then
                        ply:SetTeam( teamID )
                        if ply.l_TeamColor then ply:SetPlyColor( ply.l_TeamColor:ToVector() ) end
                    elseif ply:GetTeam() != 0 then
                        ply:SetTeam( 0 )
                        if ply.l_PlyNoTeamColor then ply:SetPlyColor( ply.l_PlyNoTeamColor ) end
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

    local function SetTeamToLambda( lambda, team, rndNoTeams, limit, useMdls )
        if !teamsEnabled:GetBool() then return end

        local teamTbl = LambdaTeams.TeamData
        if limit and limit > 0 then
            teamTbl = table_Copy( teamTbl )
            for k, _ in pairs( teamTbl ) do
                if LambdaTeams:GetTeamCount( k ) < limit then continue end
                teamTbl[ k ] = nil
            end
        end

        local teamData
        if team == "random" then
            if rndNoTeams then
                local teamCount = table_Count( teamTbl )
                if random( 1, teamCount + 1 ) > teamCount then return end
            end

            teamData = table_Random( teamTbl )
        else
            teamData = teamTbl[ team ]
        end
        if !teamData then return end

        local name = teamData.name
        lambda:SetExternalVar( "l_TeamName", name )
        lambda:SetNW2String( "lambda_teamname", name )
        lambda:SetNWString( "lambda_teamname", name )

        if useMdls == nil then useMdls = true end
        if useMdls then
            local plyMdls = teamData.playermdls
            if plyMdls and #plyMdls > 0 then 
                lambda:SetModel( plyMdls[ random( #plyMdls ) ] ) 

                lambda.l_BodyGroupData = {}
                if rndBodyGroups:GetBool() then
                    for _, v in ipairs( lambda:GetBodyGroups() ) do
                        local subMdls = #v.submodels
                        if subMdls == 0 then continue end 

                        local rndID = random( 0, subMdls )
                        lambda:SetBodygroup( v.id, rndID )
                        lambda.l_BodyGroupData[ v.id ] = rndID
                    end

                    local skinCount = lambda:SkinCount()
                    if skinCount > 0 then lambda:SetSkin( random( 0, skinCount - 1 ) ) end
                end
            end
        end

        local color = teamData.color
        lambda:SetExternalVar( "l_TeamColor", color:ToColor() )
        lambda:SetPlyColor( color )
        lambda:SetNW2Vector( "lambda_teamcolor", color )
        lambda:SetNWVector( "lambda_teamcolor", color )

        local teamID = LambdaTeams.RealTeams[ name ]
        if teamID then lambda:SetTeam( teamID ) end
    end

    local function OnPlayerSpawnedNPC( ply, npc )
        if !npc.IsLambdaPlayer then return end
        SetTeamToLambda( npc, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt() )
    end

    local function LambdaOnInitialize( self )
        self.l_NextEnemyTeamSearchT = CurTime() + 1.0
        self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )

        self:SimpleTimer( 0.1, function()
            if self.l_TeamName then return end

            if self.l_MWSspawned then
                self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                SetTeamToLambda( self, mwsTeam:GetString(), incNoTeams:GetBool(), mwsTeamLimit:GetInt() )
            else
                local ply = self:GetCreator()
                if IsValid( ply ) then
                    self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                    SetTeamToLambda( self, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt(), false ) 
                end
            end

            if self.l_TeamColor then self:SetPlyColor( self.l_TeamColor:ToVector() ) end
        end, true )
    end

    local function LambdaPostRecreated( self )
        if !self.l_TeamName then return end
        self:SetNW2String( "lambda_teamname", self.l_TeamName )
        self:SetNWString( "lambda_teamname", self.l_TeamName )

        local teamID = LambdaTeams.RealTeams[ self.l_TeamName ]
        if teamID then self:SetTeam( teamID ) end

        if !self.l_TeamColor then return end
        self.l_TeamColor = Color( self.l_TeamColor.r, self.l_TeamColor.g, self.l_TeamColor.b )

        self:SetNW2Vector( "lambda_teamcolor", self.l_TeamColor:ToVector() )
        self:SetNWVector( "lambda_teamcolor", self.l_TeamColor:ToVector() )

        if self.l_PlyNoTeamColor and !teamsEnabled:GetBool() then
            self:SetPlyColor( self.l_PlyNoTeamColor )
        else
            self:SetPlyColor( self.l_TeamColor:ToVector() )
        end
    end

    local function LambdaOnThink( self )
        if !teamsEnabled:GetBool() then return end

        if CurTime() > self.l_NextEnemyTeamSearchT then
            self.l_NextEnemyTeamSearchT = CurTime() + 1.0

            local ene = self:GetEnemy()
            local kothEnt = self.l_KOTH_Entity
            if ( self.l_TeamName and attackOthers:GetBool() or IsValid( kothEnt ) ) and ( !self:InCombat() or !self:CanSee( ene ) ) then
                local surroundings = self:FindInSphere( nil, 2000, function( ent )
                    if LambdaIsValid( ent ) and ( !LambdaIsValid( ene ) or self:GetRangeSquaredTo( ent ) < self:GetRangeSquaredTo( ene ) ) and self:CanTarget( ent ) and self:CanSee( ent ) then
                        local areTeammates = LambdaTeams:AreTeammates( self, ent )
                        if IsValid( kothEnt ) and kothEnt == ent.l_KOTH_Entity and ent:IsInRange( kothEnt, 1000 ) and !areTeammates then
                            return true
                        end
                        return ( areTeammates == false )
                    end
                end )

                if #surroundings > 0 then 
                    self:AttackTarget( surroundings[ random( #surroundings ) ] ) 
                end
            end
        end

        local flag = self.l_CTF_Flag
        if IsValid( flag ) and self:InCombat() and ( self.l_HasFlag or !flag.IsLambdaCaptureZone and flag:GetTeamName() != self.l_TeamName and self:IsInRange( flag, 384 ) and self:CanSee( flag ) ) then
            self.l_movepos = flag:GetPos()
        end
    end
    
    local function LambdaCanTarget( self, ent )
        if self.l_HasFlag and ent.IsLambdaPlayer and ( !ent:InCombat() or ent:GetEnemy() != self ) then return true end
        if teamsEnabled:GetBool() and LambdaTeams:AreTeammates( self, ent ) then return true end
    end
    
    local function LambdaOnInjured( self, dmginfo )
        if !self.l_TeamName or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !IsValid( attacker ) or !LambdaTeams:AreTeammates( self, attacker ) then return end

        if noFriendFire:GetBool() then return true end
    end
    
    local function LambdaOnOtherInjured( self, victim, dmginfo, tookDamage )
        if !tookDamage or !self.l_TeamName or self:InCombat() or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaIsValid( attacker ) then return end

        if LambdaTeams:AreTeammates( self, victim ) and self:CanTarget( attacker ) and ( self:IsInRange( victim, 500 ) or self:CanSee( victim ) ) then
            self:AttackTarget( attacker )
        elseif LambdaTeams:AreTeammates( self, attacker ) and self:CanTarget( victim ) and ( self:IsInRange( attacker, 500 ) or self:CanSee( attacker ) ) then
            self:AttackTarget( victim )
        end
    end
    
    local function LambdaOnBeginMove( self, pos )
        if !teamsEnabled:GetBool() then return end

        local state = self:GetState()
        if state != "Idle" and state != "FindTarget" then return end

        local kothEnt = self.l_KOTH_Entity
        if !IsValid( kothEnt ) or kothEnt:GetIsCaptured() and random( 1, ( kothEnt:GetCapturerName() == kothEnt:GetCapturerTeamName( self ) and 4 or 8 ) ) == 1 then
            local kothEnts = ents_FindByClass( "lambda_koth_point" )
            if #kothEnts > 0 then kothEnt = kothEnts[ random( #kothEnts ) ] end
        end
        if IsValid( kothEnt ) then
            self.l_KOTH_Entity = kothEnt
            local capRange = kothCapRange:GetInt()
            local area = GetNearestNavArea( kothEnt:GetPos(), false, capRange )
            self:SetRun( random( 1, 3 ) != 1 and !self:IsInRange( kothEnt, capRange ) )
            self:RecomputePath( IsValid( area ) and area:GetRandomPoint() or ( kothEnt:GetPos() + VectorRand( -capRange, capRange ) ) )
            return
        end

        if self.l_TeamName then
            local ctfFlag = self.l_CTF_Flag
            if !IsValid( ctfFlag ) or random( 1, 5 ) == 1 or self.l_HasFlag and !ctfFlag.IsLambdaCaptureZone or !self.l_HasFlag and ctfFlag.IsLambdaCaptureZone then
                for _, flag in RandomPairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
                    if IsValid( flag ) then
                        if !self.l_HasFlag then 
                            if !flag:GetIsCaptureZone() and ( flag:GetTeamName() != self.l_TeamName and flag:GetIsPickedUp() or !flag:GetIsAtHome() or random( 1, 3 ) == 1 ) then
                                ctfFlag = flag
                                break
                            end
                        elseif flag:GetTeamName() == self.l_TeamName and IsValid( flag.CaptureZone ) then
                            ctfFlag = flag.CaptureZone
                            break
                        end
                    end
                end
            end
            if IsValid( ctfFlag ) then
                self:RecomputePath( ctfFlag:GetPos() + Vector( random( -50, 50 ), random( -50, 50 ), 0 ) )
                self:SetRun( true )
                self.l_CTF_Flag = ctfFlag
                return
            end

            local rndDecision = random( 1, 100 )
            if rndDecision < 30 and stickTogether:GetBool() then
                for _, ent in RandomPairs( ents_GetAll() ) do
                    if ent != self and LambdaTeams:AreTeammates( self, ent ) and ent:Alive() and ( !ent:IsPlayer() or !ignorePlys:GetBool() ) then
                        local movePos = ( ( ent.l_issmoving and ( ( isentity( self.l_movepos ) and IsValid( self.l_movepos ) ) and self.l_movepos:GetPos() or self.l_movepos ) or ent:GetPos() ) + VectorRand( -400, 400 ) )
                        local area = GetNearestNavArea( movePos, false, 400 )
                        if IsValid( area ) then movePos = area:GetClosestPointOnArea( movePos ) end

                        self:RecomputePath( movePos )
                        break 
                    end
                end
            elseif rndDecision > 70 and huntDown:GetBool() and attackOthers:GetBool() then
                for _, ent in RandomPairs( ents_GetAll() ) do
                    if ent != self and LambdaTeams:AreTeammates( self, ent ) == false and ent:Alive() and self:CanTarget( ent ) then
                        local movePos = ( ent:GetPos() + VectorRand( -300, 300 ) )
                        local area = GetNearestNavArea( movePos, false, 300 )
                        if IsValid( area ) then movePos = area:GetClosestPointOnArea( movePos ) end

                        self:RecomputePath( movePos )
                        break
                    end
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
    local surface = surface
    local PlayClientSound = surface.PlaySound
    local file_Find = file.Find
    local string_Replace = string.Replace
    local string_EndsWith = string.EndsWith
    local DrawText = draw.DrawText
    local SimpleTextOutlined = draw.SimpleTextOutlined
    local ScrW = ScrW
    local ScrH = ScrH
    local TraceLine = util.TraceLine
    local table_IsEmpty = table.IsEmpty
    local AddHalo = halo.Add
    local CreateVGUI = vgui.Create
    local spairs = SortedPairs
    local AddTextChat = chat.AddText
    local DermaMenu = DermaMenu
    local table_Merge = table.Merge
    local AddNotification = notification.AddLegacy
    local Clamp = math.Clamp
    local LerpVector = LerpVector
    local vec_white = Vector( 1, 1, 1 )
    local GetAllValidPlayerModels = player_manager.AllValidModels
    local TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName

    local uiScale = GetConVar( "lambdaplayers_uiscale" )

    local nameTrTbl = {}
    local hudTrTbl = { filter = function( ent ) if ent:IsWorld() then return true end end }

    local ctfFlagCircle = Material( "lambdaplayers/icon/team_flag_circle.png" )
    local kothFlagCircle = Material( "lambdaplayers/icon/team_flag_square.png" )

    net.Receive( "lambda_teamsystem_playclientsound", function()
        local plyTeam = playerTeam:GetString()
        if plyTeam == "" then return end

        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end

        local teamBased = net.ReadBool()
        if teamBased then
            local targetTeam, attackTeam = net.ReadString(), net.ReadString()
            if plyTeam != targetTeam and attackTeam != plyTeam then return end
            cvarName = cvarName .. ( plyTeam != targetTeam and "ally" or "enemy" )
        end

        local cvar = GetConVar( cvarName )
        if !cvar then return end

        local sndPath = cvar:GetString()
        if sndPath == "" then return end

        if string_EndsWith( sndPath, "*" ) then
            local dirFiles = file_Find( "sound/" .. sndPath, "GAME" )
            sndPath = string_Replace( sndPath .. dirFiles[ random( #dirFiles ) ], "*", "" )
        end

        PlayClientSound( sndPath )
    end )

    local function OnPlayerLambdaTeamChanged( name, oldVal, newVal )
        net.Start( "lambda_teamsystem_setplayerteam" )
            net.WriteEntity( LocalPlayer() )
            net.WriteString( newVal )
        net.SendToServer()
    end
    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_playerteam", modulePrefix .. "OnPlayerLambdaTeamChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_playerteam", OnPlayerLambdaTeamChanged, modulePrefix .. "OnPlayerLambdaTeamChanged" )

    local function GetLambdaTeamColor( self )
        local colorvec = self:GetNW2Vector( "lambda_teamcolor", false )
        if !colorvec then colorvec = self:GetNWVector( "lambda_teamcolor" ) end
        return colorvec:ToColor()
    end

    local function LambdaGetDisplayColor( self )
        local teamName = LambdaTeams:GetPlayerTeam( self )
        if teamName and teamsEnabled:GetBool() then return LambdaTeams:GetTeamColor( teamName, true ) end
    end

    local function OnPreDrawHalos()
        local plyTeam = playerTeam:GetString()
        if plyTeam == "" or !drawHalo:GetBool() or !teamsEnabled:GetBool() then return end

        for _, ent in ipairs( GetLambdaPlayers() ) do
            local entTeam = LambdaTeams:GetPlayerTeam( ent )
            if entTeam and entTeam == plyTeam and !ent:GetIsDead() and ent:IsBeingDrawn() then
                AddHalo( { ent }, LambdaTeams:GetTeamColor( entTeam, true ), 3, 3, 1, true, false )
            end
        end
    end

    local function OnHUDPaint()
        if !teamsEnabled:GetBool() then return end
        local ply = LocalPlayer()
        local scrW, scrH = ScrW(), ScrH()

        local traceEnt = ply:GetEyeTrace().Entity
        if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
            local entTeam = LambdaTeams:GetPlayerTeam( traceEnt )
            if entTeam then 
                local friendTbl = traceEnt.l_friends
                local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )
                
                DrawText( "Team: " .. entTeam, "lambdaplayers_displayname", ( scrW / 2 ), ( scrH / height ) + LambdaScreenScale( 1 + uiScale:GetFloat() ), LambdaTeams:GetTeamColor( entTeam, true ), TEXT_ALIGN_CENTER ) 
            end
        end

        local plyTeam = playerTeam:GetString()
        if plyTeam == "" then return end

        local eyePos = ply:EyePos()

        if drawTeamName:GetBool() then
            nameTrTbl.start = eyePos
            nameTrTbl.filter = ply

            for _, ent in ipairs( GetLambdaPlayers() ) do
                local entTeam = LambdaTeams:GetPlayerTeam( ent )
                if entTeam and entTeam == plyTeam and !ent:GetIsDead() and ent:IsBeingDrawn() then
                    local textPos = ( ent:GetPos() + ent:GetUp() * 96 )
                    nameTrTbl.endpos = textPos
                    
                    local nameTr = TraceLine( nameTrTbl )
                    if !nameTr.Hit or nameTr.Entity == ent then
                        local drawPos = textPos:ToScreen()
                        DrawText( entTeam .. "'s Member", "lambdaplayers_displayname", drawPos.x, drawPos.y, LambdaTeams:GetTeamColor( entTeam, true ), TEXT_ALIGN_CENTER )
                    end
                end
            end
        end

        if kothIconEnabled:GetBool() then
            local fadeInStart = kothIconFadeStartDist:GetInt()
            local fadeOutEnd = kothIconFadeEndDist:GetInt()
            
            for _, koth in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
                if IsValid( koth ) and !koth:IsDormant() then
                    local iconPos = koth:WorldSpaceCenter()

                    hudTrTbl.start = eyePos
                    hudTrTbl.endpos = iconPos

                    if kothIconDrawVisible:GetBool() or TraceLine( hudTrTbl ).Hit then
                        surface.SetMaterial( kothFlagCircle )

                        local iconClr = koth:GetCapturerColor()
                        local capPerc = koth:GetCapturePercent()
                        if !koth:GetIsCaptured() then
                            iconClr = LerpVector( ( capPerc / 100 ), iconClr, koth:GetContesterColor() )
                        else
                            iconClr = LerpVector( ( ( 100 - capPerc ) / 100 ), iconClr, vec_white )
                        end

                        local drawAlpha = 0
                        local dist = eyePos:Distance( iconPos )
                        if dist < fadeInStart and dist > fadeOutEnd then
                            local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
                            drawAlpha = ( ( 1 - norm ) * 255 )
                        elseif dist < fadeOutEnd then
                            drawAlpha = 255
                        end
                        
                        iconClr = iconClr:ToColor()
                        surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )
                        
                        local angDiff = math.AngleDifference( ply:GetAimVector():GetNormalized():Angle().y, ( iconPos - eyePos ):GetNormalized():Angle().y )
                        if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
                        angDiff = angDiff - 90
                        
                        local offsetSize = 45
                        local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
                        local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

                        local screenPos = iconPos:ToScreen()
                        if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then 
                            screenPos.x = x
                        end
                        if screenPos.y < y or screenPos.y > scrH then 
                            screenPos.y = y 
                        elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then 
                            screenPos.y = ( scrH - y ) 
                        end

                        surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
                    end
                end
            end
        end

        if ctfIconEnabled:GetBool() then
            local fadeInStart = ctfIconFadeStartDist:GetInt()
            local fadeOutEnd = ctfIconFadeEndDist:GetInt()

            for _, flag in ipairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
                if IsValid( flag ) and !flag:IsDormant() then
                    local holder = flag:GetFlagHolderEnt()
                    if holder != ply and ( !flag:GetIsAtHome() and !flag:GetIsPickedUp() and flag:GetTeamName() == plyTeam or IsValid( holder ) and LambdaTeams:GetPlayerTeam( holder ) == plyTeam ) then
                        local iconPos = flag:WorldSpaceCenter()

                        hudTrTbl.start = eyePos
                        hudTrTbl.endpos = iconPos

                        if ctfIconDrawVisible:GetBool() or TraceLine( hudTrTbl ).Hit then
                            surface.SetMaterial( ctfFlagCircle )

                            local drawAlpha = 0
                            local dist = eyePos:Distance( iconPos )
                            if dist < fadeInStart and dist > fadeOutEnd then
                                local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
                                drawAlpha = ( ( 1 - norm ) * 255 )
                            elseif dist < fadeOutEnd then
                                drawAlpha = 255
                            end

                            local iconClr = flag:GetTeamColor():ToColor()
                            surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )
                            
                            local angDiff = math.AngleDifference( ply:GetAimVector():GetNormalized():Angle().y, ( iconPos - eyePos ):GetNormalized():Angle().y )
                            if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
                            angDiff = angDiff - 90
                            
                            local offsetSize = 45
                            local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
                            local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

                            local screenPos = iconPos:ToScreen()
                            if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then 
                                screenPos.x = x
                            end
                            if screenPos.y < y or screenPos.y > scrH then 
                                screenPos.y = y 
                            elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then 
                                screenPos.y = ( scrH - y ) 
                            end

                            surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
                        end
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
        if !ply:IsSuperAdmin() then 
            AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
            PlayClientSound( "buttons/button10.wav" ) 
            return 
        end

        local frame = LAMBDAPANELS:CreateFrame( "Lambda Team Editor", 550, 550 )

        local leftpanel = LAMBDAPANELS:CreateBasicPanel( frame )
        leftpanel:SetSize( 225, 200 )
        leftpanel:Dock( LEFT )

        local teamlist = CreateVGUI( "DListView", leftpanel )
        teamlist:Dock( FILL )
        teamlist:AddColumn( "Teams", 1 )

        local CompileSettings
        local ImportTeam
        local teams = {}

        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/teamlist.json", "json", function( data ) 
            if !data then return end

            table_Merge( teams, data )

            for k, v in spairs( data ) do
                local line = teamlist:AddLine( k )
                line:SetSortValue( 1, v )
            end
        end )

        local function UpdateTeamLine( teamname, newinfo )
            for _, v in ipairs( teamlist:GetLines() ) do
                local info = v:GetSortValue( 1 )
                if info.name == teamname then v:SetSortValue( 1, newinfo ) return end
            end

            local line = teamlist:AddLine( teamname )
            line:SetSortValue( 1, newinfo )
        end

        function teamlist:DoDoubleClick( id, line )
            ImportTeam( line:GetSortValue( 1 ) )
            PlayClientSound( "buttons/button15.wav" )
        end

        function teamlist:OnRowRightClick( id, line )
            local conmenu = DermaMenu( false, leftpanel )
            local info = line:GetSortValue( 1 )

            conmenu:AddOption( "Delete " .. info.name .. "?", function()
                LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/teamlist.json", info.name, "json" ) 
                AddTextChat( "Deleted " .. info.name .. " from the team list.")
                PlayClientSound( "buttons/button15.wav" )
                teamlist:RemoveLine( id )
            end )
            conmenu:AddOption( "Cancel", function() end )
        end

        local rightpanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
        rightpanel:SetSize( 310, 200 )

        local mainscroll = LAMBDAPANELS:CreateScrollPanel( rightpanel, false, FILL )
        
        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Validate Teams", function()
            local hasissue = false
            
            for k, v in pairs( teams ) do
                local mdls = v.playermdls
                if mdls and #mdls > 0 then
                    for _, v in ipairs( mdls ) do
                        if file_Exists( v, "GAME" ) then continue end
                        hasissue = true 
                        print( "Lambda Team Validation: Team " .. k .. " has an invalid playermodel! (" .. v .. ")" )
                    end
                end
            end

            AddTextChat( "Team Validation complete." .. ( hasissue and " Some issues were found. Check console for more details." or " No issues were found." ) )
        end )

        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Save Team", function()
            local compiledinfo = CompileSettings()
            if !compiledinfo then return end

            local alreadyexists = false
            for _, v in ipairs( teamlist:GetLines() ) do
                local info = v:GetSortValue( 1 )
                if info.name == compiledinfo.name then 
                    v:SetSortValue( 1, compiledinfo ) 
                    AddTextChat( "Edited team " .. compiledinfo.name .. "'s data." )
                    alreadyexists = true; break 
                end
            end
            if !alreadyexists then
                local line = teamlist:AddLine( compiledinfo.name )
                line:SetSortValue( 1, compiledinfo )
                AddTextChat( "Saved " .. compiledinfo.name .. " to the team list." )
            end

            PlayClientSound( "buttons/button15.wav" )
            LAMBDAPANELS:UpdateKeyValueFile( "lambdaplayers/teamlist.json", { [ compiledinfo.name ] = compiledinfo }, "json" )

            net.Start( "lambda_teamsystem_updatedata" ); net.SendToServer()
            net.Receive( "lambda_teamsystem_sendupdateddata", LambdaTeams.UpdateData )
        end )

        --

        LAMBDAPANELS:CreateLabel( "Team Name", mainscroll, TOP )
        local teamname = LAMBDAPANELS:CreateTextEntry( mainscroll, TOP, "Enter the team's name here" )

        LAMBDAPANELS:CreateLabel( "Team Color", mainscroll, TOP )
        local teamcolor = LAMBDAPANELS:CreateColorMixer( mainscroll, TOP )

        LAMBDAPANELS:CreateLabel( "Team Playermodels", mainscroll, TOP )
        local teampmlist = CreateVGUI( "DListView", mainscroll )
        teampmlist:SetSize( 300, 150 )
        teampmlist:Dock( TOP )
        teampmlist:AddColumn( "", 1 )

        function teampmlist:DoDoubleClick( id )
            teampmlist:RemoveLine( id )
            PlayClientSound( "buttons/button15.wav" )
        end

        LAMBDAPANELS:CreateButton( mainscroll, TOP, "Add Playermodel", function()
            local modelframe = LAMBDAPANELS:CreateFrame( "Team Playermodels", 800, 500 )
            
            local modelpanel = LAMBDAPANELS:CreateBasicPanel( modelframe, RIGHT )
            modelpanel:SetSize( 350, 200 )

            local modelpreview = CreateVGUI( "DModelPanel", modelframe )
            modelpreview:SetSize( 400, 100 )
            modelpreview:Dock( LEFT )

            modelpreview:SetModel( "" )

            function modelpreview:LayoutEntity( Entity )
                Entity:SetAngles( Angle( 0, RealTime() * 20 % 360, 0 ) )
            end

            local modelscroll = LAMBDAPANELS:CreateScrollPanel( modelpanel, false, FILL )
            local pmlist = CreateVGUI( "DIconLayout", modelscroll )
            pmlist:Dock( FILL )
            pmlist:SetSpaceY( 12 )
            pmlist:SetSpaceX( 12 )

            LAMBDAPANELS:CreateButton( modelpanel, BOTTOM, "Select Model", function()
                local selectedmodel = modelpreview:GetModel()

                if !selectedmodel or selectedmodel == "" then
                    AddNotification( "You didn't select any playermodel!", 1, 4 )
                    PlayClientSound( "buttons/button10.wav" )
                    return
                end
                for _, v in ipairs( teampmlist:GetLines() ) do
                    if v:GetValue( 1 ) == selectedmodel then
                        AddNotification( "Selected playermodel is already on the list!", 1, 4 )
                        PlayClientSound( "buttons/button10.wav" )
                        return
                    end
                end

                AddNotification( "Added " .. TranslateToPlayerModelName( selectedmodel ) ..  " to the playermodel list!", 0, 4 )
                PlayClientSound( "buttons/button15.wav" )

                teampmlist:AddLine( selectedmodel )
            end )

            local manualMdl = LAMBDAPANELS:CreateTextEntry( modelpanel, BOTTOM, "Enter here if you want to use a non-playermodel model" )

            function manualMdl:OnChange()
                local mdlPath = manualMdl:GetText()
                
                if file_Exists( mdlPath, "GAME" ) then
                    modelpreview:SetModel( mdlPath )
                    local mdlEnt = modelpreview:GetEntity()
                    if IsValid( mdlEnt ) then modelpreview:GetEntity().GetPlayerColor = function() return teamcolor:GetVector() end end
                end
            end

            for _, v in spairs( GetAllValidPlayerModels() ) do
                local modelbutton = pmlist:Add( "SpawnIcon" )
                modelbutton:SetModel( v )

                function modelbutton:DoClick()
                    manualMdl:SetValue( modelbutton:GetModelName() )
                    manualMdl:OnChange()
                end
            end
        end )

        CompileSettings = function()
            local name = teamname:GetText()
            if name == "" then 
                AddNotification( "No team name is set for this team!", 1, 4 )
                PlayClientSound( "buttons/button10.wav" )
                return 
            end

            local playermdls = nil
            local pmlist = teampmlist:GetLines()
            if #pmlist > 0 then
                playermdls = {}
                for _, v in ipairs( pmlist ) do playermdls[ #playermdls + 1 ] = v:GetValue( 1 ) end
            end

            local infotable = {
                name = name,
                color = teamcolor:GetVector(),
                playermdls = playermdls
            }

            return infotable
        end

        ImportTeam = function( infotable )
            teamname:SetText( infotable.name or "" )
            teamcolor:SetVector( infotable.color or vec_white )

            teampmlist:Clear()
            local mdls = infotable.playermdls
            if mdls then for _, v in ipairs( mdls ) do teampmlist:AddLine( v ) end end
        end
    end

    RegisterLambdaPanel( "LambdaTeam", "Opens a panel that allows you to create and edit lambda teams. You must be a Super Admin to use this panel. Make sure to refresh the team list after adding or deleting a team.", OpenLambdaTeamPanel )

end