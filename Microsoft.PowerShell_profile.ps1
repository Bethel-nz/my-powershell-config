##Invoke-Expression (&starship init powershell)
oh-my-posh init pwsh --config 'C:\Users\DELL\Documents\Powershell\zash.omp.json' | Invoke-Expression

Import-Module z
Import-Module -Name Terminal-Icons

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias g git
Set-Alias editor code
Set-Alias open ii


#Functions
function mods {
    Invoke-Expression "cmd /c mods $args"
}
  function zip-file {
      [CmdletBinding()]
      param (
        [string]$Target,
        [switch]$IncludeSubdirectories
      )


      $ParentPath = Split-Path -Path $Target -Parent

           $ZipFilePath = Join-Path -Path $ParentPath -ChildPath ("{0}.zip" -f $Target)

           $params = @{
        Path = $Target
        DestinationPath = $ZipFilePath
        CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
      }


      if ($IncludeSubdirectories) {
        $params.IncludeBaseDirectory = $true
        $params.Filter = "*.*"
      }
      else {

        $params.RootPath = "documents"
        $params.PrefixPath = "documents"
      }


      Compress-Archive @params
    }

function nxt {
    param(
        [string]$Action,
        [string]$AppName,
	  [switch]$yarn
    )

   if (-not $Action) { # Check if no action was provided
        Write-Host "Available nxt commands:"
        Write-Host "  new | new <project-name>  -  Creates a new Next.js project"
        Write-Host "  start               -  Starts the development server"
        Write-Host "  build               -  Builds the project for production"
        Write-Host "  preview             -  Previews the production build"
        Write-Host "  lint                -  Runs the configured linter"
        Write-Host "  generate            -  Runs 'npm prisma generate' and 'npm prisma db push'"
        return
    }

    if (($Action -eq "dev") -or ($Action -eq "build") -or ($Action -eq "start") -or ($Action -eq "lint") -or ($Action -eq "generate")) {
        if (-not (Test-Path "./package.json")) {
            Write-Error "This doesn't seem like a Next.js project. Please navigate to your Next.js project directory or use 'nxt new <project-name>' to create one."
            return
        }
    }



    switch ($Action ) {
        "new" {
            if ($yarn) {
                yarn create next-app $AppName
            } else {
                npx create-next-app@latest $AppName
            }
        }

        "dev" {
            if ($yarn) { yarn dev } else { npm run dev }
        }

        "build" {
            if ($yarn) { yarn build } else { npm run build }
        }

        "preview" {
            if ($yarn) { yarn start } else { npm run start }
        }

        "lint" {
            if ($yarn) { yarn lint } else { npm run lint }
        }

        "prisma" {
            if ($yarn) {
                if ($args -contains "gen-only") {
                    yarn prisma generate
                } elseif ($args -contains "push-only") {
                    yarn prisma db push
                } else {
                    yarn prisma generate
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Prisma generate failed."
                        return
                    }
                    yarn prisma db push
                }
            } else {
                if ($args -contains "gen-only") {
                    npx prisma generate
                } elseif ($args -contains "push-only") {
                    npx prisma db push
                } else {
                    npx prisma generate
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Prisma generate failed."
                        return
                    }
                    npx prisma db push
                }
            }
        }
        default{

            Write-Error "Invalid action. Choose: 'nxt new <project-name>', 'nxt start', 'nxt build','nxt preview', 'nxt lint' or 'nxt prisma - nxt prisma | nxt prisma gen-only nxt prisma push-only'"
        }
        }
    }

function ws(){
return (z "@workspace")
}
function projects(){
return (z "@projects")
}

function update_log {
    param(
        [string]$command,
        [string]$fullPath
    )

    $logFile = "C:\temp\whereis_log.txt"

    "$command,$fullPath" | Out-File -FilePath $logFile -Append
}

function get_from_log {
    param(
        [string]$command
    )

    $logFile = "C:\temp\whereis_log.txt"

    if (-not (Test-Path $logFile)) {
        return $null
    }

    $logEntries = Get-Content $logFile
    foreach ($entry in $logEntries) {
        $cmd, $path = $entry.Split(",")
        if ($cmd -eq $command) {
            return $path
        }
    }

    return $null
}

function whereis {
    param(
        [string]$command
    )

    if (-not $command) {
        Write-Output "Please provide a command name."
        return
    }

    Import-Module Wmi

    $twoDaysAgo = (Get-Date).AddDays(-2)
    $userPath = "C:\Users\Bethel"

    # -- Check Log --
    $fullPath = get_from_log $command
    if ($fullPath) {
        Write-Output "File found: $fullPath"
        Write-Output "Template command: cd $fullPath"
        return
    }

    # --- C Drive Search (Limited scope) ---
    $cDriveSearchFolders = "Documents", "Music", "Downloads", "Desktop", "Videos"
    foreach ($folder in $cDriveSearchFolders) {
        $searchPath = Join-Path $userPath $folder
        $searchResults = Get-ChildItem -Path $searchPath -Filter "*$command*" -Recurse -ErrorAction SilentlyContinue |
                         Select-Object Name, FullName, CreationTime

        if ($searchResults) {
            $searchResults | Format-Table -AutoSize
            return # Stop searching if found on C drive
        }
    }

    # --- E Drive Search (Full search, update log) ---
    $eDrive = "E:\"
    $searchResults = Get-ChildItem -Path $eDrive -Filter "*$command*" -Recurse -ErrorAction SilentlyContinue |
                     Select-Object Name, FullName, CreationTime, LastWriteTime

    # Update Log with New or Recently Modified Files
    if ($searchResults) {
        $searchResults | Where-Object { $_.CreationTime -ge $twoDaysAgo -or $_.LastWriteTime -ge $twoDaysAgo} |
            ForEach-Object {
                update_log $_.Name $_.FullName
            }
    }

    # --- Search Results ---
    if ($searchResults) {
        $searchResults | Format-Table -AutoSize
    } else {
        Write-Output "'$command' and similar files/folders not found in any drives."
    }
}



function touch {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )

    # Ensure the directory structure exists
    $dir = Split-Path -Path $Path -Parent
    if (!(Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Create or update the file
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType File -Path $Path | Out-Null
    } else {
        (Get-Item -Path $Path).LastWriteTime = Get-Date
    }
}

