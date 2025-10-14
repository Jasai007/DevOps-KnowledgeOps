# Create a new Cognito user
param(
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [string]$UserPoolId = "us-east-1_QVdUR725D",
    [string]$Region = "us-east-1"
)

Write-Host "Creating new user: $Email" -ForegroundColor Green

try {
    # Create user
    Write-Host "1. Creating user in Cognito..." -ForegroundColor Yellow
    aws cognito-idp admin-create-user `
        --user-pool-id $UserPoolId `
        --username $Email `
        --user-attributes Name=email,Value=$Email Name=email_verified,Value=true `
        --temporary-password $Password `
        --message-action SUPPRESS `
        --region $Region

    if ($LASTEXITCODE -eq 0) {
        Write-Host "User created successfully!" -ForegroundColor Green
        
        # Set permanent password
        Write-Host "2. Setting permanent password..." -ForegroundColor Yellow
        aws cognito-idp admin-set-user-password `
            --user-pool-id $UserPoolId `
            --username $Email `
            --password $Password `
            --permanent `
            --region $Region

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Password set successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "User created successfully!" -ForegroundColor Green
            Write-Host "Email: $Email" -ForegroundColor White
            Write-Host "Password: $Password" -ForegroundColor White
            Write-Host ""
            Write-Host "You can now login with these credentials!" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to set password" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to create user" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}