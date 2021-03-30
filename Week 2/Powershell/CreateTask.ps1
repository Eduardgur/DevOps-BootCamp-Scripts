param(
    [string]$TaskName,
    [int]$TimeToWait
)

function Create-Script{
    Write-Host "Creatting hello world script" -ForegroundColor Cyan
    New-Item -Path "C:\" -Name "mytask.txt" -Value "Hello bootcamp" -Force | Out-Null
    Write-Host "C:\mytask.txt has been created" -ForegroundColor Green
}

function Create-Task {
    param (
        [string]$TaskName
    )
    $TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 1000) 
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable 
    $TaskAction = New-ScheduledTaskAction -Execute "notepad" -Argument 'c:\mytask.txt'
    $Task = New-ScheduledTask -Trigger $TaskTrigger -Action $TaskAction -Settings $TaskSettings
    Register-ScheduledTask -TaskName $TaskName -InputObject $Task -Force | Out-Null
    Write-Host "$TaskName has been created" -ForegroundColor Green
}

function Change-TaskStatus {
    param(
        [string]$TaskName,
        [int]$TaskTtl
    )
        Disable-ScheduledTask -TaskName $TaskName | Out-Null
        Write-Host "$TaskName has been disabled" -ForegroundColor Green 
        
}

function Get-AllTasks {
    Write-Host "Printing all schedualed tasks: " -ForegroundColor Cyan
    Get-ScheduledTask | %{Write-Host $_.TaskName -ForegroundColor Yellow}
}

function Start-SleepTimer{
    param(
        [int]$SecToCount
    )
    for($i = $SecToCount; $i -gt 0 ; $i--){
        Write-Host "$i.." -NoNewline
        Start-Sleep -Seconds 1
    }
}

Create-Script
Write-Host "Creating new task. Name: $TaskName, Ttl: $TimeToWait" -ForegroundColor Cyan
Create-Task -TaskName $TaskName 
Write-Host "Disabling $TaskName in $TimeToWait seconds" -ForegroundColor Cyan
Start-SleepTimer -SecToCount $TimeToWait
Change-TaskStatus -TaskName $TaskName -TaskTtl $TimeToWait
Get-AllTasks