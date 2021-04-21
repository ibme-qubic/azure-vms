az account set --subscription "Research Unmanaged"

# Need means to remove all resources associated with VM
#az vm delete \
#  --resource-group rg-prj-rum-we-RA48HA-1 \
#  --name ismrm-img

az vm create \
  --resource-group rg-prj-rum-we-RA48HA-1 \
  --name ismrm-img \
  --public-ip-address-dns-name ismrm-img \
  --image UbuntuLTS \
  --size Standard_DS1_v2 \
  --data-disk-sizes-gb 10 \
  --storage-sku Standard_LRS \
  --nsg-rule SSH \
  --admin-username azureuser \
  --admin-password $1 \
  --output table

#  --custom-data vm_setup.sh \
#  --image /subscriptions/d75dbbe4-ac00-435f-8f41-8f7adba1dbce/resourceGroups/rg-prj-rum-we-RA48HA-1/providers/Microsoft.Compute/galleries/asl_vm_images/images/asl_course_vm_image/versions/1.0.0 \

# Open RDP port
az vm open-port \
  --resource-group rg-prj-rum-we-RA48HA-1 \
  --name ismrm-img \
  --port 3389 \
  --output table

