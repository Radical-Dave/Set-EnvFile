#Set-StrictMode -Version Latest
#####################################################
# Set-EnvFile
#####################################################
<#PSScriptInfo

.VERSION 0.1

.GUID b608274b-5a28-47cb-b291-d43f78b1f2cb

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell token regex

.LICENSEURI https://github.com/Radical-Dave/Set-EnvFile/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/Set-EnvFile

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#

.DESCRIPTION
 PowerShell Script to Set-EnvFile from EnvironmentVariables (APPSETTING_)

.PARAMETER source
Source paths to process

#>
[CmdletBinding(SupportsShouldProcess)]
Param([Parameter(Mandatory=$false)][string]$path)
begin {
	$Global:ErrorActionPreference = 'Stop'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))	
	$PSScriptVersion = (Test-ScriptFileInfo -Path $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty Version)
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "#####################################################"
	if (!$path) {$path = ".env" }
	Write-Host "# $PSScriptRoot/$PSScriptName $($PSScriptVersion):$action $data $path called by:$PSCallingScript" -ForegroundColor White
	$Global:envFileChanged = $false
	$Global:envFileSettings = @{}
	$envvars = @{}
	if ($path -and (Test-Path $path)) {
		try {			
			$content = Get-Content $path -ErrorAction Stop
			Write-Verbose "Parsed .env file:$path"
			foreach ($line in $content) {
				#Write-Verbose "line:$line"
				if([string]::IsNullOrWhiteSpace($line)){ continue } #Skipping empty line
				if($line.StartsWith("#")){ continue } #ignore comments
				if($line -like "*:=*"){
					$kvp = $line -split ":=",2            
					$key = $kvp[0].Trim()
					$value = "{0};{1}" -f $kvp[1].Trim(),[System.Environment]::GetEnvironmentVariable($key)
				} elseif ($line -like "*=:*"){
					$kvp = $line -split "=:",2            
					$key = $kvp[0].Trim()
					$value = "{1};{0}" -f $kvp[1].Trim(),[System.Environment]::GetEnvironmentVariable($key)
				} else {
					$kvp = $line -split "=",2            
					$key = $kvp[0].Trim()
					$value = $kvp[1].Trim()
					#$value = "{0};{1}" -f $kvp[1].Trim(),[System.Environment]::GetEnvironmentVariable($key)
				}
				#if ($PSCmdlet.ShouldProcess("environment variable $key", "set value $value")) {            
				#	#[Environment]::SetEnvironmentVariable($key, $value, "Process") | Out-Null
				#	Write-Host "# settings[${setting.Key}]:${$settings[$setting.Key]}"
				#	$settings[$key] = $value
				#}
				if ($key) {
					$Global:envFileSettings[$key] = $value
					#Write-host "# settings.count=$($settings.Keys.Count)"
				}
			}
			Write-Verbose "Parsed .env file:$path contains $($Global:envFileSettings.Keys.Count) settings"
			$envvars = Get-ChildItem env:APPSETTING_*
			#Write-Verbose "envvars:$envvars"
			Write-Host "Checking ENV: $($envvars.Length)"
			$envvars.foreach({
				$key = $_.Key -replace "APPSETTING_", ""
				$value = $_.Value
				if ($Global:envFileSettings[$key] -ne $value) {
					if (!$Global:envFileChanged) {$Global:envFileChanged = $true}
					$Global:envFileSettings[$key] = $value
					Write-Host "# $($key) changed! $($Global:envFileSettings[$key])-$($value)"
				} else {
					Write-Host "# $($key) no change - $($Global:envFileSettings[$key])"
				}
			})
			Write-Verbose "Checking ENV variables: $($envvars.Count)"
		}
		catch {
			Write-Error "ERROR $PSScriptName $($path): $_" -InformationVariable results
		}
	}
}
process {
	try {
		#Write-Verbose "Parsed .env file:$path contains ${$Global:envFileSettings.Count}"
		#Write-Host "Parsed .env file:$path contains ${$Global:envFileSettings.Count}"
		if(!$settings -and 1 -eq 2) { # Using Get-Az* commands
			if ($SlotName) { # Determine whether or not to work on app-level or slot-level
				$settingsGetter = { (Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $WebAppName -Slot $SlotName).SiteConfig.AppSettings }
				$settingsSetter = { param ($newSettings) Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $WebAppName -Slot $SlotName -AppSettings $newSettings }
			} else {
				$settingsGetter = { (Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName).SiteConfig.AppSettings }
				$settingsSetter = { param ($newSettings) Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -AppSettings $newSettings }
			}
		}
		if (1 -eq 2) {			
			$oldSettings = &$settingsGetter
			$newSettings = @{ }
			$oldSettings | ForEach-Object { $newSettings[$_.Name] = $_.Value }
			$props = Get-Content $SettingsFile | ConvertFrom-StringData
			$props.Keys | ForEach-Object { $newSettings[$_] = $props.$_ }
			&$settingsSetter $newSettings
		}

		#on azure windows app service:
		#ASPNETCORE_ENVIRONMENT=Production
		#computername=ps1sdwk00092E
		#branch=master
		#deployment_branch=master
		#RepoUrl
		#SCM_GIT_EMAIL=windowsazure
		#SCM_GIT_USERNAME=windowsazure
		#ScmType=VSO
		#WEBSITE_CURRENT_STAMPNAME=waws-prod-blu-315
		#WEBSITE_HOME_STAMPNAME=waws-prod-blu-315
		#WEBSITE_RESOURCE_GROUP=tests-app-repo-test
		#WEBSITE_SCM_ALWAYS_ON_ENABLED=1
		#WEBSITE_SCM_SEPARATE_STATUS=1
		#WEBSITE_SITE_NAME=tests-app-repo-test-app


		if (1 -eq 2) {
			#if (!$path) {$path = Get-Location}
			if (!$paths) {
				$currLocation = Get-Location
				$paths = @((Split-Path $profile -Parent),$PSScriptRoot,("$currLocation" -ne "$PSScriptRoot" ? $currLocation : ''))
			}
			$paths.foreach({
				$path = $_
				if ($path) {
					#if ($path.GetType() -ne 'Array') {Write-Verbose "wow:$($path.GetType())"}
					if (Test-Path "$path\*.env*") {
						Get-ChildItem -Path "$path\*.env*" | Foreach-Object {
							try {
								$f = $_
								$content = (Get-Content $f.FullName) # -join [Environment]::NewLine # -Raw
								$content | ForEach-Object {
									if (-not ($_ -like '#*') -and ($_ -like '*=*')) {
										$sp = $_.Split('=')
										[System.Environment]::SetEnvironmentVariable($sp[0], $sp[1])
									}
								}
							}
							catch {
								throw "ERROR $PSScriptName $path-$f"
							}
						}
					} else {
						Write-Verbose "skipped:$p no *.env* files found"
					}
				}
			})
		}
		if ($Global:envFileChanged) {
			Write-Host "Changes detected!"
			#$Global:envFileSettings.GetEnumerator() | ForEach-Object {Write-Output "$($_.Key)=$($_.Value)"} | Set-Content -Path "$($path)2"
			$Global:envFileSettings.Keys | ForEach-Object {if ($_){Write-Output "$_=$($Global:envFileSettings[$_])"}} | Set-Content -Path "$($path)"
			Write-Host "Changes detected! $path - saved"
		} else {
			Write-Host "NO Changes detected!"
		}
	}
	catch {
		Write-Error "ERROR $PSScriptName $($path): $_" -InformationVariable results
	}
}
