$ErrorActionPreference = 'Stop'
Write-Host "Downloading foundry_nightly_win32_amd64.zip..."
Invoke-WebRequest -Uri "https://github.com/foundry-rs/foundry/releases/download/nightly/foundry_nightly_win32_amd64.zip" -OutFile "foundry.zip"
Write-Host "Extracting..."
Expand-Archive -Path "foundry.zip" -DestinationPath "." -Force
Write-Host "Removing temporary zip..."
Remove-Item -Path "foundry.zip"
Write-Host "Done! Checking forge version:"
& .\forge.exe --version
