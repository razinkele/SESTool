$translationsPath = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"

# Read the JSON file
$json = Get-Content $translationsPath -Raw | ConvertFrom-Json

# Create a hashtable to track seen English keys
$seen = @{}
$uniqueTranslations = @()

foreach ($translation in $json) {
    $enKey = $translation.en

    if (-not $seen.ContainsKey($enKey)) {
        # First occurrence, keep it
        $seen[$enKey] = $true
        $uniqueTranslations += $translation
    } else {
        Write-Host "Removing duplicate: $enKey"
    }
}

Write-Host "Original count: $($json.Count)"
Write-Host "Unique count: $($uniqueTranslations.Count)"
Write-Host "Duplicates removed: $($json.Count - $uniqueTranslations.Count)"

# Convert back to JSON and save
$uniqueTranslations | ConvertTo-Json -Depth 10 | Set-Content $translationsPath -Encoding UTF8

Write-Host "Duplicates removed successfully!"
