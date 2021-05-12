# Create a VM from an existing image
#
# $1: VM name
# $2: region
# $3: admin password

VMNAME=$1
REGION=$2
PWD=$3

# Basic subscription info
SUBS=d75dbbe4-ac00-435f-8f41-8f7adba1dbce
RG=rg-prj-rum-we-RA48HA-1

# Name of the image gallery, image defition and image version
SIG_NAME=vm_images
IMAGE_DEF_NAME=ismrm-image-def
IMAGE_VERSION=1.0.0

VMSIZE=Standard_D4_v3
DATADISK_SIZE=10

echo "Starting"
az vm create --resource-group $RG \
             --image /subscriptions/$SUBS/resourceGroups/$RG/providers/Microsoft.Compute/galleries/$SIG_NAME/images/$IMAGE_DEF_NAME/versions/$IMAGE_VERSION \
             --name $VMNAME \
             --location $REGION \
             --public-ip-address-dns-name $VMNAME \
             --size $VMSIZE \
             --nsg-rule SSH \
             --admin-username azureuser \
             --admin-password $PWD \
             --output table
echo "Created VM"
#--data-disk-sizes-gb $DATADISK_SIZE \
#--storage-sku Standard_LRS \
            
# Open RDP port
az vm open-port \
  --resource-group $RG \
  --name $VMNAME \
  --port 3389 \
  --output table
echo "Opened RDP port"
