# TelegramNotifier Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

. "$root\lib\TelegramNotifier.ps1"

Describe "TelegramNotifier Module" {

    Context "TelegramConfig Class" {
        It "Should initialize with defaults" {
            $tc = [TelegramConfig]::new()
            $tc.BotToken | Should BeNullOrEmpty
            $tc.ChatIds.Count | Should Be 0
            $tc.Enabled | Should Be $false
        }
    }

    Context "ConvertTo-TelegramConfigObject" {
        It "Should convert hashtable to PSCustomObject" {
            $hash = @{
                BotToken = "123:ABC"
                ChatIds  = @("111", "222")
                Enabled  = $true
            }
            $obj = ConvertTo-TelegramConfigObject -ConfigHash $hash
            $obj.BotToken | Should Be "123:ABC"
            $obj.ChatIds.Count | Should Be 2
            $obj.Enabled | Should Be $true
        }
    }

    Context "Send-TelegramNotification" {
        It "Should return failure when not configured" {
            $tgConfig = [PSCustomObject]@{
                BotToken = $null
                ChatIds  = @()
                Enabled  = $false
            }
            $result = Send-TelegramNotification -TelegramConfig $tgConfig -Message "test"
            $result.Success | Should Be $false
            $result.Message | Should Be "Telegram not configured"
        }

        It "Should return failure when enabled but no token" {
            $tgConfig = [PSCustomObject]@{
                BotToken = $null
                ChatIds  = @("123")
                Enabled  = $true
            }
            $result = Send-TelegramNotification -TelegramConfig $tgConfig -Message "test"
            $result.Success | Should Be $false
        }

        It "Should handle empty chat IDs" {
            $tgConfig = [PSCustomObject]@{
                BotToken = "123:ABC"
                ChatIds  = @()
                Enabled  = $true
            }
            $result = Send-TelegramNotification -TelegramConfig $tgConfig -Message "test"
            $result.Success | Should Be $false
            $result.SuccessCount | Should Be 0
            $result.TotalChats | Should Be 0
        }
    }
}
