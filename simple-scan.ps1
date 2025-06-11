# PowerShell script for scanning CloudFormation templates using cfn_nag
# Usage: .\simple-scan.ps1 [template-file]

param (
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "infraascode.yaml",  # Default template file if not specified
    
    [Parameter(Mandatory=$false)]
    [switch]$UseAwsScan = $false  # Flag to use AWS CloudFormation validate-template
)

# Verify template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning CloudFormation template: $TemplateFile" -ForegroundColor Cyan
$content = Get-Content $TemplateFile -Raw

# Basic security checks
Write-Host "`n=== Basic Security Checks ===" -ForegroundColor Cyan

# Check for public SSH access
Write-Host "Checking for public SSH access..." -ForegroundColor Cyan
if ($content -match "FromPort.*22" -and $content -match "ToPort.*22" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    Write-Host "❌ HIGH RISK: SSH port 22 is open to the world (0.0.0.0/0)" -ForegroundColor Red
    Write-Host "   Recommendation: Restrict SSH access to specific IP ranges" -ForegroundColor Yellow
} else {
    Write-Host "✅ SSH access is properly restricted" -ForegroundColor Green
}

# Check for public HTTP/HTTPS access
Write-Host "Checking for public HTTP/HTTPS access..." -ForegroundColor Cyan
if ($content -match "FromPort.*80" -and $content -match "ToPort.*80" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    Write-Host "⚠️ MEDIUM RISK: HTTP port 80 is open to the world (0.0.0.0/0)" -ForegroundColor Yellow
    Write-Host "   Note: This may be intentional for public web services" -ForegroundColor Yellow
}

# Check for RDS encryption
Write-Host "Checking for RDS encryption..." -ForegroundColor Cyan
if ($content -match "AWS::RDS::DBInstance") {
    if (-not ($content -match "StorageEncrypted.*true")) {
        Write-Host "❌ HIGH RISK: RDS instance does not have storage encryption enabled" -ForegroundColor Red
        Write-Host "   Recommendation: Add 'StorageEncrypted: true' to RDS instance properties" -ForegroundColor Yellow
    } else {
        Write-Host "✅ RDS storage encryption is enabled" -ForegroundColor Green
    }
}

# Check for RDS backup
Write-Host "Checking for RDS backups..." -ForegroundColor Cyan
if ($content -match "AWS::RDS::DBInstance") {
    if (-not ($content -match "BackupRetentionPeriod")) {
        Write-Host "❌ HIGH RISK: RDS instance does not have backups enabled" -ForegroundColor Red
        Write-Host "   Recommendation: Add 'BackupRetentionPeriod: 7' to RDS instance properties" -ForegroundColor Yellow
    } else {
        Write-Host "✅ RDS backups are enabled" -ForegroundColor Green
    }
}

# Check for RDS auto minor version upgrade
Write-Host "Checking for RDS auto minor version upgrade..." -ForegroundColor Cyan
if ($content -match "AWS::RDS::DBInstance") {
    if (-not ($content -match "AutoMinorVersionUpgrade.*true")) {
        Write-Host "❌ HIGH RISK: RDS instance does not have auto minor version upgrades enabled" -ForegroundColor Red
        Write-Host "   Recommendation: Add 'AutoMinorVersionUpgrade: true' to RDS instance properties" -ForegroundColor Yellow
    } else {
        Write-Host "✅ RDS auto minor version upgrades are enabled" -ForegroundColor Green
    }
}

# Check for VPC Flow Logs
Write-Host "Checking for VPC Flow Logs..." -ForegroundColor Cyan
if (-not ($content -match "AWS::EC2::FlowLog")) {
    Write-Host "⚠️ LOW RISK: VPC Flow Logs are not enabled" -ForegroundColor Yellow
    Write-Host "   Recommendation: Add AWS::EC2::FlowLog resource for network monitoring" -ForegroundColor Yellow
} else {
    Write-Host "✅ VPC Flow Logs are enabled" -ForegroundColor Green
}

# Check for HTTPS listener
Write-Host "Checking for HTTPS listener..." -ForegroundColor Cyan
if ($content -match "AWS::ElasticLoadBalancingV2::Listener") {
    if (-not ($content -match "Protocol.*HTTPS")) {
        Write-Host "⚠️ MEDIUM RISK: No HTTPS listener configured" -ForegroundColor Yellow
        Write-Host "   Recommendation: Add HTTPS listener with SSL/TLS certificate" -ForegroundColor Yellow
    } else {
        Write-Host "✅ HTTPS listener is configured" -ForegroundColor Green
    }
}

