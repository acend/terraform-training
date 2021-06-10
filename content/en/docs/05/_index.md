---
title: "5. Outputs"
weight: 5
sectionnumber: 5
---

Now that we have our content created we should use it somewhere. As we have for e.g. a VM in the cloud, we need some information about the created content to access it!


## Task {{% param sectionnumber %}}.1: Output

We will create another file called `outputs.tf`. Here we will list all the content we want to get, so we can use it.

```bash
output "random_result" {
    description = "random string created by terraform"
    value       = random_string.random
}
```

By again applying this config with Terraform, you will see how this value appears at the end of the command.

```
Outputs:

random_result = 3033
```

You are also able to use those output values by using:

```bash
terraform output random_result
terraform output -raw random_result
```

Can you see the different between those outputs?


## Task {{% param sectionnumber %}}.2: Taint

This command can be used to mark an object as "damaged". Do so, causes Terraform to replace the project on the next apply:

```
terraform taint random_string.acr
```

Since Terraform 0.15.2 you also can do this with the option `-replace <terraform object name>` e.g:

```
terraform apply -replace="random_string.acr"
```

The random number should now be recreated.


## Task {{% param sectionnumber %}}.3: Untaint

You are also able to untaint your tained object by:

```
terraform untaint random_string.acr
```

