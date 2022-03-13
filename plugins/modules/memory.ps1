#!powershell
# -*- coding: utf-8 -*-

# (c) 2022, John McCall (@lowlydba)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.lowlydba.sqlserver.plugins.module_utils._SqlServerUtils

Import-ModuleDependency
$ErrorActionPreference = "Stop"

# Get Csharp utility module
$spec = @{
    supports_check_mode = $true
    options = @{
        max = @{type = "int"; required = $false; default = 0 }
    }
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlCredential = Get-SqlCredential -Module $module
$sqlInstance = $module.Params.sql_instance
$max = $module.Params.max
$checkMode = $module.CheckMode
$module.Result.changed = $false

# Set max memory for SQL Instance
try {
    if ($checkMode) {
        # Make an equivalent output
        $server = Connect-DbaInstance -SqlInstance $sqlInstance -SqlCredential $sqlCredential
        $output = [PSCustomObject]@{
            ComputerName = $server.ComputerName
            InstanceName = $server.ServiceName
            SqlInstance = $server.DomainInstanceName
            Total = $server.PhysicalMemory
            MaxValue = $max
            PreviousMaxValue = $server.Configuration.MaxServerMemory.ConfigValue
        }
    }
    else {
        # Set max memory
        $setMemorySplat = @{
            SqlInstance = $sqlInstance
            SqlCredential = $sqlCredential
            Max = $max
            EnableException = $true
        }
        $output = Set-DbaMaxMemory @setMemorySplat
    }

    if ($output.PreviousMaxValue -ne $max) {
        $module.Result.changed = $true
    }

    $resultData = ConvertTo-SerializableObject -InputObject $output
    $module.Result.data = $resultData
    $module.ExitJson()
}
catch {
    $module.FailJson("Error setting max memory.", $_)
}
