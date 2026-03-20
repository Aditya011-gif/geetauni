
$path = "lib\screens\marketplace_screen.dart"
$content = Get-Content $path
$part1 = $content[0..440]
$part2 = "}"
$part3 = $content[1521..($content.Count-1)]

# Combine and write
# Check if $part3 is not null/empty to avoid issues if file shortened
if ($part3) {
    Set-Content -Path $path -Value ($part1 + $part2 + $part3)
    Write-Host "Fixed file successfully."
} else {
    Write-Host "Error: File seems shorter than expected."
}
