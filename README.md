Ad-Hoc Automation on Azure with Terraform and Ansible

This project provisions four Ubuntu VMs on Microsoft Azure using Terraform and manages them with Ansible ad-hoc commands. The goal is to rapidly spin up a development environment, establish passwordless SSH, and run automation tasks across multiple hosts without writing a playbook.

Objective:

- Deploy 4 Linux VMs on Azure with Terraform

- Configure passwordless SSH (SSH key authentication)

- Create an Ansible inventory with host groups

- Execute Ansible ad-hoc commands to:

- Verify connectivity

- Check system info (whoami, uptime, disk, memory)

- Install packages (htop, nginx)

- Manage services (nginx)

Tools Used:
Tool	Purpose
- Terraform	Infrastructure as Code (provision Azure VMs)
-Azure CLI	Cloud authentication and resource management
- Ansible	Remote automation (ad-hoc mode)
- Ubuntu 22.04	VM operating system

Project Structure
.
├── terraform/
│   ├── main.tf
│   ├── terraform.tfstate
│   └── variables.tf (optional)
├── inventory.ini
└── README.md

Deployment Steps:
1. Login to Azure
az login

2. Deploy infrastructure with Terraform
cd terraform
terraform init
terraform apply -auto-approve


Record the public IPs Terraform outputs.

Ansible Inventory

Create inventory.ini:

[web]
<vm0_ip>
<vm1_ip>

[app]
<vm2_ip>

[db]
<vm3_ip>

[all:vars]
ansible_user=azureuser
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

SSH Access Validation

Verify passwordless SSH:

ssh azureuser@<vm_ip>


No password should be required.

Ansible Ad-Hoc Commands
Ping all hosts
ansible all -i inventory.ini -m ping

Whoami
ansible all -i inventory.ini -m command -a "whoami"

Uptime
ansible all -i inventory.ini -m command -a "uptime"

Install htop on all VMs
ansible all -i inventory.ini -m apt -a "name=htop state=present" --become

Install and start nginx on web servers only
ansible web -i inventory.ini -m apt -a "name=nginx state=present" --become
ansible web -i inventory.ini -m service -a "name=nginx state=started enabled=yes" --become

Disk usage
ansible all -i inventory.ini -m command -a "df -h"

Memory usage
ansible all -i inventory.ini -m command -a "free -m"

Expected Results

- Terraform successfully provisions 4 VMs

- SSH key authentication works on all hosts

- Ansible ad-hoc commands run against the correct groups

- nginx is installed and running only on web servers

Reflection :

- Ad-hoc Ansible commands are excellent for quick checks, troubleshooting, and running fast one-time tasks across multiple machines. For repeatable workflows, configuration management, and long-term automation, Ansible playbooks provide a more scalable and maintainable approach.

- This project demonstrates using Terraform for infrastructure and Ansible for configuration in an efficient and controlled way.
