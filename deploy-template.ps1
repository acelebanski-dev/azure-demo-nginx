# !!! Connect to Azure first (or use Cloud Shell) and select your subscription before executing this script !!!

# Download cloud-init file for Linux VM configuration
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/cloud-init.txt -OutFile cloud-init.txt
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.bicep -OutFile kv-deployment.bicep
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.parameters.json -OutFile kv-deployment.parameters.json
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.bicep -OutFile module-main.bicep
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.parameters.json -OutFile module-main.parameters.json
#Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-nginxhello.bicep -OutFile module-nginxhello.bicep

# Create resource group for KeyVault template deployment
$rg = 'ne-demo-rg-keyvault'
$location = 'northeurope'
New-AzResourceGroup -Name $rg -Location $location

# Deploy the Nginx Hello template to created resource group
$password =  ("!@#$%^&*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".tochararray() | Sort-Object {Get-Random})[0..8] -join '' | ConvertTo-SecureString -AsPlainText
$outputs = New-AzResourceGroupDeployment `
-Name KvBicepDeployment `
-ResourceGroupName $rg `
-TemplateFile kv-deployment.bicep `
-TemplateParameterFile kv-deployment.parameters.json `
-secretValue $password

# Retrieve the outputs from KeyVault template deployment
foreach ($key in $outputs.Outputs.keys) {
    if ($key -eq "kvName") {
        $kvName = $outputs.Outputs[$key].value
    }
    elseif ($key -eq "kvResourceGroupName") {
        $kvResourceGroupName = $outputs.Outputs[$key].value
    }
    elseif ($key -eq "secretName") {
        $secretName = $outputs.Outputs[$key].value
    }
}

# Create resource group for Nginx Hello template deployment
$rg = 'ne-demo-rg-nginx-hello'
New-AzResourceGroup -Name $rg -Location $location

# Deploy the Nginx Hello template to created resource group
New-AzResourceGroupDeployment `
-Name NginxBicepDeployment `
-ResourceGroupName $rg `
-TemplateFile module-main.bicep `
-TemplateParameterFile module-main.parameters.json `
-kvName $kvName `
-kvResourceGroupName $kvResourceGroupName `
-secretName $secretName