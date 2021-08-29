---
title: "Setup"
weight: 1
type: docs
menu:
  main:
    weight: 1
---

The Terraform lab exercises require the installation and configuration of a few applications. This page will
help you getting started.


## Web shell

Your Terraform lab trainer will provide you personal credentials to your web shell.  
All required CLI tools and an IDE are installed and ready to use.


## Local installation

The exercises assume a UNIX environment. In case you are working under Windows, be advised to install the
**Windows Subsystem for Linux** as documented here: https://docs.microsoft.com/en-us/windows/wsl/install-win10


### CLI Tools

Please install the following applications:

* `terraform` - Terraform CLI  
  There are two methods for installing `terraform`:
  * **Recommended:** Install and manage different versions with `tfenv` from  
    https://github.com/tfutils/tfenv  
    Run the following commands to install the latest version of Terraform:
    ```bash
    tfenv install latest
    tfenv use latest    
    ```
  * **Alternative:** Follow the instructions on the Hashicorp website at  
  https://learn.hashicorp.com/tutorials/terraform/install-cli
* `az` - Azure CLI  
   **Note:** This is used for the Azure workshop only!  
   See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
* `kubectl` - Kubernetes CLI  
   See https://kubernetes.io/docs/tasks/tools/
* `helm` - Helm - Kubernetes package manager CLI (optional)
   See https://helm.sh/docs/intro/install/
* `jq` - JSON query CLI (optional)  
  See https://stedolan.github.io/jq/download/

Make sure `terraform` is installed correctly and found in your `PATH` by running:

```bash
terraform version
```

**Optional:** To install `bash` autocompletion, run the following command and restart your shell:

```bash
echo "complete -C `which terraform` terraform" >> ~/.bashrc
```


### IDE

Install a text editor of your choice. PyCharm Community Edition IDE with the HCL plugin is recommended for its
powerful features like resource and attribute auto-complete, refactoring etc.


#### PyCharm

To install PyCharm, follow the instructions:

* Goto https://www.jetbrains.com/pycharm/download
* add plugin **HashiCorp Terraform / HCL language support**


#### Visual Studio Code

Visual Studio Code offers Terraform support via extension, follow the instructions:

* Goto https://code.visualstudio.com/download
* add the extension **HashiCorp Terraform**
