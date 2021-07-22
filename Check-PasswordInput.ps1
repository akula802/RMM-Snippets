# For RMM scripts that change user passwords, this is a handy function to validate the input supplied at runtime
# The $illegalSubstring could be an array in a future version, so multiple banned words can be refused


$suppliedPassword = "@Password@"   # Labtech expands in-script variables using "@<variable>@" strings
$whitespace = '\s'
$illegalSubstring = "admin"
$numbers = '[\d]'
$uppers = '[A-Z]'
$specialChars = '[!@#%^&*+\-_~]'



Function PasswordCheck() {

    # Define the string parameter that this function accepts
    Param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyString()]
        [string]$Password
    )


    # Before doing anything, clear the $Error variable
    $Error.Clear()


    # Begin the function's main logic set
    try
        {
            # Make sure the password is not blank
            if (($Password | Select-Object -ExpandProperty Length) -eq 0)
                {
                    Write-Host The password cannot be blank!
                    exit
                }

            # Make sure the password is at least 15 characters long
            elseif (($Password | Select-Object -ExpandProperty Length) -lt 15)
                    {
                        Write-Host The password must be a minimum of 15 characters long!
                        exit
                    }
    
            # Make sure the password doesn't contain spaces
            elseif ($Password -match $whitespace)
                    {
                        Write-Host The password cannot contain any spaces!
                        exit
                    }

            # Make sure the password doesn't contain an 'illegal' substring
            elseif ($Password -match $illegalSubstring)
                    {
                        $message = "The password cannot contain " + ([char]34) + "$illegalSubstring" + ([char]34) + "!"
                        Write-Host $message
                        exit
                    }

            # Make sure the password contains aplha characters (NOTE: -notmatch is case insensitive)
            elseif ($Password -notmatch $uppers)
                {
                    Write-Host The password cannot be all numbers!
                    exit
                }

            # Make sure the password contains a capitalized letter (NOTE: -cmatch IS case sensitive, -match is not)
            elseif (!($Password -cmatch $uppers))
                    {
                        Write-Host The password must contain a capitalized letter!
                        exit
                    }

            # Make sure the password contains a number
            elseif ($password -notmatch $numbers)
                {
                    Write-Host The password must contain a number!
                    exit
                }

            # make sure the password contains a special character
            elseif ($Password -notmatch $specialChars)
                {
                    Write-Host The password must contain a special character from this set: $specialChars
                    exit
                }

            # If it gets to this point, the password is good enough
            else
                {
                    Write-Host Password was successfully verified.
                    exit
                }

        } # End try block

    catch
        {
            Write-Host Something terrible happened! Error details to follow:
            Write-Host $Error
        }

} # End function PasswordCheck



# Call the function
PasswordCheck -Password $suppliedPassword

