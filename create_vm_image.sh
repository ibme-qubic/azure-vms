# Script to turn a template VM into an image from which we can create more VMs
#
# Note that before running this script the VM must be 'deprovisioned' by
# logging in via ssh and running:
#
#     sudo waagent -deprovision+user
#
# Args: $1=name of template VM already set up and prepared
#
# Lots of Azure gotchas possible here. It seems that an image definition
# must always come from the same image so when you create a new template VM
# you have to change the image name and the image definition name. 
# I'm sure this should not be necessary (what's the image definition version
# for?) but I just got errors otherwise.

# Basic subscription info
SUBS=d75dbbe4-ac00-435f-8f41-8f7adba1dbce
RG=rg-prj-rum-we-RA48HA-1

# Name of the image gallery, image defition and image name/version
IMAGE_NAME=ismrm-image
SIG_NAME=vm_images
IMAGE_DEF_NAME=ismrm-image-def
IMAGE_VERSION=1.0.0

# Default region - can replicate afterwards
REGION=westeurope

# Metadata associated with image definition
PUBLISHER=UofNottinghamPhysimals
OFFER=IsmrmPracticals
SKU=IsmrmVm

echo "Starting"

## Deallocate and generalize the VM then create an image from it
az vm deallocate --resource-group $RG \
                 --name $1 \
                 --output table
echo "Deallocated"

az vm generalize --resource-group $RG \
                 --name $1 \
                 --output table
echo "Generalized"

az image create --resource-group $RG \
                --name $IMAGE_NAME \
                --source $1 \
                --output table
echo "Image created"

az sig create --resource-group $RG \
              --gallery-name $SIG_NAME \
              --output table
echo "Created SIG"

# Put the image in the shared image gallery
# Only need to create the image definition once

az sig image-definition create --resource-group $RG \
                               --gallery-name $SIG_NAME \
                               --gallery-image-definition $IMAGE_DEF_NAME \
                               --publisher $PUBLISHER \
                               --offer $OFFER \
                               --sku $SKU \
                               --os-type Linux \
                               --os-state generalized \
                               --output table
echo "Image def created"

az sig image-version create --resource-group $RG \
                            --gallery-name $SIG_NAME \
                            --gallery-image-definition $IMAGE_DEF_NAME \
                            --gallery-image-version $IMAGE_VERSION \
                            --target-regions $REGION \
                            --replica-count 1 \
                            --managed-image /subscriptions/$SUBS/resourceGroups/$RG/providers/Microsoft.Compute/images/$IMAGE_NAME \
                            --output table
echo "Image version created"

