# Basic subscription info
SUBSNAME="Research Unmanaged"
SUBS=d75dbbe4-ac00-435f-8f41-8f7adba1dbce
RG=rg-prj-rum-we-RA48HA-1

# VM size
#VMSIZE=Standard_DS2_v2
#VMSIZE=Standard_A2M_v2
VMSIZE=Standard_D4_v3
DATADISK_SIZE=10

az account set --subscription "$SUBSNAME"

# FIXME Need means to remove all resources associated with VM
#az vm delete \
#  --resource-group $RG \
#  --name $1

az vm create \
  --resource-group $RG \
  --name $1 \
  --public-ip-address-dns-name $1 \
  --image UbuntuLTS \
  --size $VMSIZE \
  --data-disk-sizes-gb $DATADISK_SIZE \
  --storage-sku Standard_LRS \
  --nsg-rule SSH \
  --admin-username azureuser \
  --admin-password $2 \
  --output table

#  --custom-data vm_setup.sh \
#  --image /subscriptions/$SUBS/resourceGroups/$RG/providers/Microsoft.Compute/galleries/asl_vm_images/images/asl_course_vm_image/versions/1.0.0 \

# Open RDP port
az vm open-port \
  --resource-group $RG \
  --name $1 \
  --port 3389 \
  --output table

# SSH across setup files and scripts
scp vm_setup.sh desktop_files/*.desktop azureuser@$1.westeurope.cloudapp.azure.com:
