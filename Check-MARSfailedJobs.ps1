# Script to search event logs for records of failed Azure Backup (MARS) jobs
# Intended to be run daily via RMM, and create alerts based on output
# Makes sure a failed backup job did NOT occurr today, and that a backup DID occur within the last 3 days



# Initial Variables
$logName = "CloudBackup"
$eventIds = @('5','10','11','12','13','14','16','18')
$today = Get-Date
$3daysAgo = $today.AddDays(-3)



# Make sure the MARS agent log exists, exit if it does not
Try
    {
        $error.Clear()
        $logExists = [System.Diagnostics.EventLog]::SourceExists($logName)

        if ($logExists -eq $false)
            {
                Write-Host The $logName log was not found on this machine.
                exit
            }
    }
Catch
    {
        Write-Host Something bad happened, unable to query Application and Services logs.
        exit
    }



# Query event log for failure events recorded TODAY, and return result for RMM to read
Try
    {
    $failedBackups = Foreach ($eventId in $eventIds)
        {
            Get-WinEvent -LogName $logName | Select-Object TimeCreated, Id, LevelDisplayName, Message | Where-Object {$_.Id -eq $eventId} | Where-Object {$_.TimeCreated -eq $today} | Select-Object -First 1

            # An empty or null output means no backup failures were reported
            if (!$failedBackups)
                {
                    # Make sure there are successful backups being recorded, and the lack of failures isn't just because the app is paused, etc.
                    $lastSuccessfulBackup = Get-WinEvent -LogName $logName | Select-Object TimeCreated, Id, LevelDisplayName, Message | Where-Object {$_.Id -eq '3'} | Select-Object -First 1

                    if ($lastSuccessfulBackup.TimeCreated -lt $3daysAgo)
                        {
                            # The last successful backup was more than 3 days ago
                            Write-Host The last successful backup was more than 3 days ago.
                            exit

                        } # End if $lastSuccessfulBackup check

                    else
                        {
                            # This is the ideal condition, everything is working
                            Write-Host No failures were recorded today, and a backup has completed in the past 3 days.
                            exit
                        } # End else for $lastSuccessfulBackup check

                } # End if $failedBackups loop

            # Any result here indicates a backup failure WAS recorded
            else
                {
                    Write-Host A backup failure was recorded today.
                    Write-Host $failedBackups
                    exit
                }

        } # End Foreach $eventId loop

    } # end Try

Catch
    {
        Write-Host Failed to query $logName log.
        exit
    } # End catch

