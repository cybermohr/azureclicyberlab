#!/bin/bash

# Name: buildCyberRange.sh
# Version: 1.0
# Author: Brian P. Mohr
# Email: brian@cybermohr.com
# Date: 2018-05-24

# Collect the varibles to build the environment
read -p "Enter Your Azure Username (leave blank if you are using two-factor authentication): " Username
read -p "Enter a name for the Resource Group you want to create: " myResourceGroup
read -p "Enter a Username to be used for the administrator on the VMs: " AdminUser
echo "Enter a Password to be used for the administrator on the VMs (between 12 and 123 characters): "
read -s AdminPassword

# Login to Azure
if [ -z "$Username" ]; then
    az login
else
    az login -u $Username
fi


# Create a resource group.
echo "Creating Resource Group..."
az group create --name $myResourceGroup --location eastus

# Create a virtual network.
echo "Creating Virtual Network..."
az network vnet create --resource-group $myResourceGroup --name myVnet --subnet-name mySubnet --dns-servers "10.0.0.254"

#####################Windows 2016 Domain Controller#######################

# Create a virtual machine.
echo "Creating Windows 2016 Domain Controller Virtual Machine..."
az vm create \
    --resource-group $myResourceGroup \
    --name SRV-DC01 \
    --location eastus \
    --image win2016datacenter \
    --size Standard_DS2_v2 \
    --private-ip-address "10.0.0.254" \
    --storage-sku Standard_LRS \
    --admin-username $AdminUser \
    --admin-password $AdminPassword

# Attach a new data disk to the virtual machine.
echo "Creating and Attaching Data Disk for Domain Controller..."
az vm disk attach \
  --resource-group $myResourceGroup \
  --vm-name SRV-DC01 \
  --disk DC01-DataDisk \
  --size-gb 10 \
  --sku Standard_LRS \
  --caching None \
  --new

# Add Active Directory role to the virtual machine
echo "Adding Active Directory Role to Domain Controller..."
az vm extension set \
  --publisher Microsoft.Compute \
  --version 1.8 \
  --name CustomScriptExtension \
  --vm-name SRV-DC01 \
  --resource-group $myResourceGroup \
  --settings '{"commandToExecute":"powershell.exe Install-WindowsFeature -Name AD-Domain-Services"}'

#####################Windows 10 Client#######################

# Create a virtual machine.
echo "Creating Windows 10 Virtual Machine..."
az vm create \
    --resource-group $myResourceGroup \
    --name WIN10 \
    --location eastus \
    --image "MicrosoftWindowsDesktop:Windows-10:RS3-Pro:16299.248.1" \
    --size Standard_DS2_v2 \
    --storage-sku Standard_LRS \
    --no-wait \
    --admin-username $AdminUser \
    --admin-password $AdminPassword

#####################Windows 2012R2 Server#######################

# Create a virtual machine.
echo "Creating Windows 2012 R2 Virtual Machine..." 
az vm create \
    --resource-group $myResourceGroup \
    --name SRV-2012 \
    --location eastus \
    --image Win2012Datacenter \
    --size Standard_DS2_v2 \
    --storage-sku Standard_LRS \
    --no-wait \
    --admin-username $AdminUser \
    --admin-password $AdminPassword

#####################Kali Linux#######################

# Create a virtual machine.
echo "Creating Kali Linux Virtual Machine..."
az vm create \
    --resource-group $myResourceGroup \
    --name KALI \
    --location eastus \
    --image "kali-linux:kali-linux:kali:2017.3.0" \
    --size Standard_DS2_v2 \
    --storage-sku Standard_LRS \
    --no-wait \
    --admin-username $AdminUser \
    --admin-password $AdminPassword
