$logpath = "C:\inetpub\logs\"
$daystokeep = 30

get-childitem -LiteralPath $logpath -Include *.log -Recurse |
  where-object { -not $_.PSIsContainer } |
  where-object { $_.LastWriteTime -lt ((get-date).AddDays((-1 * $daystokeep))) } |
  remove-item
