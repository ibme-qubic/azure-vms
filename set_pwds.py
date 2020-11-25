import sys
import os

PWDS = "vm_pass.txt"
NUM_USERS = 4

REGION_VMS = {
    "westeurope" : [1, 2, 3, 4, 10, 11, 23, 24, 25],
    "northeurope" : [5, 6, 7, 8, 9, 12, 20, 21, 22, 26, 27, 28],
    "eastus" : [13, 14],
    "westus" : [15],
    "uaenorth" : [17],
    "australiaeast" : [18],
    "brazilsouth" : [19],
}

def sudo_cmd(client, cmd, user_input=[]):
    stdin, stdout, stderr = client.exec_command("sudo -S " + cmd)
    if "--sudo-pwd" in sys.argv:
        stdin.write(rootpwd + "\n")
        stdin.flush()
    for line in user_input:
        stdin.write(line + "\n")
        stdin.flush()
    stdin.channel.shutdown_write()
    print(f'{stdout.read().decode("utf8")}')
    print(f'{stderr.read().decode("utf8")}')
    stdin.close()
    stderr.close()
    stdout.close()

if len(sys.argv) < 2:
    print("Usage: set_pwds.py <VM id> [--set] [--sudo-pwd]")
    sys.exit(1)

vm_id = int(sys.argv[1])
vm_region = None
for region, vm_ids in REGION_VMS.items():
    if vm_id in vm_ids:
        vm_region = region
        break
if not vm_region:
    print("Region could not be found for VM basilcourse%i" % vm_id)
    sys.exit(1)

print("Passwords on VM basilcourse%i.%s.cloudapp.azure.com" % (vm_id, vm_region))
passwords = [p.strip() for p in open(PWDS).readlines()]
vm_passwords = passwords[(vm_id-1)*NUM_USERS:vm_id*NUM_USERS]

if "--set" in sys.argv:
    import getpass
    rootpwd = getpass.getpass("Admin Password: ")

    # Start SSH
    import paramiko
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        "basilcourse%i.%s.cloudapp.azure.com" % (vm_id, vm_region), 
        username="azureuser", password=rootpwd, look_for_keys=False
    )

    sudo_cmd(client, "sed -i 's/allow_channels=true/allow_channels=false/g' /etc/xrdp/xrdp.ini")
    sudo_cmd(client, "apt install -y gedit")

    for user_idx in range(4):
        sudo_cmd(client, "passwd asl%i" % (user_idx+1), [vm_passwords[user_idx], vm_passwords[user_idx]])

        sudo_cmd(client, "umount /home/asl%i/thinclient_drives" % (user_idx+1))
        sudo_cmd(client, "rm -rf /home/asl%i/thinclient_drives" % (user_idx+1))
    client.close()

print("Passwords are: ")
for user_idx in range(4):
    print("asl%i: %s" % (user_idx+1, vm_passwords[user_idx]))