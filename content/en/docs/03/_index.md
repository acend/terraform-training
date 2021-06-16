---
title: "3. Local environment"
weight: 3
sectionnumber: 3
---

Here you will understand how you can plan and apply your config. After all the work is done you will also learn how to destroy your content.


## Task {{% param sectionnumber %}}.1: Creation

We will start with a simple example by creating a ressource ...
So start your editor of choice and insert the following lines:

```bash
resource "random_integer" "acr" {
  min = 1000
  max = 9999
}
```

Name the file `main.tf`


## Task {{% param sectionnumber %}}.2: Initialisation

Lets create an initial local setup by running:

```bash
terraform init
```

Output:

```
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/random...
- Installing hashicorp/random v3.1.0...
- Installed hashicorp/random v3.1.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```


## Task {{% param sectionnumber %}}.3: Planing

The planing will help Terraform to understand your configuration and verfiy the content ruffly.

```bash
terraform plan
```

You may see some output like:

```
Terraform will perform the following actions:

  # random_integer.acr will be created
  + resource "random_integer" "acr" {
      + id     = (known after apply)
      + min    = 1000
      + max    = 9999
      + result = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```


## Task {{% param sectionnumber %}}.4: Applying

After planing our content we will let Terraform create it by appliyng the configuration:

```bash
terraform apply
```

You will get asked, after a short repeating of the planing, if you really want to apply this. So type `yes`

Now you can use your created content.

```
random_integer.acr: Creating...
random_integer.acr: Creation complete after 0s [id=9437]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```


## Task {{% param sectionnumber %}}.5: Local state

After creating all the ressources you may ask now, wehre does Terraform has stored the data which has been created? As we are not in Cloud yet, where does your state live?

```bash
ls -l
```

You will find a file called `terraform.tfstate`. This file cointains all information about your whole Terraform run. Even your random number is saved here. Terraform will always have such a `tfstate` file to save all your configurations. It is used to compare your desired state against the real world.

In the AKS chapter we will learn how save this file into cloud itself a why this is recommended.


## Task {{% param sectionnumber %}}.6: Destruction

There are different ways to get rid of your content.

* by deleting the `main.tf` file
* by running `terraform destroy`


```bash
terraform destroy
```

You will again be asked, if you want destroy the content. After your decision the content has your desired state.

