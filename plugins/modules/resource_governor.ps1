#!powershell
# -*- coding: utf-8 -*-

# (c) 2022, John McCall (@lowlydba)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.lowlydba.sqlserver.plugins.module_utils._SqlServerUtils

Import-ModuleDependency
$ErrorActionPreference = "Stop"

$spec = @{
    supports_check_mode = $true
    options = @{
        enabled = @{type = 'bool'; required = $false; default = $true }
        classifier_function = @{type = 'str'; required = $false }
    }
}

# Get Csharp utility module
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec, @(Get-LowlyDbaSqlServerAuthSpec))
$sqlInstance = $module.Params.sql_instance
$sqlCredential = Get-SqlCredential -Module $module
$enabled = $module.Params.enabled
$classifierFunction = $module.Params.classifier_function
$checkMode = $module.CheckMode
$module.Result.changed = $false

try {
    $rg = Get-DbaResourceGovernor -SqlInstance $sqlInstance -SqlCredential $sqlCredential
    $rgClassifierFunction = $rg.ClassifierFunction.Name
    if ($rg.Enabled -eq $enabled) {
        if (($rgClassifierFunction -eq $classifierFunction) -or ($null -eq $rgClassifierFunction -and $classifierFunction -eq "NULL")) {
            $output = $rg
        }
    }
    else {
        if ($checkMode) {
            $output = $rg
            $output.ClassifierFunction = $classifierFunction
            $output.Enabled = $enabled
        }
        else {
            $rgHash = @{
                SqlInstance = $sqlInstance
                SqlCredential = $sqlCredential
                ClassifierFunction = $classifierFunction
                EnableException = $true
                Confirm = $false
            }
            if ($enabled) {
                $output = Set-DbaResourceGovernor @rgHash -Enabled
            }
            else {
                $output = Set-DbaResourceGovernor @rgHash -Disabled
            }
        }
        $module.Result.changed = $true
    }

    $resultData = ConvertTo-SerializableObject -InputObject $output
    $module.Result.data = $resultData
    $module.ExitJson()
}
catch {
    $module.FailJson("Setting resource governor failed.", $_)
}
