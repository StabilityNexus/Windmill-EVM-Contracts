# Setup & Run Windmill Exchange locally
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     WINDMILL EXCHANGE — LOCAL DEVELOPMENT LAUNCHER       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Set environment variables
$env:PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
$env:FOUNDRY_DISABLE_NIGHTLY_WARNING = "1"

# 2. Deploy contracts to Anvil
Write-Host "[1/3] Deploying smart contracts to Anvil (http://127.0.0.1:8545)..." -ForegroundColor Yellow
.\forge.exe script script/DeployAnvilSimple.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# 3. Fund Account #1 with USDC for testing counter orders
Write-Host "[2/3] Funding Account #1 (0x7099...79C8) with 500,000 USDC..." -ForegroundColor Yellow
.\cast.exe send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "transfer(address,uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 500000000000 --private-key $env:PRIVATE_KEY --rpc-url http://127.0.0.1:8545

# 4. Launch Web UI
Write-Host "[3/3] Starting Windmill WebUI on http://localhost:3000..." -ForegroundColor Green
Set-Location Windmill-EVM-WebUI
cmd /c "npm run dev -- -p 3000"
