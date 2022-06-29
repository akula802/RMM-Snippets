# https://help.kaseya.com/webhelp/EN/restapi/9040000/#37320.htm

<#

The following summarizes the algorithm used to generate the GET /auth payload for a given username and password. Italics indicate variable names.

Generate a random integer, store in variable called Random.
Compute the SHA-256 hash of the admin password, store in RawSHA256Hash.
Compute the SHA-256 hash of the concatenated string Password + Username, store in CoveredSHA256HashTemp.
Compute the SHA-256 hash of the concatenated string CoveredSHA256HashTemp + Random, store in CoveredSHA256Hash.
Compute the SHA-1 hash of the admin password, store in RawSHA1Hash.
Compute the SHA-1 hash of the concatenated string Password + Username, store in CoveredSHA1HashTemp.
Compute the SHA-1 hash of the concatenated string CoveredSHA1HashTemp + Random, store in CoveredSHA1Hash.
Create a comma separated concatenated string with the following strings and variables.
“user=” + Username
“pass2=” + CoveredSHA256Hash
“pass1=” + CoveredSHA1Hash
“rpass2=” + RawSHA256Hash
“rpass1=” + RawSHA1Hash
“rand2=” + Random

You should end up with the string:
“user={Username},pass2={CoveredSHA256Hash},pass1={CoveredSHA1Hash},rpass2={RawSHA256Hash},rpass1={RawSHA1Hash},rand2={Random}”

Base64 encode this string.

Use the encoded value in the Authorization header with a Basic scheme.

GET /auth
Authorization: Basic
dXNlcj1rYWRtaW4scGFzczI9ZjE5ZWFmYzY3ZWY5MzJjMjBkMTlmZGQ1ZmIyZTY1NjBkY2U5YTk1YWFhYjEwNjczMjQ5
YTU3YTkzODY2ZTQxZCxwYXNzMT0wZGMwZmY5YzBkNGVkMDRlODJiYzZmYTk0ZTY3NTQzMjFhMDgyMzc1LHJhbmQyPTk5
NDY1NixycGFzczI9ZjE5ZWFmYzY3ZWY5MzJjMjBkMTlmZGQ1ZmIyZTY1NjBkY2U5YTk1YWFhYjEwNjczMjQ5YTU3YTkz
ODY2ZTQxZCxycGFzczE9MGRjMGZmOWMwZDRlZDA0ZTgyYmM2ZmE5NGU2NzU0MzIxYTA4MjM3NSx0d29mYXBhc3M9OnVu
ZGVmaW5lZA==


$mystring = "Some string and text content here"
$mystream = [IO.MemoryStream]::new([byte[]][char[]]$mystring)
Get-FileHash -InputStream $mystream -Algorithm SHA256

#>



# Function to hash strings
Function Hash-String() {

    # Define the string parameters that this function requires
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$RawString,
        [ValidateSet('SHA1', 'SHA256')]
        [string]$Algorithm
    )


    # Create a memory stream from the string
    $mystream = [IO.MemoryStream]::new([byte[]][char[]]$RawString)

    # Hash the string from the stream
    $hashed = Get-FileHash -InputStream $mystream -Algorithm $Algorithm

    # Return the result
    return ($hashed).Hash


} # End function Hash-String



# Function to base64 encode strings
Function Base64Encode-String() {

    # Define the string parameters that this function requires
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$RawString
    )

    # Do the encoding
    $string64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($RawString))
    

    # Return the result
    return $string64


} # End function Base64Encode-String



# The API URL
$apiURL = "https://<your_kaseya_server>"



# Generate a random INT
$Random = Get-Random -Minimum 100000 -Maximum 2147483647
Write-Host `r`n
Write-Host Random Int: $Random
Write-Host `r`n



# First prompt for the username and password
$vsa_username = Read-Host Enter your VSA username
$vsa_password = Read-Host Enter your VSA password
Write-Host `r`n
$vsa_concatted = $vsa_password + $vsa_username



# The building blocks of the auth string - SHA256 parts
$RawSHA256Hash = Hash-String -RawString $vsa_password -Algorithm SHA256
$CoveredSHA256HashTemp = Hash-String -RawString $vsa_concatted -Algorithm SHA256
$hash256Rand = $CoveredSHA256HashTemp + $Random
$CoveredSHA256Hash = Hash-String -RawString $hash256Rand -Algorithm SHA256



# The building blocks of the auth string - SHA1 parts
$RawSHA1Hash = Hash-String -RawString $vsa_password -Algorithm SHA1
$CoveredSHA1HashTemp = Hash-String -RawString $vsa_concatted -Algorithm SHA1
$hash1Rand = $CoveredSHA1HashTemp + $Random
$CoveredSHA1Hash = Hash-String -RawString $hash1Rand -Algorithm SHA1



# The auth string
$authString = "user={$vsa_username},pass2={$CoveredSHA256Hash},pass1={$CoveredSHA1Hash},rpass2={$RawSHA256Hash},rpass1={$RawSHA1Hash},rand2={$Random}"
Write-Host Auth String: $authString
Write-Host `r`n`r`n



# The base64 encoded auth string, to be used when calling the API
$authString64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authString))



# Write the auth string to screen
Write-Host $authString64
Write-Host `r`n`r`n



# This last bit borrowed shamelessly from: https://github.com/aaronengels/KaseyaVSA/blob/main/functions/New-ApiAccessToken.ps1
# Define parameters for Invoke-WebRequest cmdlet
	$params = [ordered] @{
		Uri         	= '{0}/api/v1.0/auth' -f $apiUrl
		Method      	= 'GET'
		ContentType 	= 'application/json; charset=utf-8'
		Headers     	= @{'Authorization' = "Basic $authString64"}
	}



# Fetch new access token
$response = Invoke-RestMethod @params
$authToken = $response.result.token
Write-Host Token: $authToken

