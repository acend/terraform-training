---
title: "2. First steps"
weight: 2
sectionnumber: 2
onlyWhen: azure
---

{{% alert title="Important" color="secondary" %}}
Please make sure you completed [the setup](../../setup/) before you continue with this lab.
{{% /alert %}}


## First Steps

Start your IDE in an empty project directory and launch a UNIX shell.  

The upcoming labs will always refer to the root folder of your exercises. Store it in an environment variable
to access it quicker:

```bash
export LAB_ROOT=`pwd`
```

Now create a new directory:

```bash
mkdir $LAB_ROOT/first_steps
cd $LAB_ROOT/first_steps
```

Create a new file named `main.tf` in your working directory and paste the following:

```terraform
output "hello" {
  value = "Hello Terraform!"
}
```

Now run the commands
```bash
terraform init
terraform apply
```

Terraform asks for your confirmation, enter `yes`:
```
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Well done! You created your first "Hello World!" in Terraform.  
The next chapters will explain what we've actually just done here - let's move on!
