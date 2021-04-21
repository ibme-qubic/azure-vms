import sys
import os
import argparse

import getpass
import paramiko

class ArgumentParser(argparse.ArgumentParser):
    """
    ArgumentParser for program options
    """

    def __init__(self, **kwargs):
        argparse.ArgumentParser.__init__(self, prog="vm_admin", add_help=False, **kwargs)
        self.add_argument("--create-master", action="store_true", default=False, help="Create master VM")
        self.add_argument("--init-master", action="store_true", default=False, help="Initialize master VM")
        self.add_argument("--create-users", action="store_true", default=False, help="Create users on instance VM")
        self.add_argument("--passwords", default="vm_pass.txt", help="File containing passwords for instance VMs")
        self.add_argument("--master-name", default="ismrm-img", help="Name of master VM for operations on master VM")
        self.add_argument("--master-region", default="westeurope", help="Region of master VM")
        self.add_argument("--master-setup-script", default="vm_setup.sh", help="Master setup script")
        self.add_argument("--instance", type=int, help="Instance number for operations on instances")
        self.add_argument("--num-users", type=int, default=4, help="Number of users on each instance")

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

def run_script(client, script):
    sftp_client = client.open_sftp()
    sftp_client.put(os.path.basename(script), script)
    sftp_client.close()

    stdin, stdout, stderr = client.exec_command("sh %s" % os.path.basename(script))
    stdin.channel.shutdown_write()
    print(f'{stdout.read().decode("utf8")}')
    print(f'{stderr.read().decode("utf8")}')
    stdin.close()
    stderr.close()
    stdout.close()

def create_master(options):
    print("Creating VM: %s" % options.master_name)
    while 1:
        admin_pwd = getpass.getpass("Admin Password: ")
        admin_pwd2 = getpass.getpass("Repeat admin password: ")
        if admin_pwd != admin_pwd2:
            print("Passwords do not match\n")
        else:
            break

    os.system("""
        az vm create \
            --resource-group rg-prj-rum-we-RA48HA-1 \
            --name %s \
            --public-ip-address-dns-name %s \
            --image UbuntuLTS \
            --size Standard_DS1_v2 \
            --data-disk-sizes-gb 10 \
            --storage-sku Standard_LRS \
            --nsg-rule SSH \
            --admin-username azureuser \
            --admin-password %s \
            --output table""" % (options.master_name, options.master_name, admin_pwd))
    os.system("""
        az vm open-port \
            --resource-group rg-prj-rum-we-RA48HA-1 \
            --name %s \
            --port 3389 \
            --output table""" % options.master_name)

def init_master(options):
    print("Initializing master VM: %s" % options.master_name)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    admin_pwd = getpass.getpass("Admin Password: ")
    client.connect(
        "%s.%s.cloudapp.azure.com" % (options.master_name, options.master_region), 
        username="azureuser", password=admin_pwd, look_for_keys=False
    )
    run_script(client, options.master_setup_script)

def main():
    options = ArgumentParser().parse_args()

    if options.create_master:
        create_master(options)
    if options.init_master:
        init_master(options)

if __name__ == "__main__":
    main()
