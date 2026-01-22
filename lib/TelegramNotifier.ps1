# Telegram Notification Module
# Supports multiple users for notifications

# Define TelegramConfig class only if not already defined
if (-not ([System.Management.Automation.PSTypeName]'TelegramConfig').Type) {
    class TelegramConfig {
        [string]$BotToken
        [string[]]$ChatIds
        [bool]$Enabled
        
        TelegramConfig() {
            $this.BotToken = $null
            $this.ChatIds = @()
            $this.Enabled = $false
        }
    }
}

# Helper function to convert hashtable to object for Send-TelegramNotification
function ConvertTo-TelegramConfigObject {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ConfigHash
    )
    
    return [PSCustomObject]@{
        BotToken = $ConfigHash.BotToken
        ChatIds = $ConfigHash.ChatIds
        Enabled = $ConfigHash.Enabled
    }
}

function Send-TelegramNotification {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TelegramConfig,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowErrors
    )
    
    if (-not $TelegramConfig.Enabled -or -not $TelegramConfig.BotToken) {
        return @{
            Success = $false
            FailedChats = @()
            Message = "Telegram not configured"
        }
    }
    
    $formattedMessage = "*$Type*`n`n$Message`n`n_$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_"
    
    $successCount = 0
    $failedChats = @()
    
    foreach ($chatId in $TelegramConfig.ChatIds) {
        try {
            $uri = "https://api.telegram.org/bot$($TelegramConfig.BotToken)/sendMessage"
            $body = @{
                chat_id = $chatId
                text = $formattedMessage
                parse_mode = "Markdown"
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json; charset=utf-8" -ErrorAction Stop
            if ($response.ok) {
                $successCount++
            }
        } catch {
            $errorMsg = $_.Exception.Message
            $failedChats += @{
                ChatId = $chatId
                Error = $errorMsg
            }
            
            if ($ShowErrors) {
                # Parse error message
                if ($errorMsg -match "chat not found") {
                    Write-Host "Chat $chatId not found - User must start conversation with bot first" -ForegroundColor Yellow
                } elseif ($errorMsg -match "bot was blocked") {
                    Write-Host "Chat $chatId blocked the bot" -ForegroundColor Yellow
                } else {
                    Write-Host "Failed to send to chat ${chatId}: $errorMsg" -ForegroundColor Yellow
                }
            }
        }
    }
    
    return @{
        Success = ($successCount -gt 0)
        SuccessCount = $successCount
        FailedChats = $failedChats
        TotalChats = $TelegramConfig.ChatIds.Count
    }
}

function Test-TelegramConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BotToken
    )
    
    try {
        $uri = "https://api.telegram.org/bot$BotToken/getMe"
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        
        if ($response.ok) {
            Write-Host "$([char]0x2713) Bot connected: @$($response.result.username)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "$([char]0x2717) Failed to connect to Telegram bot: $_" -ForegroundColor Red
        return $false
    }
    
    return $false
}

function Get-TelegramChatId {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BotToken
    )
    
    Write-Host ""
    Write-Host "=== How to get your Telegram Chat ID ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Method 1: Using @userinfobot" -ForegroundColor Yellow
    Write-Host "  1. Open Telegram and search for @userinfobot" -ForegroundColor White
    Write-Host "  2. Start conversation and send /start" -ForegroundColor White
    Write-Host "  3. Bot will reply with your Chat ID" -ForegroundColor White
    Write-Host ""
    Write-Host "Method 2: Automatic detection" -ForegroundColor Yellow
    Write-Host "  1. Send any message to your bot" -ForegroundColor White
    Write-Host "  2. This tool will detect your Chat ID" -ForegroundColor White
    Write-Host ""
    Write-Host "Checking for messages..." -ForegroundColor Cyan
    
    try {
        $uri = "https://api.telegram.org/bot$BotToken/getUpdates"
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        
        if ($response.ok -and $response.result.Count -gt 0) {
            $chatIds = $response.result | ForEach-Object { 
                if ($_.message.chat.id) {
                    @{
                        ChatId = $_.message.chat.id
                        Username = $_.message.chat.username
                        FirstName = $_.message.chat.first_name
                        Type = $_.message.chat.type
                    }
                }
            } | Select-Object -Property ChatId, Username, FirstName, Type -Unique
            
            if ($chatIds.Count -gt 0) {
                Write-Host ""
                Write-Host "Found $($chatIds.Count) chat(s):" -ForegroundColor Green
                Write-Host ""
                foreach ($chat in $chatIds) {
                    Write-Host "  Chat ID: $($chat.ChatId)" -ForegroundColor White
                    if ($chat.Username) {
                        Write-Host "  Username: @$($chat.Username)" -ForegroundColor Gray
                    }
                    if ($chat.FirstName) {
                        Write-Host "  Name: $($chat.FirstName)" -ForegroundColor Gray
                    }
                    Write-Host "  Type: $($chat.Type)" -ForegroundColor Gray
                    Write-Host ""
                }
                return $chatIds.ChatId
            }
        }
        
        Write-Host ""
        Write-Host "No messages found." -ForegroundColor Yellow
        Write-Host "Please send a message to your bot and try again." -ForegroundColor Yellow
        return @()
    } catch {
        Write-Host ""
        Write-Host "Failed to get chat IDs: $_" -ForegroundColor Red
        return @()
    }
}

