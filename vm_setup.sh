# Update and install required software
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install xfce4 xrdp firefox pwgen gedit -y
sudo systemctl enable xrdp
echo xfce4-session >$HOME/.xsession
sudo service xrdp restart

# Set local user password
passwd

# Add new users
for USER in asl1 asl2 asl3 asl4
do
#    sudo adduser $USER
    sudo cp $HOME/.xsession $HOME/.xsessionrc $HOME/.profile /home/$USER/
    sudo chown $USER /home/$USER/.xsession* /home/$USER/.profile
    sudo chgrp $USER /home/$USER/.xsession* /home/$USER/.profile
done

# Install FSL
sudo wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
sudo python fslinstaller.py -E -q
sudo apt-get install libquadmath0 -y
sudo sed -i -e 's/(parent=parent, ready=ready)/(ready=ready, raiseErrors=True)/' $FSLDIR/python/oxford_asl/gui/preview_fsleyes.py 

# Mount data disk 
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc
sudo mkfs -t ext4 /dev/sdc1
sudo mkdir /data && sudo mount /dev/sdc1 /data
# FIXME add to FSTAB:
# UUID=ff0a1d74-cd6f-4127-885b-bd4be0292a0e	/data	ext4	defaults	0	2

cd /data
sudo wget https://fsl.fmrib.ox.ac.uk/fslcourse/downloads/asl.tar.gz
sudo tar -xzf asl.tar.gz
