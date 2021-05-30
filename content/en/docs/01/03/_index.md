---
title: "Outputs"
weight: 12
sectionnumber: 1.2
---

Now that we have our content created we should use it somewhere. As we have for e.g. a VM in the cloud, we need some information about the created content to access it!

## Output

We will create another file called `output.tf`. Here we will list all the content we want to get, so we can use it.

```bash
output "random_result" {
    description = "random string created by terraform"
    value       = random_string.random
}
```

By again applying this config with Terraform, you will see how this value appears at the end of the command.

You are also able to use those output values by using:

```bash
terraform output random_result
terraform output -raw random_result
```

Can you see the different between those outputs?

## Taint

TODO

## Untaint

TODO