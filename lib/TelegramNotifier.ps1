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
            Write-Host "$([char]0x2713) $(L 'telegram_bot_connected' $response.result.username)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "$([char]0x2717) $(L 'telegram_failed_connect' $_)" -ForegroundColor Red
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
    Write-Host "=== $(L 'telegram_how_to_get_id') ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host (L 'telegram_method_userinfobot') -ForegroundColor Yellow
    Write-Host "  1. $(L 'telegram_step_search')" -ForegroundColor White
    Write-Host "  2. $(L 'telegram_step_start')" -ForegroundColor White
    Write-Host "  3. $(L 'telegram_step_reply')" -ForegroundColor White
    Write-Host ""
    Write-Host (L 'telegram_method_auto') -ForegroundColor Yellow
    Write-Host "  1. $(L 'telegram_step_send_message')" -ForegroundColor White
    Write-Host "  2. $(L 'telegram_step_detect')" -ForegroundColor White
    Write-Host ""
    Write-Host (L 'telegram_checking_messages') -ForegroundColor Cyan
    
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
                Write-Host (L 'telegram_found_chats' $chatIds.Count) -ForegroundColor Green
                Write-Host ""
                foreach ($chat in $chatIds) {
                    Write-Host "  $(L 'telegram_chat_id' $chat.ChatId)" -ForegroundColor White
                    if ($chat.Username) {
                        Write-Host "  $(L 'telegram_username' $chat.Username)" -ForegroundColor Gray
                    }
                    if ($chat.FirstName) {
                        Write-Host "  $(L 'telegram_name' $chat.FirstName)" -ForegroundColor Gray
                    }
                    Write-Host "  $(L 'telegram_type' $chat.Type)" -ForegroundColor Gray
                    Write-Host ""
                }
                return $chatIds.ChatId
            }
        }
        
        Write-Host ""
        Write-Host (L 'telegram_no_messages') -ForegroundColor Yellow
        Write-Host (L 'telegram_send_message_prompt') -ForegroundColor Yellow
        return @()
    } catch {
        Write-Host ""
        Write-Host (L 'telegram_error_getting_ids' $_) -ForegroundColor Red
        return @()
    }
}

function Invoke-TelegramConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    Write-Host ""
    Write-Host "=== $(L 'telegram_config_title') ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Load existing config as hashtable
    $telegramConfig = $Config.GetTelegramConfig()
    
    if ($telegramConfig.Enabled) {
        Write-Host "$(L 'telegram_current_status') " -NoNewline
        Write-Host (L 'telegram_status_enabled') -ForegroundColor Green
        Write-Host (L 'telegram_registered_users' $telegramConfig.ChatIds.Count) -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "1. $(L 'telegram_option_enable')"
    Write-Host "2. $(L 'telegram_option_add_user')"
    Write-Host "3. $(L 'telegram_option_remove_user')"
    Write-Host "4. $(L 'telegram_option_test')"
    Write-Host "5. $(L 'telegram_option_disable')"
    Write-Host "0. $(L 'telegram_option_back')"
    Write-Host ""
    
    $choice = Read-Host (L 'menu_select_option')
    
    switch ($choice) {
        "1" {
            Write-Host ""
            $botToken = Read-Host (L 'telegram_enter_token')
            
            if (Test-TelegramConnection -BotToken $botToken) {
                $telegramConfig.BotToken = $botToken
                $telegramConfig.Enabled = $true
                
                Write-Host ""
                Write-Host (L 'telegram_getting_chat_ids') -ForegroundColor Cyan
                $availableChatIds = Get-TelegramChatId -BotToken $botToken
                
                if ($availableChatIds.Count -gt 0) {
                    Write-Host (L 'telegram_found_chat_ids' ($availableChatIds -join ', ')) -ForegroundColor Green
                    $addAll = Read-Host (L 'telegram_add_all_chats')
                    
                    if ($addAll -eq 'y') {
                        $telegramConfig.ChatIds = $availableChatIds
                    }
                }
                
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host (L 'telegram_enabled') -ForegroundColor Green
            }
        }
        "2" {
            if (-not $telegramConfig.Enabled) {
                Write-Host (L 'telegram_configure_first') -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            $chatId = Read-Host (L 'telegram_enter_chat_id')
            
            if ($telegramConfig.ChatIds -notcontains $chatId) {
                $telegramConfig.ChatIds += $chatId
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host (L 'telegram_user_added') -ForegroundColor Green
            } else {
                Write-Host (L 'telegram_user_exists') -ForegroundColor Yellow
            }
        }
        "3" {
            if ($telegramConfig.ChatIds.Count -eq 0) {
                Write-Host (L 'telegram_no_users') -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host (L 'telegram_registered_users_list')
            for ($i = 0; $i -lt $telegramConfig.ChatIds.Count; $i++) {
                Write-Host "$($i + 1). $($telegramConfig.ChatIds[$i])"
            }
            
            $index = [int](Read-Host (L 'telegram_enter_number_remove')) - 1
            
            if ($index -ge 0 -and $index -lt $telegramConfig.ChatIds.Count) {
                $removed = $telegramConfig.ChatIds[$index]
                $telegramConfig.ChatIds = $telegramConfig.ChatIds | Where-Object { $_ -ne $removed }
                $Config.SaveTelegramConfig($telegramConfig)
                Write-Host (L 'telegram_user_removed') -ForegroundColor Green
            }
        }
        "4" {
            if (-not $telegramConfig.Enabled) {
                Write-Host (L 'telegram_not_configured') -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host (L 'telegram_sending_test') -ForegroundColor Cyan
            
            $result = Send-TelegramNotification -TelegramConfig (ConvertTo-TelegramConfigObject $telegramConfig) -Message "Test notification from GitHub Runner Manager" -Type "Info" -ShowErrors
            
            Write-Host ""
            if ($result.Success) {
                Write-Host "$([char]0x2713) $(L 'telegram_test_success' $result.SuccessCount $result.TotalChats)" -ForegroundColor Green
            } else {
                Write-Host "$([char]0x2717) $(L 'telegram_test_failed')" -ForegroundColor Red
            }
            
            if ($result.FailedChats.Count -gt 0) {
                Write-Host ""
                Write-Host "$(L 'telegram_failed_chats')" -ForegroundColor Yellow
                foreach ($failed in $result.FailedChats) {
                    Write-Host "  - $(L 'telegram_chat_id' $failed.ChatId)" -ForegroundColor Yellow
                }
                
                Write-Host ""
                Write-Host (L 'telegram_common_issues') -ForegroundColor Cyan
                Write-Host "  1. $(L 'telegram_issue_not_started')" -ForegroundColor White
                Write-Host "     $(L 'telegram_solution_start')" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  2. $(L 'telegram_issue_blocked')" -ForegroundColor White
                Write-Host "     $(L 'telegram_solution_unblock')" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  3. $(L 'telegram_issue_invalid_id')" -ForegroundColor White
                Write-Host "     $(L 'telegram_solution_get_id')" -ForegroundColor Gray
                Write-Host ""
            }
        }
        "5" {
            $telegramConfig.Enabled = $false
            $Config.SaveTelegramConfig($telegramConfig)
            Write-Host (L 'telegram_disabled') -ForegroundColor Yellow
        }
    }
}
