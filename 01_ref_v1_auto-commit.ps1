$script:currentDir = Get-Location
$script:mainDir = Split-Path -Path $script:currentDir -Parent

function Get-EnvVariable {
    param (
        [string]$Variable
    )
    $envPath = Join-Path -Path $script:mainDir -ChildPath ".env"
    if (!(Test-Path -Path $envPath)) {
        throw "The .env file does not exist at path $envPath"
    }
    $envVars = @{}
    Get-Content -Path $envPath | ForEach-Object {
        $key, $value = $_ -split '=', 2
        $envVars[$key] = $value
    }
    if (-not $envVars.ContainsKey($Variable)) {
        throw "Variable $Variable not found in .env file"
    }
    return $envVars[$Variable]
}

function Get-ProjectName {
    $projectDirPath = $script:currentDir
    $name = Split-Path -Path $projectDirPath -Parent
    $name = Split-Path -Path $name -Leaf
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw "Project name could not be determined."
    }
    return $name
}

function Get-GitHubUserName {
    try {
        $user = Get-EnvVariable -Variable "GITHUBUSERNAME"
        if ([string]::IsNullOrWhiteSpace($user)) {
            throw "GitHub username is null or white space."
        }
        return $user
    } catch {
        Write-Error "Error in Get-GitHubUserName: $_"
        Exit 1
    }
}


function Get-GitHubProjectURL {
    param (
        [switch]$CreateIfNotExist
    )
    try {
        $githubUsername = Get-GitHubUserName
        $projectName = Get-ProjectName
        return "https://github.com/$githubUsername/$projectName.git"
    } catch {
        Write-Error "Error in Get-GitHubProjectURL: $_"
        Exit 1
    }
}

function Set-GitRemoteURL {
    param (
        [string]$newURL
    )
    Set-Location -Path $script:mainDir
    $gitFile = Join-Path -Path $script:mainDir -ChildPath ".git"
    if (!(Test-Path $gitFile)) {
        throw "This directory is not a Git repository."
    }
    $newURL = Get-GitHubProjectURL
    & git remote set-url origin $newURL
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set the new remote URL."
    }
    Write-Host "Remote URL updated to $newURL"
    Set-Location -Path $script:currentDir
}


function Get-GitInit {
    try {
        Set-Location -Path $script:mainDir
        $gitFile = "$mainDir/.git"
        $repoURL = Get-GitHubProjectURL -CreateIfNotExist

        if (!(Test-Path $gitFile)) {
            Clear-Host
            & git init
            & git add .
            & git commit -m "Initial commit"
            if ($LASTEXITCODE -ne 0 -or $null -eq $repoURL -or $repoURL -like "*Repository not found*") {
                & git remote add origin $repoURL
                & git push -u origin master
            } else {
                Write-Host "Repository does not exist and was not created."
            }
        }
        Set-Location -Path $script:currentDir
    }
    catch {
        Write-Error "Error in Get-GitInit: $_"
        Exit 1
    }
}

function Get-GitUpdate {
    try {
        $gitPullOutput = & git pull origin master --allow-unrelated-histories  2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "git pull failed with message: $gitPullOutput"
        }

        $gitAddOutput = & git add . 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "git add failed with message: $gitAddOutput"
        }

        $commitMessage = "Update some codes"
        $gitCommitOutput = & git commit -m $commitMessage 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($gitCommitOutput -match 'nothing to commit') {
                Write-Host "No changes to commit."
            } else {
                throw "git commit failed with message: $gitCommitOutput"
            }
        } else {
            Write-Host "Commit successful: $gitCommitOutput"
        }

        # Push changes
        $gitPushOutput = & git push -u origin master 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($gitPushOutput -match 'Everything up-to-date' -or $gitPushOutput -match 'To https:') {
                Write-Host "Git push status: $gitPushOutput"
            } else {
                throw "git push encountered an issue: $gitPushOutput"
            }
        } else {
            Write-Host "Git push successful. Output: $gitPushOutput"
        }
    }
    catch {
        Write-Error "Error in Get-GitUpdate: $_"
        Exit 1
    }
}
function Update-NewRepo {
    try {
        # Add all changes to git
        $gitAddOutput = & git add . 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "git add failed with message: $gitAddOutput"
        }

        # Commit changes
        $commitMessage = "Initial commit"
        $gitCommitOutput = & git commit -m $commitMessage 2>&1
        if ($LASTEXITCODE -ne 0) {
            # Assuming you want to log the situation where there are no changes to commit
            if ($gitCommitOutput -match 'nothing to commit') {
                Write-Host "No changes to commit."
            } else {
                throw "git commit failed with message: $gitCommitOutput"
            }
        } else {
            Write-Host "Commit successful: $gitCommitOutput"
        }

        # Push changes
        $gitPushOutput = & git push -u origin master 2>&1
        if ($LASTEXITCODE -ne 0) {
            # Check if the output is the 'Everything up-to-date' message or matches the specific project URL
            if ($gitPushOutput -match 'Everything up-to-date' -or $gitPushOutput -match 'To https:') {
                # It's a regular message, not an error
                Write-Host "Git push status: $gitPushOutput"
            } else {
                # It's an unexpected message, handle it as an error
                throw "git push encountered an issue: $gitPushOutput"
            }
        } else {
            # The operation was successful (based on the exit code)
            Write-Host "Git push successful. Output: $gitPushOutput"
        }
    }
    catch {
        Write-Error "Error in Update-NewRepo: $_"
        Exit 1
    }
}

function Update-ProjectRepo {
    try {
        Clear-Host
        $gitFile = Join-Path -Path $script:mainDir -ChildPath ".git"
        Set-Location -Path $script:mainDir

        if (Test-Path $gitFile) {
            $repoURL = Get-GitHubProjectURL
            & git ls-remote --exit-code -h $repoURL | Out-Null
            if ($LASTEXITCODE -ne 0 -or $null -eq $repoURL -or $repoURL -like "*Repository not found*") { 
                Write-Host "Repository does not exist in GitHub"
                Start-Sleep -Seconds 2
                Write-Host "Proceed to create a new repository..."
                Start-Sleep -Seconds 3
                Remove-Item -Path $gitFile  -Recurse -Force
                Get-GitInit
                Get-ProjectRepo
                Update-NewRepo
            } else {
                Get-GitUpdate
            }
        } else {
            Remove-Item -Path $gitFile  -Recurse -Force
            Get-GitInit
            Update-NewRepo
        }
        Set-Location -Path $script:currentDir
    }
    catch {
        Write-Error "Error in Update-ProjectRepo: $_"
        Exit 1
    }
}

# Main execution
Update-ProjectRepo