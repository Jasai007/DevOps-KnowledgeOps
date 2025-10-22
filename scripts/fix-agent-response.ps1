# Fix Agent Response Issues
# Comprehensive diagnostic and fix script

Write-Host "🔧 DevOps KnowledgeOps Agent Response Fix" -ForegroundColor Green
Write-Host ""

# Step 1: Check AWS CLI and credentials
Write-Host "1️⃣ Checking AWS Configuration..." -ForegroundColor Cyan
try {
    $awsIdentity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    Write-Host "✅ AWS Credentials Valid" -ForegroundColor Green
    Write-Host "   Account: $($awsIdentity.Account)" -ForegroundColor Gray
    Write-Host "   Region: $(aws configure get region)" -ForegroundColor Gray
} catch {
    Write-Host "❌ AWS Credentials Issue" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: List available Bedrock Agents
Write-Host "2️⃣ Discovering Bedrock Agents..." -ForegroundColor Cyan
try {
    $agents = aws bedrock-agent list-agents --region us-east-1 --output json 2>$null | ConvertFrom-Json
    
    if ($agents.agentSummaries.Count -gt 0) {
        Write-Host "✅ Found Bedrock Agents:" -ForegroundColor Green
        foreach ($agent in $agents.agentSummaries) {
            Write-Host "   📋 Agent: $($agent.agentName)" -ForegroundColor White
            Write-Host "      ID: $($agent.agentId)" -ForegroundColor Gray
            Write-Host "      Status: $($agent.agentStatus)" -ForegroundColor Gray
            
            # Get agent aliases
            try {
                $aliases = aws bedrock-agent list-agent-aliases --agent-id $agent.agentId --region us-east-1 --output json 2>$null | ConvertFrom-Json
                if ($aliases.agentAliasSummaries.Count -gt 0) {
                    Write-Host "      Aliases:" -ForegroundColor Gray
                    foreach ($alias in $aliases.agentAliasSummaries) {
                        Write-Host "        - $($alias.agentAliasName): $($alias.agentAliasId) ($($alias.agentAliasStatus))" -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Host "      No aliases found" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        # Find the DevOps agent
        $devopsAgent = $agents.agentSummaries | Where-Object { $_.agentName -like "*DevOps*" -or $_.agentName -like "*KnowledgeOps*" }
        if ($devopsAgent) {
            Write-Host "🎯 Found DevOps Agent:" -ForegroundColor Green
            Write-Host "   Name: $($devopsAgent.agentName)" -ForegroundColor White
            Write-Host "   ID: $($devopsAgent.agentId)" -ForegroundColor White
            Write-Host "   Status: $($devopsAgent.agentStatus)" -ForegroundColor White
            
            $correctAgentId = $devopsAgent.agentId
            
            # Get the correct alias
            $aliases = aws bedrock-agent list-agent-aliases --agent-id $correctAgentId --region us-east-1 --output json 2>$null | ConvertFrom-Json
            $activeAlias = $aliases.agentAliasSummaries | Where-Object { $_.agentAliasStatus -eq "PREPARED" } | Select-Object -First 1
            
            if ($activeAlias) {
                $correctAliasId = $activeAlias.agentAliasId
                Write-Host "   Active Alias: $($activeAlias.agentAliasName) ($correctAliasId)" -ForegroundColor White
            } else {
                $correctAliasId = "TSTALIASID"
                Write-Host "   ⚠️  No active alias found, using default: $correctAliasId" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️  No DevOps-specific agent found, using configured ID" -ForegroundColor Yellow
            $correctAgentId = "MNJESZYALW"
            $correctAliasId = "TSTALIASID"
        }
    } else {
        Write-Host "⚠️  No Bedrock Agents found" -ForegroundColor Yellow
        $correctAgentId = "MNJESZYALW"
        $correctAliasId = "TSTALIASID"
    }
} catch {
    Write-Host "⚠️  Could not list Bedrock Agents, using configured values" -ForegroundColor Yellow
    $correctAgentId = "MNJESZYALW"
    $correctAliasId = "TSTALIASID"
}

Write-Host ""

# Step 3: Update configuration
Write-Host "3️⃣ Updating Configuration..." -ForegroundColor Cyan
$configPath = "backend/config/cognito-config.env"
$configContent = Get-Content $configPath

# Update or add BEDROCK_AGENT_ALIAS_ID
$aliasLineExists = $configContent | Where-Object { $_ -match "^BEDROCK_AGENT_ALIAS_ID=" }
if ($aliasLineExists) {
    $configContent = $configContent -replace "^BEDROCK_AGENT_ALIAS_ID=.*", "BEDROCK_AGENT_ALIAS_ID=$correctAliasId"
} else {
    $configContent += "BEDROCK_AGENT_ALIAS_ID=$correctAliasId"
}

# Update BEDROCK_AGENT_ID if we found a better one
$configContent = $configContent -replace "^BEDROCK_AGENT_ID=.*", "BEDROCK_AGENT_ID=$correctAgentId"

# Write updated config
$configContent | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "✅ Configuration Updated:" -ForegroundColor Green
Write-Host "   BEDROCK_AGENT_ID: $correctAgentId" -ForegroundColor White
Write-Host "   BEDROCK_AGENT_ALIAS_ID: $correctAliasId" -ForegroundColor White

Write-Host ""

# Step 4: Test the agent
Write-Host "4️⃣ Testing Agent Response..." -ForegroundColor Cyan
$env:BEDROCK_AGENT_ID = $correctAgentId
$env:BEDROCK_AGENT_ALIAS_ID = $correctAliasId

try {
    Write-Host "   Running agent test..." -ForegroundColor Gray
    $testOutput = node tests/test-bedrock-agent.js 2>&1
    
    if ($testOutput -match "Agent responded successfully") {
        Write-Host "✅ Agent is responding correctly!" -ForegroundColor Green
        $agentWorking = $true
    } else {
        Write-Host "❌ Agent test failed" -ForegroundColor Red
        Write-Host "   Output: $testOutput" -ForegroundColor Gray
        $agentWorking = $false
    }
} catch {
    Write-Host "❌ Agent test error: $($_.Exception.Message)" -ForegroundColor Red
    $agentWorking = $false
}

Write-Host ""

# Step 5: Provide recommendations
Write-Host "5️⃣ Recommendations:" -ForegroundColor Cyan

if ($agentWorking) {
    Write-Host "✅ Agent is working! You can now:" -ForegroundColor Green
    Write-Host "   1. Run: .\start.ps1" -ForegroundColor White
    Write-Host "   2. Or: .\scripts\start-smart.ps1" -ForegroundColor White
    Write-Host "   3. Test: node tests/test-agentcore.js" -ForegroundColor White
} else {
    Write-Host "⚠️  Agent needs attention. Try:" -ForegroundColor Yellow
    Write-Host "   1. Check agent status in AWS Bedrock Console" -ForegroundColor White
    Write-Host "   2. Ensure agent is in PREPARED state" -ForegroundColor White
    Write-Host "   3. Verify agent alias is active" -ForegroundColor White
    Write-Host "   4. Check IAM permissions for bedrock:InvokeAgent" -ForegroundColor White
    Write-Host ""
    Write-Host "   For now, use fallback mode:" -ForegroundColor Cyan
    Write-Host "   cd backend && node server-fallback.js" -ForegroundColor White
}

Write-Host ""
Write-Host "🎯 Configuration saved to: $configPath" -ForegroundColor Green