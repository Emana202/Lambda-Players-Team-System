AddCSLuaFile()

if ( CLIENT ) then

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" }
	}

	language.Add("tool.lambda_teamsystem_spawnpointmaker", "Lambda Spawnpoint Maker")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.name", "Lambda Spawnpoint Maker")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.desc", "Creates a team spawnpoint that Lambda teams will use to spawn in")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.left", "Fire onto a surface to create spawnpoint or fire near a existing spawnpoint to change its team")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.right", "Fire near a existing spawnpoint to remove it")

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambda_teamsystem_spawnpointmaker"
TOOL.ClientConVar = {
	[ "spawnteam" ] = ""
}

function TOOL:LeftClick( tr )
	local spawnTeam = self:GetClientInfo( "spawnteam" )
	if !spawnTeam or spawnTeam == "" then
		return false
	end

	if ( SERVER ) then
		local changedTeam = false
		for _, ent in ipairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaSpawnpoint then 
				ent:SetSpawnTeam( spawnTeam )
				ent:SetTeamColor( LambdaTeams:GetTeamColor( spawnTeam ) )
				changedTeam = true; break
			end
		end

		if !changedTeam then
			local spawnPoint = ents.Create( "lambda_teamspawnpoint" )
			spawnPoint:SetPos( tr.HitPos )

			local spawnAng = ( tr.StartPos - tr.HitPos ):Angle().y
			spawnPoint:SetAngles( Angle( 0, spawnAng, 0 ) )

			spawnPoint.SpawnTeam = spawnTeam

			spawnPoint:Spawn()

			local addname = ( teamName != "" and teamName or spawnPoint:GetCreationID() )
			undo.Create("Lambda Spawnpoint " .. addname )
				undo.SetPlayer( self:GetOwner() )
				undo.AddEntity( spawnPoint )
			undo.Finish("Lambda Spawnpoint " .. addname )

			self:GetOwner():AddCleanup( "sents", spawnPoint )
    	end
    end

    return true
end

function TOOL:RightClick(tr)
	if ( SERVER ) then
		for _, ent in ipairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaSpawnpoint then 
				ent:Remove() 
			end
		end
	end

	return true
end

function TOOL.BuildCPanel( panel )
    local combo = panel:ComboBox( "Spawn Team", "lambda_teamsystem_spawnpointmaker_spawnteam" )
    for k, v in pairs( LambdaTeams.TeamOptions ) do if k != "None" then combo:AddChoice( k, v ) end end
	panel:ControlHelp( "The team that this spawnpoint will belong to." )

	local refresh = vgui.Create( "DButton" )
	panel:AddItem( refresh )
	refresh:SetText( "Refresh Team List" )

	function refresh:DoClick()
		combo:Clear()
		local teamData = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
	    for k, _ in pairs( teamData ) do combo:AddChoice( k, k ) end
	end
end