$csvwebsites = Import-Csv -Path appin.csv


$loclist = "emea-nl-ams-azr","emea-gb-db3-azr","emea-fr-pra-edge","emea-ru-msa-edge" ### Add locations to array
[array]$emails = "email@email.com" ### Add emails to array
$tests = @()
$locs = @()

foreach ($location in $loclist){
$locs += [pscustomobject]@{
id = $location
}
}

### For each website in the CSV (or your data source of choice) create its respective test section within the parameters json
foreach ($website in $csvwebsites){

$name = $website | Select-String -Pattern '\/\/(.*?)\.' | %{$_.Matches.Groups[1].value}

$tests += [pscustomobject] @{
"name"= $name;
"url"= $website.urls;
"expected"= 200;
"frequency_secs"= 300;
"timeout_secs"= 30;
"failedLocationCount"= 1;
"description"= "A Test for the Website $name";
"guid"= New-Guid;
"locations" = [array]$locs;
}


}

### Putting the parameters json all together ###
$jsonparams = [pscustomobject] @{
    '$schema'= "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#";
    "contentVersion" = "1.0.0.0";
    "parameters" = [pscustomobject] @{
    "appName" = [pscustomobject] @{"value" = "APPINSIGHT1"};
    "emails"= [pscustomobject] @{"value"= $emails};
    "tests" = [pscustomobject] @{"value" = $tests};

}
}

### Convert from Hashtable to JSON
$jsonparams | ConvertTo-Json -Depth 10 | out-file azuredeploy.parameters.json



### Convert from Hashtable to JSON
$jsonparams | ConvertTo-Json -Depth 10 | out-file azuredeploy.parameters.json



### Deploy this thing
Connect-AzureRmAccount
New-AzureRmResourceGroupDeployment -ResourceGroupName **** -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json