function Invoke-TelegramConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Host ""
    Write-Host "=== Telegram Notification Configuration ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Load existing config as hashtable
    $telegramConfig = $Config.GetTelegramConfig()
    
    if ($telegramConfig.Enabled) {
        Write-Host "Current status: " -NoNewline
        Write-Host "ENABLED" -ForegroundColor Green
        Write-Host "Registered users: $($telegramConfig.ChatIds.Count)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "1. Enable/Configure Telegram notifications"
    Write-Host "2. Add user (Chat ID)"
    Write-Host "3. Remove user"
    Write-Host "4. Test notification"
    Write-Host "5. Disable notifications"
    Write-Host "0. Back"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            $botToken = Read-Host "Enter Telegram Bot Token"
            
            if (Test-TelegramConnection -BotToken $botToken) {
                $telegramConfig.BotToken = $botToken
                $telegramConfig.Enabled = $true
                
                Write-Host ""
                Write-Host "Getting available chat IDs..." -ForegroundColor Cyan
                $availableChatIds = Get-TelegramChatId -BotToken $botToken
                
                if ($availableChatIds.Count -gt 0) {
                    Write-Host "Found chat IDs: $($availableChatIds -join ', ')" -ForegroundColor Green
                    $addAll = Read-Host "Add all found chat IDs? (y/n)"
                    
                    if ($addAll -eq 'y') {
                        $telegramConfig.ChatIds = $availableChatIds
                    }
                }
                
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host "Telegram notifications enabled!" -ForegroundColor Green
            }
        }
        "2" {
            if (-not $telegramConfig.Enabled) {
                Write-Host "Please configure Telegram bot first (option 1)" -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            $chatId = Read-Host "Enter Chat ID to add"
            
            if ($telegramConfig.ChatIds -notcontains $chatId) {
                $telegramConfig.ChatIds += $chatId
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host "User added successfully!" -ForegroundColor Green
            } else {
                Write-Host "This user is already registered" -ForegroundColor Yellow
            }
        }
        "3" {
            if ($telegramConfig.ChatIds.Count -eq 0) {
                Write-Host "No users registered" -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host "Registered users:"
            for ($i = 0; $i -lt $telegramConfig.ChatIds.Count; $i++) {
                Write-Host "$($i + 1). $($telegramConfig.ChatIds[$i])"
            }
            
            $index = [int](Read-Host "Enter number to remove") - 1
            
            if ($index -ge 0 -and $index -lt $telegramConfig.ChatIds.Count) {
                $removed = $telegramConfig.ChatIds[$index]
                $telegramConfig.ChatIds = $telegramConfig.ChatIds | Where-Object { $_ -ne $removed }
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host "User removed successfully!" -ForegroundColor Green
            }
        }
        "4" {
            if (-not $telegramConfig.Enabled) {
                Write-Host "Telegram notifications are not configured" -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host "Sending test notification..." -ForegroundColor Cyan
            
            $result = Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message "Test notification from GitHub Runner Manager" -Type "Info" -ShowErrors
            
            Write-Host ""
            if ($result.Success) {
                Write-Host "$([char]0x2713) Successfully sent to $($result.SuccessCount) of $($result.TotalChats) chats" -ForegroundColor Green
            } else {
                Write-Host "$([char]0x2717) Failed to send to all chats" -ForegroundColor Red
            }
            
            if ($result.FailedChats.Count -gt 0) {
                Write-Host ""
                Write-Host "Failed chats:" -ForegroundColor Yellow
                foreach ($failed in $result.FailedChats) {
                    Write-Host "  - Chat ID: $($failed.ChatId)" -ForegroundColor Yellow
                }
                
                Write-Host ""
                Write-Host "Common issues:" -ForegroundColor Cyan
                Write-Host "  1. User hasn't started conversation with bot" -ForegroundColor White
                Write-Host "     Solution: Open Telegram, search for your bot, click START" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  2. User blocked the bot" -ForegroundColor White
                Write-Host "     Solution: Unblock bot in Telegram settings" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  3. Invalid Chat ID" -ForegroundColor White
                Write-Host "     Solution: Get correct Chat ID from @userinfobot" -ForegroundColor Gray
                Write-Host ""
            }
        }
        "5" {
            $telegramConfig.Enabled = $false
            $Config.SaveTelegramConfig($telegramConfig)
            Write-Host "Telegram notifications disabled" -ForegroundColor Yellow
        }
    }
}
