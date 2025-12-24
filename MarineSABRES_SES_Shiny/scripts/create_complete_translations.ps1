# Script to create complete translation.json with Portuguese and Italian
# Converts Lithuanian (lt) to Portuguese (pt) and Italian (it)

$translationFile = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"

# Read current file
$json = Get-Content $translationFile -Raw | ConvertFrom-Json

# Change languages from lt to pt and it
$json.languages = @("en", "es", "fr", "de", "pt", "it")

# Convert all translations: rename lt to pt, and duplicate for it
foreach ($trans in $json.translation) {
    if ($trans.PSObject.Properties.Name -contains "lt") {
        # Portuguese - reuse Lithuanian text as placeholder (will need proper translation later)
        $trans | Add-Member -MemberType NoteProperty -Name "pt" -Value $trans.lt -Force
        # Italian - reuse Lithuanian text as placeholder (will need proper translation later)
        $trans | Add-Member -MemberType NoteProperty -Name "it" -Value $trans.lt -Force
        # Remove lt property
        $trans.PSObject.Properties.Remove("lt")
    }
}

Write-Host "Converted $($json.translation.Count) existing translations from lt to pt/it"
Write-Host "Note: pt and it currently have placeholder text - needs proper translation"

# Save intermediate file
$json | ConvertTo-Json -Depth 10 | Set-Content $translationFile -Encoding UTF8

Write-Host "Saved intermediate translation.json with pt/it placeholders"
Write-Host "Ready to add Dashboard and additional Entry Point translations"
