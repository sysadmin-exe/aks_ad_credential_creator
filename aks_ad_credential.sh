#!/bin/bash

#This bash script will create Azure AD credentials for AKS cluster deployment. 
#Server App and client App IDs will be created and exported to system varialbes that can be used in terraform plan. 

#link used: https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli 
#AKS creation tutorial : https://codersociety.com/blog/articles/terraform-azure-kubernetes

# Create the Azure AD application
serverApplicationId=$(az ad app create --display-name aksappidserver --identifier-uris "https://aksappiderver" --query appId -o tsv)

# Update the application group membership claims
az ad app update --id $serverApplicationId --set groupMembershipClaims=All

# Create a service principal for the Azure AD application
az ad sp create --id $serverApplicationId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset --name $serverApplicationId --credential-description "AKSPassword" --query password -o tsv)

#assign permissions
az ad app permission add --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $serverApplicationId

#create AD client app
clientApplicationId=$(az ad app create --display-name "${aksname}Client" --native-app --reply-urls "https://${aksname}Client" --query appId -o tsv)
    
az ad sp create --id $clientApplicationId

oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $clientApplicationId --api $serverApplicationId

export TF_VAR_prefix=learn-aks
export TF_VAR_client_app_id=$(echo $clientApplicationId)
export TF_VAR_server_app_id=$(echo $serverApplicationId)
export TF_VAR_server_app_secret=$(echo $serverApplicationSecret)
export TF_VAR_tenant_id=$(az account show --query tenantId -o tsv)