# Check for IAM database authentication
Write-Host "Checking for RDS IAM authentication..." -ForegroundColor Cyan
if ($content -match "AWS::RDS::DBInstance") {
    if (-not ($content -match "EnableIAMDatabaseAuthentication.*true")) {
        Write-Host "⚠️ MEDIUM RISK: RDS instance does not have IAM authentication enabled" -ForegroundColor Yellow
        Write-Host "   Recommendation: Add 'EnableIAMDatabaseAuthentication: true' to RDS instance properties" -ForegroundColor Yellow
    } else {
        Write-Host "✅ RDS IAM authentication is enabled" -ForegroundColor Green
    }
}

# Check for CloudWatch logs
Write-Host "Checking for CloudWatch logs..." -ForegroundColor Cyan
if ($content -match "AWS::RDS::DBInstance") {
    if (-not ($content -match "EnableCloudwatchLogsExports")) {
        Write-Host "⚠️ MEDIUM RISK: RDS instance does not have CloudWatch logs enabled" -ForegroundColor Yellow
        Write-Host "   Recommendation: Add 'EnableCloudwatchLogsExports' to RDS instance properties" -ForegroundColor Yellow
    } else {
        Write-Host "✅ RDS CloudWatch logs are enabled" -ForegroundColor Green
    }
}

# Use AWS CloudFormation validate-template if flag is set
if ($UseAwsScan) {
    Write-Host "`n=== AWS CloudFormation Validation ===" -ForegroundColor Cyan
    $awsInstalled = $null
    try {
        $awsInstalled = Get-Command aws -ErrorAction SilentlyContinue
    } catch {
        # Command not found
    }

    if ($null -ne $awsInstalled) {
        aws cloudformation validate-template --template-body file://$TemplateFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ AWS CloudFormation validation passed" -ForegroundColor Green
        } else {
            Write-Host "❌ AWS CloudFormation validation failed" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ AWS CLI not found. Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    }
}

# Count issues
$highCount = 0
$mediumCount = 0
$lowCount = 0

# SSH check
if ($content -match "FromPort.*22" -and $content -match "ToPort.*22" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    $highCount++
}

# RDS encryption check
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "StorageEncrypted.*true")) {
    $highCount++
}

# RDS backup check
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "BackupRetentionPeriod")) {
    $highCount++
}

# RDS auto minor version upgrade check
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "AutoMinorVersionUpgrade.*true")) {
    $highCount++
}

# HTTP check
if ($content -match "FromPort.*80" -and $content -match "ToPort.*80" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    $mediumCount++
}

# HTTPS listener check
if ($content -match "AWS::ElasticLoadBalancingV2::Listener" -and -not ($content -match "Protocol.*HTTPS")) {
    $mediumCount++
}

# IAM database authentication check
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "EnableIAMDatabaseAuthentication.*true")) {
    $mediumCount++
}

# CloudWatch logs check
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "EnableCloudwatchLogsExports")) {
    $mediumCount++
}

# VPC Flow Logs check
if (-not ($content -match "AWS::EC2::FlowLog")) {
    $lowCount++
}

