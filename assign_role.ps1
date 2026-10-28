# assign_role.ps1 - Assign master role to user with phone 605676002 in Supabase
$envFile = "C:\Users\usuario\proyectos\lokitrono\.env"
# Load .env variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^([^#=]+)=?(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path Env:$key -Value $value
    }
}
$supabaseUrl = $Env:SUPABASE_URL
$serviceKey = $Env:SUPABASE_SERVICE_ROLE_KEY
$phone = "605676002"
$filter = "phone=eq.$phone"
$getUrl = "$supabaseUrl/rest/v1/authorized_users?$filter"
$headers = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey" }
# Get existing user
try {
    $existing = Invoke-RestMethod -Method GET -Uri $getUrl -Headers $headers -ErrorAction Stop
} catch {
    Write-Error "Failed to query Supabase: $_"
    exit 1
}
if ($existing -and $existing.Count -gt 0) {
    Write-Host "User exists, updating role to master..."
    $body = @{ role = "master" } | ConvertTo-Json -Depth 2
    $patchRes = Invoke-RestMethod -Method PATCH -Uri $getUrl -Headers ($headers + @{ 'Content-Type' = 'application/json' }) -Body $body -ErrorAction Stop
    Write-Host "Update response:`n$(ConvertTo-Json $patchRes)"
} else {
    Write-Host "User not found, inserting new record..."
    $postUrl = "$supabaseUrl/rest/v1/authorized_users"
    $body = @{ phone = $phone; role = "master" } | ConvertTo-Json -Depth 2
    $postRes = Invoke-RestMethod -Method POST -Uri $postUrl -Headers ($headers + @{ 'Content-Type' = 'application/json' }) -Body $body -ErrorAction Stop
    Write-Host "Insert response:`n$(ConvertTo-Json $postRes)"
}
