$translationsPath = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"
$newTranslationsPath = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\entry_point_translations_to_add.json"

$content = Get-Content $translationsPath -Raw
$newTranslations = Get-Content $newTranslationsPath -Raw

# Remove the closing ] and }
$content = $content.TrimEnd()
$content = $content.Substring(0, $content.LastIndexOf(']'))

# Remove the opening [ and closing ] from new translations
$newTranslations = $newTranslations.Trim()
$newTranslations = $newTranslations.Substring(1, $newTranslations.Length - 2)

# Append new translations
$finalContent = $content + "," + [Environment]::NewLine + $newTranslations + [Environment]::NewLine + "  ]" + [Environment]::NewLine + "}"

# Write back
$finalContent | Set-Content $translationsPath -Encoding UTF8

Write-Host "Translations merged successfully!"