# Summary
Write-Host "`n=== Scan Summary ===" -ForegroundColor Cyan
Write-Host "Template: $TemplateFile" -ForegroundColor White
Write-Host "Scan Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -ForegroundColor White
Write-Host "High severity issues: $highCount" -ForegroundColor $(if ($highCount -gt 0) { "Red" } else { "Green" })
Write-Host "Medium severity issues: $mediumCount" -ForegroundColor $(if ($mediumCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "Low severity issues: $lowCount" -ForegroundColor $(if ($lowCount -gt 0) { "Cyan" } else { "Green" })

# Generate HTML report
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>CloudFormation Security Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { margin: 20px 0; }
        .high { color: #d9534f; font-weight: bold; }
        .medium { color: #f0ad4e; }
        .low { color: #5bc0de; }
        .good { color: #5cb85c; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>CloudFormation Security Scan Report</h1>
    <p>Template: $TemplateFile</p>
    <p>Scan Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><span class="$(if ($highCount -gt 0) { 'high' } else { 'good' })">High severity issues: $highCount</span></p>
        <p><span class="$(if ($mediumCount -gt 0) { 'medium' } else { 'good' })">Medium severity issues: $mediumCount</span></p>
        <p><span class="$(if ($lowCount -gt 0) { 'low' } else { 'good' })">Low severity issues: $lowCount</span></p>
    </div>
    
    <h2>Security Findings</h2>
    <table>
        <tr>
            <th>Severity</th>
            <th>Issue</th>
            <th>Recommendation</th>
        </tr>
"@

# Add SSH finding
if ($content -match "FromPort.*22" -and $content -match "ToPort.*22" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    $htmlReport += @"
        <tr>
            <td class="high">HIGH</td>
            <td>SSH port 22 is open to the world (0.0.0.0/0)</td>
            <td>Restrict SSH access to specific IP ranges</td>
        </tr>
"@
}

# Add RDS encryption finding
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "StorageEncrypted.*true")) {
    $htmlReport += @"
        <tr>
            <td class="high">HIGH</td>
            <td>RDS instance does not have storage encryption enabled</td>
            <td>Add 'StorageEncrypted: true' to RDS instance properties</td>
        </tr>
"@
}

# Add RDS backup finding
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "BackupRetentionPeriod")) {
    $htmlReport += @"
        <tr>
            <td class="high">HIGH</td>
            <td>RDS instance does not have backups enabled</td>
            <td>Add 'BackupRetentionPeriod: 7' to RDS instance properties</td>
        </tr>
"@
}

# Add RDS auto minor version upgrade finding
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "AutoMinorVersionUpgrade.*true")) {
    $htmlReport += @"
        <tr>
            <td class="high">HIGH</td>
            <td>RDS instance does not have auto minor version upgrades enabled</td>
            <td>Add 'AutoMinorVersionUpgrade: true' to RDS instance properties</td>
        </tr>
"@
}

# Add HTTP finding
if ($content -match "FromPort.*80" -and $content -match "ToPort.*80" -and $content -match "CidrIp.*0\.0\.0\.0/0") {
    $htmlReport += @"
        <tr>
            <td class="medium">MEDIUM</td>
            <td>HTTP port 80 is open to the world (0.0.0.0/0)</td>
            <td>This may be intentional for public web services</td>
        </tr>
"@
}

# Add HTTPS listener finding
if ($content -match "AWS::ElasticLoadBalancingV2::Listener" -and -not ($content -match "Protocol.*HTTPS")) {
    $htmlReport += @"
        <tr>
            <td class="medium">MEDIUM</td>
            <td>No HTTPS listener configured</td>
            <td>Add HTTPS listener with SSL/TLS certificate</td>
        </tr>
"@
}

# Add IAM database authentication finding
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "EnableIAMDatabaseAuthentication.*true")) {
    $htmlReport += @"
        <tr>
            <td class="medium">MEDIUM</td>
            <td>RDS instance does not have IAM authentication enabled</td>
            <td>Add 'EnableIAMDatabaseAuthentication: true' to RDS instance properties</td>
        </tr>
"@
}

# Add CloudWatch logs finding
if ($content -match "AWS::RDS::DBInstance" -and -not ($content -match "EnableCloudwatchLogsExports")) {
    $htmlReport += @"
        <tr>
            <td class="medium">MEDIUM</td>
            <td>RDS instance does not have CloudWatch logs enabled</td>
            <td>Add 'EnableCloudwatchLogsExports' to RDS instance properties</td>
        </tr>
"@
}

# Add VPC Flow Logs finding
if (-not ($content -match "AWS::EC2::FlowLog")) {
    $htmlReport += @"
        <tr>
            <td class="low">LOW</td>
            <td>VPC Flow Logs are not enabled</td>
            <td>Add AWS::EC2::FlowLog resource for network monitoring</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
    
    <h2>Best Practices</h2>
    <ul>
        <li>Restrict SSH access to specific IP ranges or use AWS Systems Manager Session Manager instead</li>
        <li>Enable encryption for all sensitive data at rest</li>
        <li>Configure automated backups for all databases</li>
        <li>Enable automatic minor version upgrades to get security patches</li>
        <li>Use HTTPS for all web traffic</li>
        <li>Enable logging and monitoring for all resources</li>
        <li>Use IAM roles and policies for authentication when possible</li>
    </ul>
</body>
</html>
"@

$htmlReport | Out-File -FilePath "security-scan-report.html"
Write-Host "`nHTML report generated: security-scan-report.html" -ForegroundColor Green
Write-Host "Scan completed successfully" -ForegroundColor Green