import os
os.environ["PATH"] += os.pathsep + 'C:\Program Files\Graphviz\bin'

from diagrams import Diagram, Cluster, Edge
from diagrams.azure.network import NetworkInterfaces
from diagrams.azure.network import NetworkSecurityGroupsClassic
from diagrams.azure.network import ApplicationGateway
from diagrams.azure.network import PublicIpAddresses
from diagrams.azure.compute import VMSS
from diagrams.azure.compute import VMLinux
from diagrams.custom import Custom
from urllib.request import urlretrieve

with Diagram("Demo Nginx container environment in Azure", show=False, filename="nginx-hello-diagram", direction="LR"):
    
    with Cluster("Public Internet"):
        pip1 = PublicIpAddresses("Bastion Public IP")
        pip2 = PublicIpAddresses("App GW Public IP")

    with Cluster("VNET1"):
        with Cluster("AzureBastionSubnet"):
            diagrams_url = "https://github.com/David-Summers/Azure-Design/blob/master/PNG_Azure_All/Bastion.png?raw=true"
            diagrams_icon = "bastion.png"
            urlretrieve(diagrams_url, diagrams_icon)
            bastion = Custom("Bastion", diagrams_icon)

        with Cluster("AppGwSubnet"):
            appgw1 = ApplicationGateway("App GW")

        with Cluster("ServerSubnet"):
            with Cluster("VM instances"):
                instances = [
                    VMLinux("VM2 - Zone 3") - NetworkInterfaces("VM2 NIC"),
                    VMLinux("VM1 - Zone 1") - NetworkInterfaces('VM1 NIC')
                ]
            nsg = NetworkSecurityGroupsClassic('NSG')
            vmss = VMSS("VM Scale Set")
        
        pip1 \
        >> Edge(label="Listen HTTPS (AAD Auth)", color="blue") \
        >> bastion

        pip2 \
        >> Edge(label="Listen HTTP", color="red") \
        >> appgw1

        instances - nsg - vmss \
        << Edge(color="red") \
        << appgw1

        bastion \
        >> Edge(color="blue") \
        >> vmss