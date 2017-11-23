[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true,Position=1)]
    [Hashtable[]]$ParametersArray
)

$combinedParameters = @{};

$ParametersArray | % {
    $Parameters = $_
    $Parameters.Keys | % {
        $combinedParameters[ $_ ] = $Parameters[ $_ ]
    }
}

return $combinedParameters;