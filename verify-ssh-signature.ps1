# verify-ssh-signature.ps1
$ErrorActionPreference = 'Stop'

# Work in the script folder
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Here

# Inputs
$ImagePath = Join-Path $Here 'image.png'
$SigPath   = Join-Path $Here 'image.png.lec.sig'
$ASPath    = Join-Path $Here 'allowed_signers'
$OutPath   = Join-Path $Here 'verify_lecturer.txt'

$SignerIdentity = 'usuario'
$Namespace      = 'robot_dreams'
$LecturerPubKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOcy16pJ1D/W9taRhguy9ui17uZ1tsxteYtFhMV5iWnO ruslan.kiyanchuk@gmail.com'

$SignatureBlock = @'
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg5zLXqknUP9b21pGGC7L26LXu5n
W2zG15i0WExXmJac4AAAAMcm9ib3RfZHJlYW1zAAAAAAAAAAZzaGE1MTIAAABTAAAAC3Nz
aC1lZDI1NTE5AAAAQCabuXryeHf3RY7qFI/sACI+1ldE8INgrrFWpObWbLCjwvtvDBTfMT
aOHFN00UghzhkD+qmXLZZl1y2FkNtdhQM=
-----END SSH SIGNATURE-----
'@

if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
  throw 'ssh-keygen not found. Install/enable OpenSSH or use WSL.'
}
if (-not (Test-Path $ImagePath)) {
  throw "image.png not found here: $ImagePath"
}

# Write files
$SignatureBlock | Set-Content -Path $SigPath -Encoding ascii -NoNewline
"$SignerIdentity namespaces=""$Namespace"" $LecturerPubKey" | `
  Set-Content -Path $ASPath -Encoding ascii -NoNewline

# Verify (pipe RAW bytes!)
Get-Content $ImagePath -Encoding Byte -ReadCount 0 |
ssh-keygen -Y verify `
  -f $ASPath `
  -I $SignerIdentity `
  -n $Namespace `
  -s $SigPath |
Tee-Object -FilePath $OutPath

Write-Host ""
Write-Host "Done."
Write-Host "Signature file: $SigPath"
Write-Host "allowed_signers: $ASPath"
Write-Host "Verification output: $OutPath"
