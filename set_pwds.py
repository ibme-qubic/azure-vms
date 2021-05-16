import sys
import os

PWDS = "vm_pass.txt"
NUM_USERS = 4

# VMs with IDs 50+ are intended for tutors:
# 50: North Europe (Ireland): Alan Stone (Mon)
# 51: West Europe: Fatemah (Tue), Ilaria (Sat)
# 52: West US: Moss (Sat, Wed)
# 53: UK South: Flora (Sat), Ahlam (Mon), Colette (Wed)
# 54: UK South: Joana (Sat, Wed), Yunus (Sun), Nic (Mon)
# 55: South East Asia: Tee Yee Kai (Sun)
# 56: UK South: Paula (all sessions)
# 57: UK South: Michael (all sessions)

REGION_VMS = {
    "westeurope" : [1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 26, 39, 40, 41, 42, 51],
    "uksouth" : [4, 13, 14, 15, 28, 53, 54, 56, 57],
    "eastasia" : [23, 38, 43, 49],
    "centralindia" : [29],
    "eastus" : [3, 16, 17, 18, 19, 20, 24, 27, 45, 46, 47, 48],
    "westus" : [21, 22, 25, 52], # extra?
    "northeurope" : [50],
    "southeastasia" : [55],
    "westcentralus" : [30, 31, 32, 33, 34, 44],
    "japaneast" : [35, 36],
    "southcentralus" : [37],
    "uaenorth" : [],
    "australiaeast" : [],
    "brazilsouth" : [],
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

print("Passwords on VM ismrm%i.%s.cloudapp.azure.com" % (vm_id, vm_region))
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
        "ismrm%i.%s.cloudapp.azure.com" % (vm_id, vm_region), 
        username="azureuser", password=rootpwd, look_for_keys=False
    )

    #sudo_cmd(client, "sed -i 's/allow_channels=true/allow_channels=false/g' /etc/xrdp/xrdp.ini")

    for user_idx in range(4):
        sudo_cmd(client, "passwd user%i" % (user_idx+1), [vm_passwords[user_idx], vm_passwords[user_idx]])

        #sudo_cmd(client, "umount /home/user%i/thinclient_drives" % (user_idx+1))
        #sudo_cmd(client, "rm -rf /home/user%i/thinclient_drives" % (user_idx+1))
    client.close()

print("Passwords are: ")
for user_idx in range(4):
    print("user%i: %s" % (user_idx+1, vm_passwords[user_idx]))
