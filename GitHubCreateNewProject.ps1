

$templateProjectName = Read-Host 'What is the name of the template repo?'
$candidateGitHubName = Read-Host 'What is the candidates GitHub Account Name?'
$projectToClone = ("github.com/smcinnes/{0}" -f $templateProjectName )



$newProjectName = ("{0}_{1}" -f $candidateGitHubName,$templateProjectName )


# Creates New Project within GitHub in which to store the new candidates name
$Token =  'smcinnes:099a22c0e21987fdd44809b6b3a5202e2d9a37a0';  # username:pattoken (this should be changed!)
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token) ;

# Sets the Header & Body of the GitHub Rest API request
$Headers = @{
    Authorization = 'Basic {0}' -f $Base64Token;
    };

$Body = @{
    name =  $newProjectName;
    private = 'true';
} | ConvertTo-Json
;

# Calls the GitHub API to Create a new REPO
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Headers $Headers -Body $Body -Uri https://api.github.com/user/repos -Method POST


# Clones the project we want to use as template
git clone -q --bare https://$Token@$projectToClone

cd .\$templateProjectName.git;


#Push Original
git push -q --mirror "https://www.github.com/smcinnes/$newProjectName";


# Clears Temp Directory
cd ..;
#rm -rf $templateProjectName.git;
Remove-Item -LiteralPath "$templateProjectName.git" -Force -Recurse


## Adds users
Invoke-RestMethod -Headers $Headers -Uri https://api.github.com/repos/smcinnes/$newProjectName/collaborators/$candidateGitHubName -Method PUT


