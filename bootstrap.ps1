
Write-Host Bootstrapping. Ensuring Chocolatey and Puppet are installed...

$choco = choco

If ($choco -like "Please run chocolatey*")
	{
		Write-Host Chocolatey already installed. Updating...
		choco update
	}
Else
	{
		Write-Host Installing Chocolatey...
		#@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
	}

$puppet = puppet	
	
If ($puppet -like "See 'puppet help' for help on available puppet subcommands")
	{
		Write-Host Puppet already installed. Updating...
		choco update puppet
	}
Else
	{
		Write-Host Installing Puppet...
		choco install puppet
	}