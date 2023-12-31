$currentDir = Get-Location
$mainDir = Split-Path -Path $currentDir -Parent

function Get-EnvVariable {
    param (
        [string]$Variable
    )
    try {
        $envPath = Join-Path -Path $mainDir -ChildPath ".env"
        if (!(Test-Path -Path $envPath)) {
            throw "The .env file does not exist at path $envPath"
        }
        $envVars = @{}
        Get-Content -Path $envPath | ForEach-Object {
            $key, $value = $_ -split '='
            $envVars[$key] = $value
        }
        return $envVars[$Variable]
    } catch {
        Write-Error $_.Exception.Message
        Exit 1
    }
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


function Get-ProjectName {
    try {
        $projectDirPath = $currentDir
        $name = Split-Path -Path $projectDirPath -Parent
        $name = Split-Path -Path $name -Leaf
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "Project name could not be determined."
        }
        return $name
    } catch {
        Write-Error "Error in Get-ProjectName: $_"
        Exit 1
    }
}


function Get-ProjectRepo {
    try {
        $projectName = Get-ProjectName
        Clear-Host
        & gh repo create --public $projectName
    }
    catch {
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
    }
}


function Get-GitHubProjectURL {
    param (
        [switch]$CreateIfNotExist
    )
    try {
        $githubUsername = Get-GitHubUserName
        $projectName = Get-ProjectName
        $URL = "https://github.com/$githubUsername/$projectName.git"
        return $URL
    } catch {
        Write-Error "Error in Get-GitHubProjectURL: $_"
        Exit 1
    }
}


function Get-LogDir {
    try {
        if ([string]::IsNullOrEmpty($envPath) -or !(Test-Path -Path $envPath)) {
            $logDir = "logs"
        } else {
            $logDir = Get-EnvVariable -envPath $envPath -variableName "AUTOLOGDIR"
        }
        $logDirPath = Join-Path -Path $currentDir -ChildPath $logDir
        return $logDirPath
    } catch {
        Write-Error "Failed to define full paths: $_"
        Exit 1
    }
}


function Get-LogFiles {
    param (
        [string]$Path,
        [string]$ScriptName,
        [string]$LogType
    )
    $logPath = Get-LogDir
    try {
        $logFileName = "${logType}_log_${scriptName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $logFilePath = Join-Path -Path $logPath -ChildPath $logFileName
        return $logFilePath
    } catch {
        Write-Error "Failed to create log file: $_"
        Exit 1
    }
}


function Get-LogErrorHandling {
    param (
        [string]$errorMessage,
        [string]$logFilePath
    )
    $logPath = Get-LogDir 
    try {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -ItemType Directory -Force -Path $logPath
        }
        $logFilePath = Get-LogFiles -Path $logDirPath -ScriptName "auto-git" -LogType "error"
        $errorMessage = "An error occurred: $errorMessage"
        $errorMessage | Out-File -Append -FilePath $logFilePath
    } catch {
        Write-Error "Failed to write to log file: $_"
    }
    Write-Error $errorMessage
}


function Get-GitInit {
    try {
        Set-Location -Path $mainDir
        $gitFile = "$mainDir/.git"
        $repoURL = Get-GitHubProjectURL -CreateIfNotExist

        if (!(Test-Path $gitFile)) {
            Clear-Host
            & git init
            & git add .
            & git commit -m "Initial commit"
            if ($repoURL -ne $false) {
                & git remote add origin $repoURL
                & git push -u origin master
            } else {
                Write-Host "Repository does not exist and was not created."
            }
        }
        Set-Location -Path $currentDir
    }
    catch {
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
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
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
    }
}


function Set-GitRemoteURL {
    param (
        [string]$newURL
    )
    try {
        $gitFile = "$mainDir/.git"
        if (!(Test-Path $gitFile)) {
            throw "This directory is not a Git repository."
        }

        Set-Location -Path $mainDir
        & git remote set-url origin $newURL
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set the new remote URL."
        }
        Write-Host "Remote URL updated to $newURL"
    }
    catch {
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
    }
    finally {
        Set-Location -Path $currentDir
    }
}


function Update-NewRepo {
    try {
        $gitAddOutput = & git add . 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "git add failed with message: $gitAddOutput"
        }

        $commitMessage = "Initial commit"
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
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
    }
}


function Update-ProjectRepo {
    try {
        Clear-Host
        $gitFile = "$mainDir/.git"
        Set-Location -Path $mainDir

        if ((Test-Path $gitFile)) {

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
        Set-Location -Path $currentDir
    }
    catch {
        $logDirPath = Get-LogDir
        $errorMessage = $_.Exception.Message
        Get-LogErrorHandling -errorMessage $errorMessage -logFilePath $logDirPath
    }
}

Update-ProjectRepo