# **codilime interview project**
Demo nginx docker container deployment in Azure using IaC.

## List of contents:
1. [kv-deployment.bicep](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.bicep) <- KeyVault deployment Bicep template
2. [kv-deployment.parameters.json](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.parameters.json) <- KeyVault deployment JSON parameters file
3. [module-main.bicep](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.bicep) <- Hosting environment deployment Bicep main template
4. [module-main.parameters.json](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.parameters.json) <- Hosting environment deployment JSON parameters file
5. [module-nginxhello.bicep](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-nginxhello.bicep) <- Hosting environment deployment Bicep module template
6. [cloud-init.txt](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/cloud-init.txt) <- Linux cloud-init YAML configuration file
7. [deploy-template.ps1](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/deploy-template.ps1) <- PowerShell script deploying the templates
8. [diagram.py](https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/diagram.py) <- Python script illustrating deployed architecture using Diagrams library

## Architecture HLD:
![Architecture HLD image](https://github.com/acelebanski-dev/codilime-interview-project/blob/main/nginx-hello-diagram.png?raw=true)

## How to use:

Download templates, parameter files, cloud-init file and PowerShell script to your local machine or Azure Cloud Shell (e.g. using PowerShell cmdlets).

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.bicep -OutFile kv-deployment.bicep
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/kv-deployment.parameters.json -OutFile kv-deployment.parameters.json
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.bicep -OutFile module-main.bicep
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-main.parameters.json -OutFile module-main.parameters.json
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/module-nginxhello.bicep -OutFile module-nginxhello.bicep
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/cloud-init.txt -OutFile cloud-init.txt
Invoke-WebRequest -Uri https://raw.githubusercontent.com/acelebanski-dev/codilime-interview-project/main/deploy-template.ps1 -OutFile deploy-template.ps1
```

Modify the parameters and script variables so they match your location and environment. Then execute the PowerShell script.

```powershell
.\deploy-template.ps1
```

After a couple of minutes, test your deployment.