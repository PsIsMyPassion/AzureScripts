#Pull a report together from the various admin roles around M365 and Azure.
#Admin role accounts from the Compliance center, Exchange, Azure, and Azure subsciptions.

#Connections Needed
connect-azaccount
Connect-IPPSSession
Connect-MGGraph -scopes "RoleManagement.Read.Directory"

$memberResult = @()
#Get Compliance Center and Exchange role group members
$RoleGroups = Get-RoleGroup
foreach ($group in $RoleGroups) {
    $roleGroupMembers = Get-RoleGroupMember $group.name
    if ($roleGroupMembers) {
        foreach ($member in $roleGroupMembers) {
            $memberResult += [PSCustomObject]@{
                Name            = $member.name
                Alias           = $member.alias
                RoleType        = "Compliance Center/Exchange"
                RoleName        = $group.name
                AZResourceScope = "N/A"
            }
        }
    }
}

#Azure Subscription Access
$subs = Get-AzSubscription
foreach ($sub in $subs) {
    $subID = "/subscriptions/" + $sub.Id
    $subAssign = Get-AzRoleAssignment -Scope $subID -IncludeClassicAdministrators
    foreach ($assignment in $subAssign) {
        $memberResult += [PSCustomObject]@{
            Name             = $assignment.DisplayName
            Alias            = $assignment.SignInName
            RoleType         = "Azure Subscription"
            RoleName         = $assignment.RoleDefinitionName
            SubscriptionName = $sub.Name
        }
    }
}

#Azure Roles
$roles = Get-MgDirectoryRole
foreach ($role in $roles) {
    $roleMembers = @()
    $roleMembers += Get-MgDirectoryRoleMember -DirectoryRoleId $role.id
    if ($roleMembers) {
        foreach ($memb in $roleMembers) {
            $mgLookup = get-mguser -userID $memb.id | select UserPrincipalName, DisplayName
            $memberResult += [PSCustomObject]@{
                Name            = $mgLookup.DisplayName
                Alias           = $mgLookup.UserPrincipalName
                RoleType        = "Azure Role"
                RoleName        = $role.DisplayName
                AZResourceScope = "N/A"
            }
        }
    }
} 

$memberResult = $memberResult | sort Name
$memberResult | out-gridview