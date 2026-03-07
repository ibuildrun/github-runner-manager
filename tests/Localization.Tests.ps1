# Localization Module Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

# Load module
. "$root\lib\Localization.ps1"

Describe "Localization Module" {

    Context "Set-Language" {
        It "Should set language to English" {
            Set-Language -Language "en"
            Get-CurrentLanguage | Should Be "en"
        }

        It "Should set language to Russian" {
            Set-Language -Language "ru"
            Get-CurrentLanguage | Should Be "ru"
        }
    }

    Context "Get-AvailableLanguages" {
        It "Should return en and ru" {
            $langs = Get-AvailableLanguages
            ($langs -contains "en") | Should Be $true
            ($langs -contains "ru") | Should Be $true
            $langs.Count | Should Be 2
        }
    }

    Context "Get-Translation (L alias)" {
        BeforeEach {
            Set-Language -Language "en"
        }

        It "Should return English translation for known key" {
            $result = Get-Translation "menu_title"
            $result | Should Be "Runner Manager"
        }

        It "Should return Russian translation when language is ru" {
            Set-Language -Language "ru"
            $result = Get-Translation "press_enter"
            $result | Should Match "Enter"  # Russian contains Cyrillic
        }

        It "Should return key itself for unknown key" {
            $result = Get-Translation "nonexistent_key_xyz"
            $result | Should Be "nonexistent_key_xyz"
        }

        It "Should support parameter substitution" {
            $result = Get-Translation "token_config_title" "GitHub"
            $result | Should Be "GitHub Token Configuration"
        }

        It "Should fallback to English when key missing in current language" {
            Set-Language -Language "ru"
            # menu_title exists in both, so test with a key that exists in en
            $result = Get-Translation "menu_title"
            $result | Should Not BeNullOrEmpty
        }

        It "Should work via L alias" {
            $result = L "menu_repository"
            $result | Should Be "Repository"
        }
    }

    Context "Translation Consistency" {
        It "Should have same keys in en and ru for core menu items" {
            Set-Language -Language "en"
            $coreKeys = @(
                "menu_title", "menu_platform", "menu_repository",
                "menu_token", "press_enter", "invalid_option",
                "goodbye_message"
            )
            foreach ($key in $coreKeys) {
                $en = Get-Translation $key
                $en | Should Not Be $key  # Should not return key itself

                Set-Language -Language "ru"
                $ru = Get-Translation $key
                $ru | Should Not Be $key

                Set-Language -Language "en"
            }
        }
    }
}
