# PowerShell script for scanning CloudFormation templates using cfn-lint and cfn-nag
# Usage: .\scan-cloudformation.ps1 [template-file]

param (
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "infraascode.yaml"  # Default template file if not specified
)

# Check if cfn-lint is installed
$cfnLintInstalled = $null
try {
    $cfnLintInstalled = Get-Command cfn-lint -ErrorAction SilentlyContinue
} catch {
    # Command not found
}

if ($null -eq $cfnLintInstalled) {
    Write-Host "cfn-lint not found. Installing..."
    pip install cfn-lint
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install cfn-lint. Please install manually: pip install cfn-lint" -ForegroundColor Red
        exit 1
    }
    Write-Host "cfn-lint installed successfully" -ForegroundColor Green
} else {
    Write-Host "cfn-lint is already installed"
}

# Check if cfn_nag is installed (Ruby gem)
$cfnNagInstalled = $null
try {
    $cfnNagInstalled = Get-Command cfn_nag -ErrorAction SilentlyContinue
} catch {
    # Command not found
}

if ($null -eq $cfnNagInstalled) {
    Write-Host "cfn_nag not found. Installing..."
    gem install cfn-nag
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install cfn-nag. Please install manually: gem install cfn-nag" -ForegroundColor Red
        exit 1
    }
    Write-Host "cfn-nag installed successfully" -ForegroundColor Green
} else {
    Write-Host "cfn-nag is already installed"
}

# Verify template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

# Run cfn-lint on the template
Write-Host "Running cfn-lint on $TemplateFile..." -ForegroundColor Cyan
cfn-lint $TemplateFile

# Run cfn_nag on the template
Write-Host "Running cfn_nag on $TemplateFile..." -ForegroundColor Cyan
cfn_nag_scan --input-path $TemplateFile

# Save cfn_nag results to a file
Write-Host "Saving cfn_nag results to cfn-nag-results.json" -ForegroundColor Cyan
cfn_nag_scan --input-path $TemplateFile --output-format json | Out-File -FilePath "cfn-nag-results.json"

# Parse the JSON results (simplified as cfn_nag output format varies)
Write-Host "Checking for high severity issues..." -ForegroundColor Cyan
$nagResults = Get-Content -Raw "cfn-nag-results.json" | ConvertFrom-Json
$highSeverityCount = 0

# Count high severity issues (adjust based on actual cfn_nag output format)
if ($nagResults.violations) {
    $highSeverityCount = ($nagResults.violations | Where-Object { $_.severity -eq "HIGH" -or $_.severity -eq "CRITICAL" }).Count
}

# Display summary
Write-Host "Summary of scan results:" -ForegroundColor Yellow
Write-Host "High severity issues: $highSeverityCount" -ForegroundColor $(if ($highSeverityCount -gt 0) { "Red" } else { "Green" })

# Exit with error code if high severity issues found
if ($highSeverityCount -gt 0) {
    Write-Host "WARNING: High severity issues found!" -ForegroundColor Red
    exit 1
}

Write-Host "Scan completed successfully" -ForegroundColor Green