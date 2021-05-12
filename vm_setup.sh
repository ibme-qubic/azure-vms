#!/bin/bash

#### Update and install required software
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install xfce4 xrdp firefox pwgen gedit build-essential unzip -y

#### Enable remote desktop
sudo systemctl enable xrdp
echo xfce4-session >$HOME/.xsession
echo ". $HOME/.profile" >$HOME/.xsessionrc
# The following fixes crash on Windows client
# see https://github.com/neutrinolabs/xrdp/issues/302
sudo sed -i 's/allow_channels=true/allow_channels=false/g' /etc/xrdp/xrdp.ini
sudo service xrdp restart

#### Mount data disk
# WARNING: Azure does not guarantee which disk (sda, sdb, sdc, etc) will be the data disk so we need
# to figure it out based on the fact that we know the size of the data disk is 10Gb. If this size is changed
# the line below must be changed to reflect it or it will not work!
DATADISK=`lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd" |grep "10G" |awk '{print $1}'`
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/${DATADISK}
sudo mkfs -t ext4 /dev/${DATADISK}1
sudo mkdir /data && sudo mount /dev/${DATADISK}1 /data
#UUID=`blkid |grep ${DATADISK}1: |awk -F \" '{print $4}'`
UUID=`lsblk -f |grep ${DATADISK}1 |awk '{print $3}'`
echo -e "UUID=$UUID /data\text4\tdefaults\t0\t2" > datadisk_fstab
sudo sh -c 'cat datadisk_fstab >> /etc/fstab'
#rm datadisk_fstab

#### Install FSL
# We run the installer in quiet (non interactive) mode
FSLDIR=/usr/local/fsl
sudo wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
sudo python fslinstaller.py -E -q -d $FSLDIR
# libquadmath0 is required for FSL
sudo apt-get install libquadmath0 -y
# This patch is required in FSL 6.0.4 to make the ASL gui work
sudo sed -i -e 's/(parent=parent, ready=ready)/(ready=ready, raiseErrors=True)/' $FSLDIR/python/oxford_asl/gui/preview_fsleyes.py
# Set up environment only for azureuser - the -E switch doesn't appear to work
python fslinstaller.py -e -q -d $FSLDIR

#### Add tutorial users. 
# We only plan to use one but create a few so we
# can if necessary put people on the same VM as another
for USER in qp user1 user2 user3 user4
do
    sudo adduser $USER
    echo xfce4-session | sudo tee -a /home/$USER/.xsession
    echo ". /home/$USER/.profile" | sudo tee -a /home/$USER/.xsessionrc
    sudo cp $HOME/.profile /home/$USER/
    sudo mkdir -p /home/$USER/Desktop
    sudo cp $HOME/*.desktop /home/$USER/Desktop/
    sudo chmod a+x /home/$USER/Desktop/*.desktop
    sudo chown $USER /home/$USER/.xsession* /home/$USER/.profile /home/$USER/Desktop /home/$USER/Desktop/*.desktop
    sudo chgrp $USER /home/$USER/.xsession* /home/$USER/.profile /home/$USER/Desktop /home/$USER/Desktop/*.desktop
    sudo ln -s /data /home/$USER/course_data
    sudo ln -s /data /home/$USER/Desktop/course_data
done

#### Install quantiphyse in the qp user
# Needs to be run interactively using su at present
# because cannot get su and conda to work correctly in batch...
#$FSLDIR/fslpython/bin/conda init bash
#. /home/azureuser/.bashrc
#conda create -n qp python=3.7
#conda activate qp
#conda install tensorflow tensorflow-probability
#pip install quantiphyse
#pip install quantiphyse-cvr quantiphyse-dsc quantiphyse-asl quantiphyse-cest quantiphyse-qbold tensorflow-probability quantiphyse-fsl oxasl==0.1.12
#conda install pyside2 sphinx rst2pdf
