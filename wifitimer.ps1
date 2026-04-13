# This script is required to run as Administrator.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


<#                                     Wifitimer
A script to schedule internet connection/disconnection daily, weekly, or by date.
 ____________________________________________________________________________________________

Enter the timeframes when you want the internet to disconnect.
To specify a specific date out of the year, write "(Month) (Day) (Year) 0 (StartTime) (EndTime)"
To specify a recurring day of the week, write "0 0 0 (DayofWeek) (StartTime) (EndTime)"
To specify a daily recurring interval, "0 0 0 0 StartTime EndTime"
Express all values as integers.(i.e., month by 1-12, Day of Week as 1-7, times as 24-hour values)
If the interval goes to the next day, schedule as two entries(one going up to midnight, and the next one after midnight.)
#>
#              month(1-12) dayofmonth year(2026) dayofweek(1-7) starttime endtime
$schedule = @("0           0          0          0              1100      1400"
)

Write-Output "wifitimer script is now running... press q to quit."
Write-Output $(Get-Date) "wifitimer started" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
while ($input.Character -ne "q")
{
  # Get current Get-Datetime information
  $current_time=$(Get-Date -UFormat "%R" | ForEach-Object { $_ -replace ":", ""})
  $current_day=$(Get-Date -UFormat "%d") -replace "^0+", "" 
  $current_month=$(Get-Date -UFormat "%m") -replace "^0+", ""
  $current_year=$(Get-Date -UFormat "%Y")
  $current_dayofweek= $([int](Get-Date).DayOfWeek + 1)

  # Check the current internet connection status
  if (Get-NetAdapter | Select-Object Status | Out-String -Stream | sls "Up"){
    $STATUS=1
  }else {
    $STATUS=0
  }

  # Parse each line in the schedule
  for ($line = 0; $line -lt $schedule.Length; $line++){
    $parse = -split ($schedule[$line])
    $year=($parse[2])
    $month=($parse[0])
    $day=($parse[1])
    $dayofweek=($parse[3])
    $start=($parse[4])
    $end=($parse[5])

    # Validate inputs, numbers only
    if (((-not ($year -match "^[0-9]+$")) -or (-not ($month -match "^[0-9]+$")) -or (-not ($day -match "^[0-9]+$")) -or 
      (-not ( $dayofweek -match "^[0-9]+$")) -or (-not ( $start -match "^[0-9]+$")) -or ( -not ($end -match "^[0-9]+$" ))))
      {
      Write-Output $(Get-Date) "Invalid schedule entry, check to make sure all values are numbers." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
      Exit 1
      }

    # Make sure proper format is followed for yearly, weekly, and daily schedule entries
    if (($year -ne 0) -and (($month -eq 0 -or ( $day -eq 0) -or ( $dayofweek -ne 0))))
    { 
      Write-Output $(Get-Date) "Invalid schedule entry. Specify year, month and day, or leave all as 0 for daily recurrence." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
      Exit 1
    }
    if (($month -ne 0) -and (($year -eq 0 -or ( $day -eq 0) -or ( $dayofweek -ne 0))))
    {
      Write-Output $(Get-Date) "Invalid schedule entry. Specify year, month and day, or leave all as 0 for daily recurrence." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
      Exit 1
    }
    if (($day -ne 0) -and (($month -eq 0 -or ( $year -eq 0) -or ( $dayofweek -ne 0))))
    {
      Write-Output $(Get-Date) "Invalid schedule entry. Specify year, month and day, or leave all as 0 for daily recurrence." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append 
      Exit 1
    }
    if (($dayofweek -ne 0) -and (($month -ne 0) -or ($year -ne 0) -or ($day -ne 0)))
    {
      Write-Output $(Get-Date) "Invalid schedule entry. Specify either weekly or specific day out of the year, not both." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append 
      Exit 1
    }
    if ($start -gt $end)
    {
      Write-Output $(Get-Date) "Invalid schedule entry. Start time is after end time. Create two entries if scheduling through to next day." | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append 
      Exit 1
    }

    # Disconnect on specifiied Get-Date-time of year
    if (($year -eq $current_year) -and ($month -eq $current_month) -and ($day -eq $current_day) -and ($current_time -ge $start) -and ($current_time -lt $end))
    {
      if ($STATUS -eq 1){
        Disable-NetAdapter -Name "Wi-Fi*" -Confirm:$false -ErrorAction SilentlyContinue
        Disable-NetAdapter -Name "Ethernet*" -Confirm:$false -ErrorAction SilentlyContinue
        Write-Output $(Get-Date) "networking disabled" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append 
        Start-Sleep -Seconds 1
      }
      $DISCONNECTED=1
      break
    }

    # Disconnect weekly on specified day of week
    if (($year -eq 0) -and ($month -eq 0) -and ($day -eq 0) -and ($dayofweek -eq $current_dayofweek) -and ($current_time -ge $start) -and ($current_time -lt $end)){
      if ($STATUS -eq 1){
        Disable-NetAdapter -Name "Wi-Fi*" -Confirm:$false  -ErrorAction SilentlyContinue
        Disable-NetAdapter -Name "Ethernet*" -Confirm:$false  -ErrorAction SilentlyContinue
        Write-Output $(Get-Date) "networking disabled" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append 
        Start-Sleep -Seconds 1
      }
      $DISCONNECTED=1
      break
    }

    # Disconnect daily at specified time
    if ($year -eq 0 -and( $month -eq 0 ) -and ( $day -eq 0 ) -and  ( $dayofweek -eq 0 ) -and ( $current_time -ge $start ) -and ( $current_time -lt $end)){
      if (($STATUS -eq 1)){
        Disable-NetAdapter -Name "Wi-Fi*" -Confirm:$false  -ErrorAction SilentlyContinue
        Disable-NetAdapter -Name "Ethernet*" -Confirm:$false  -ErrorAction SilentlyContinue
        Write-Output $(Get-Date) "networking disabled" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
        Start-Sleep -Seconds 1
      }
      $DISCONNECTED=1
      break
    }
    $DISCONNECTED=0
  }

  # reconnect outside of the specified intervals
  if ($DISCONNECTED -eq 0){
    if ($STATUS -eq 0){
    Enable-NetAdapter -Name "Wi-Fi*" -Confirm:$false  -ErrorAction SilentlyContinue
    Enable-NetAdapter -Name "Ethernet*" -Confirm:$false  -ErrorAction SilentlyContinue
    Write-Output $(Get-Date) "networking enabled" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
    Start-Sleep -Seconds 1
    }
  }
  if([console]::KeyAvailable)
    {
        $input = [System.Console]::ReadKey() 

        switch ( $input.key)
        {
            q { $input="q" }
        }
    } 
  Start-Sleep -Seconds 0.1
}

# reconnect internet before quitting
Enable-NetAdapter -Name "Wi-Fi*" -Confirm:$false  -ErrorAction SilentlyContinue
Enable-NetAdapter -Name "Ethernet*" -Confirm:$false  -ErrorAction SilentlyContinue
Write-Output $(Get-Date) "networking enabled" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
Write-Output "`nQuitting program..."
Write-Output $(Get-Date) "program succesfully exited" | Out-File -FilePath $PSScriptRoot\wifitimer.log -Append
