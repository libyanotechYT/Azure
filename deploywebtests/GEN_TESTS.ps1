## Import the data source ##
$csvwebsites = Import-Csv -Path appin.csv
## Array of Azure Datacenters
[array]$loclist = "emea-nl-ams-azr","emea-gb-db3-azr","emea-fr-pra-edge","emea-ru-msa-edge" ### Add locations to array

## Initialize empty hashtable for webtests and locations
$tests = @()
$locs = @()

### Build the hashtable for the Azure locations
foreach ($location in $loclist){
$locs += [pscustomobject]@{
id = $location
}
}

# Function to build a JSON parameters file for an Insights App
function genjson($id,$emaillist,$testlist){
    $jsonparams = [pscustomobject] @{
        '$schema'= "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#";
        "contentVersion" = "1.0.0.0";
        "parameters" = [pscustomobject] @{
        "appName" = [pscustomobject] @{"value" = "NOC-APPINSIGHT$id"}; ### Put the name here $testid is incremented
        "actiongroupname" = [pscustomobject] @{"value" = "wanistest"}; ### Put the name of the pre-created actiongroup here (actiongroup has the emails)
        "tests" = [pscustomobject] @{"value" = $testlist};
        }}
    return $jsonparams
    }
    


### initalize counter for websites and new parameter files ###
$counter = 0
$testid = 0
##############################################################



### For each website in the CSV (or your data source of choice) create its respective test section within the parameters json
foreach ($website in $csvwebsites){

$counter++ ### Every website processed increment counter

$name = $website.urls | Select-String -Pattern '\/\/(.*?)\.' | %{$_.Matches.Groups[1].value}  ### Extract name from the domain name

$tests += [pscustomobject] @{  ### Build a hashtable of the webtest
"name"= $name;
"url"= $website.urls; ## Header in the CSV is "urls"
"expected"= 200;
"frequency_secs"= 300;
"timeout_secs"= 30;
"failedLocationCount"= 1;
"description"= "A Test for the Website $name";
"guid"= New-Guid;
"locations" = [array]$locs;

}

if ($counter -eq 100 ){ ### when counter reaches 100 start building the main json (Due to the limitation of 100 webtests per app)
    $testid++
    $counter = 0


### First run the function building the hashtable and then convert to a JSON file
genjson $testid $emails $tests | ConvertTo-Json -Depth 10 | out-file azuredeploy.parameters$testid.json


### Deploy IT
#New-AzureRmResourceGroupDeployment -ResourceGroupName name -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters$testid.json

$tests = @() ## Empty the hashtable to be used for the next batch of 100
}

}

$testid++ ### Increment the parameter counter one last time for the remaining batch that doesnt equal 100


### First run the function building the hashtable and then convert to a JSON file
genjson $testid $emails $tests | ConvertTo-Json -Depth 10| out-file azuredeploy.parameters$testid.json


### Deploy IT
#New-AzureRmResourceGroupDeployment -ResourceGroupName name -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters$testid.json













