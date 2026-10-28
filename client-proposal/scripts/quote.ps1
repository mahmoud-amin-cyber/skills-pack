#requires -Version 5.1
<#
  quote.ps1 - the arithmetic of a quote, so it is never wrong and always consistent.

  Usage:
    powershell -NoProfile -File scripts/quote.ps1 -Hours 120 -Rate 250 -Currency EGP
    ... -BufferPercent 30 -TaxPercent 14 -DepositPercent 50
    ... -Hours 90 -Rate 40 -Currency USD -Tiers

  The rate belongs to the freelancer. Never pass a rate the user did not give you.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][double]$Hours,
    [Parameter(Mandatory = $true)][double]$Rate,
    [double]$BufferPercent = 20,
    [double]$TaxPercent = 0,
    [double]$DepositPercent = 40,
    [string]$Currency = 'EGP',
    [switch]$Tiers
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

if ($Hours -le 0) { throw 'Hours must be greater than 0.' }
if ($Rate -le 0) { throw 'Rate must be greater than 0. A rate you did not get from the user is a guess, not a quote.' }
if ($BufferPercent -lt 0 -or $BufferPercent -gt 100) { throw 'BufferPercent must be between 0 and 100.' }
if ($TaxPercent -lt 0 -or $TaxPercent -gt 100) { throw 'TaxPercent must be between 0 and 100.' }
if ($DepositPercent -lt 0 -or $DepositPercent -gt 100) { throw 'DepositPercent must be between 0 and 100.' }

function Format-Money {
    param([double]$Value)
    '{0:N0} {1}' -f $Value, $Currency
}

$base = $Hours * $Rate
$bufferHours = [math]::Round($Hours * ($BufferPercent / 100), 1)
$buffer = $bufferHours * $Rate
$subtotal = $base + $buffer
$tax = $subtotal * ($TaxPercent / 100)
$total = $subtotal + $tax
$deposit = $total * ($DepositPercent / 100)
$balance = $total - $deposit

Write-Host ''
Write-Host 'QUOTE' -ForegroundColor Cyan
Write-Host ('  hours            {0,8:N1}' -f $Hours)
Write-Host ('  rate             {0,8:N0} {1}/h' -f $Rate, $Currency)
Write-Host ('  base             {0,8:N0} {1}' -f $base, $Currency)
Write-Host ('  buffer {0,3}%      {1,8:N1} h = {2:N0} {3}' -f $BufferPercent, $bufferHours, $buffer, $Currency)
Write-Host ('  subtotal         {0,8:N0} {1}' -f $subtotal, $Currency)
if ($TaxPercent -gt 0) {
    Write-Host ('  tax {0,3}%         {1,8:N0} {2}' -f $TaxPercent, $tax, $Currency)
}
Write-Host ('  TOTAL            {0,8:N0} {1}' -f $total, $Currency) -ForegroundColor Green
Write-Host ''
Write-Host ('  deposit {0,3}%     {1,8:N0} {2}' -f $DepositPercent, $deposit, $Currency)
Write-Host ('  balance          {0,8:N0} {1}' -f $balance, $Currency)
Write-Host ('  per project hour {0,8:N0} {1}' -f ($total / $Hours), $Currency)

if ($Tiers) {
    Write-Host ''
    Write-Host 'TIERS' -ForegroundColor Cyan
    Write-Host ('  Basic    70%   {0,10}' -f (Format-Money ([math]::Round($total * 0.7))))
    Write-Host ('  Standard 100%  {0,10}   <- recommend' -f (Format-Money $total))
    Write-Host ('  Premium  140%  {0,10}' -f (Format-Money ([math]::Round($total * 1.4))))
}

Write-Host ''
Write-Host 'Reminder: the quote is only valid with scope.md and assumptions attached.' -ForegroundColor DarkGray
