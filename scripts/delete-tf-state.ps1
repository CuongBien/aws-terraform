# Quick script to delete Terraform Cloud state
# Replace YOUR_TOKEN with actual token from https://app.terraform.io/app/settings/tokens

$TF_TOKEN = "YOUR_TOKEN_HERE"
$ORG = "CBien"
$WORKSPACE = "aws-terraform"

# Get workspace ID
$headers = @{
    "Authorization" = "Bearer $TF_TOKEN"
    "Content-Type" = "application/vnd.api+json"
}

$workspace_response = Invoke-RestMethod -Uri "https://app.terraform.io/api/v2/organizations/$ORG/workspaces/$WORKSPACE" -Headers $headers
$workspace_id = $workspace_response.data.id

Write-Host "Workspace ID: $workspace_id"

# Lock workspace
Invoke-RestMethod -Method POST -Uri "https://app.terraform.io/api/v2/workspaces/$workspace_id/actions/lock" -Headers $headers -Body '{"reason":"Clearing state"}' | Out-Null
Write-Host "Workspace locked"

# Get current state version
$state_response = Invoke-RestMethod -Uri "https://app.terraform.io/api/v2/workspaces/$workspace_id/current-state-version" -Headers $headers
$state_id = $state_response.data.id

Write-Host "Current state ID: $state_id"

# Delete state (dangerous!)
Invoke-RestMethod -Method DELETE -Uri "https://app.terraform.io/api/v2/state-versions/$state_id" -Headers $headers
Write-Host "State deleted"

# Unlock workspace
Invoke-RestMethod -Method POST -Uri "https://app.terraform.io/api/v2/workspaces/$workspace_id/actions/unlock" -Headers $headers | Out-Null
Write-Host "Workspace unlocked"

Write-Host ""
Write-Host "To actually delete state, uncomment the DELETE line in script"
