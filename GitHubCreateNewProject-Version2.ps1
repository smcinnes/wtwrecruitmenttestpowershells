<#
.Synopsis
   Sets the database owner to SA for all Databases in the Instance.
.DESCRIPTION
   This script will evaluate each database on the specified instance, and if the owner
   property is set to anything other than sa, it will change it to SA.
.EXAMPLE
   ./Set-DatabaseOwnerToSA.ps1 WS12SQL
.EXAMPLE
   ./Set-DatabaseOwnerToSA.ps1 WS12SQL\SQL01
#>
<#
 This needs to be run as Administrator on your machine for the first time
#>

$gitHubUserName =  'smcinnes';
$gitHubUserPatToken = '099a22c0e21987fdd44809b6b3a5202e2d9a37a0';
$gitHubApiToken = '{0}:{1}' -f $gitHubUserName, $gitHubUserPatToken; 


<#
.Description
Show-Menu displays a menu for the user to determine what test they want to send 
#>
function Show-Menu
{
    param (
        [string]$Title = 'Technical Test Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for Software Engineering Test."
    Write-Host "2: Press '2' for Full Stack Developer Test."
    Write-Host "3: Press '3' for SDET Test."
    Write-Host "Q: Press 'Q' to quit."
}


function DoesUserNameExist($gitHubUserName) {

    <#
        .SYNOPSIS
        Function will use the GitHub API to validate whether the GitHub username exists 

        .PARAMETER gitHubUserName

        .EXAMPLE
        DoesUserNameExist -gitHubUserName 'octocat'

        Will validate that the user octocat exists and return true

    #>

    try {
        Get-GitHubUser -User $gitHubUserName
    } catch {
       return $false;
    }

   return $true;
}

function GenerateCandidateRepoName($candidateGitHubName, $selectedTest){

    $repoName = $candidateGitHubName;

    switch($selectedTest){
       1 {$repoName = '{0}_{1}' -f $candidateGitHubName,"SoftwareEngineerTest"}
       2 {$repoName = '{0}_{1}' -f $candidateGitHubName,"FullStackEngineerTest"}
       3 {$repoName = '{0}_{1}' -f $candidateGitHubName,"SDETTest"}
    }
   return $repoName ;
}


function GenerateGitHubApiHeaders($userName, $patToken){

    $token = '{0}:{1}' -f $userName, $patToken;
    # Sets the Header & Body of the GitHub Rest API request
    return @{
        Authorization = 'Basic {0}' -f ([System.Convert]::ToBase64String([char[]]$token));
    };
}


function CloneTemplateRepo($authenticationToken, $gitHubUserName, $templateProjectName, $newRepoName) {

    $projectToClone = ("github.com/{0}/{1}" -f $gitHubUserName, $templateProjectName )

    # Clones the project we want to use as template
    git clone -q --bare https://$authenticationToken@$projectToClone

    cd .\$templateProjectName.git;


    #Push Original
    git push -q --mirror "https://www.github.com/smcinnes/$newRepoName";

}

function GetTemplateRepoName($selectedTest){
   $result=switch($selectedTest)
    {
       1 {'softwareengineer-technicaltest-template'}
       2 {'fullstackdeveloper-technicaltest-template'}
       3 {'sdet-technicaltest-template'}
    }

    return $result;
}

function CreateNewRepoForCandidate($candidatesRepoName, $gitHubUserName, $gitHubUserPatToken){

    $Body = @{
        name =  $candidatesRepoName;
        private = 'true';
    } | ConvertTo-Json ;


    # Calls the GitHub API to Create a new REPO
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-RestMethod -Headers (GenerateGitHubApiHeaders $gitHubUserName $gitHubUserPatToken) -Body $Body -Uri https://api.github.com/user/repos -Method POST
}

function AddCandidateToRepo($gitHubUserName, $gitHubUserPatToken, $candidateGitHubUserName, $newRepoName){


    Invoke-RestMethod -Headers (GenerateGitHubApiHeaders $gitHubUserName $gitHubUserPatToken) -Uri https://api.github.com/repos/$gitHubUserName/$newRepoName/collaborators/$candidateGitHubName -Method PUT

}


# Will Check to see if any requuired modules are installed on this machine
Check-PreRequisitesAreInstalled


Show-Menu –Title 'My Menu'

$selection = Read-Host "Please select the test you would like to be sent"

# Validates the Input 
if($selection -eq 'q') {
    return;
}



$candidateGitHubName = Read-Host 'What is the candidates GitHub Account Name?'

## validate that the candidate name entered exists
if (($candidateGitHubName) -And (DoesUserNameExist($candidateGitHubName))){
    Write-Host("user is valid and exists") ;
} 
else
{
    Write-Host("Username is invalid or does not exist") ;
    return;
}



## STEP 1 - Create a new REPO in which to store the test 
$newRepoName = GenerateCandidateRepoName $candidateGitHubName $selection


Write-Host "---Creating New Repo----" + $newRepoName

#New-GitHubRepository $newRepoName;
CreateNewRepoForCandidate $newRepoName $gitHubUserName $gitHubUserPatToken

## STEP 2 - Clone from the template 
CloneTemplateRepo $gitHubApiToken $gitHubUserName (GetTemplateRepoName $selection) $newRepoName


#Step 3 - Add Candidate as a collaborator to the Repo
AddCandidateToRepo $gitHubUserName  $gitHubUserPatToken $candidateGitHubName  $newRepoName ;