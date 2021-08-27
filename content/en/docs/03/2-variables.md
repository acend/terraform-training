---
title: "3.2. Variables"
weight: 32
sectionnumber: 3.2
---

## Preparation

Create a new directory for this exercise:
```bash
mkdir variables
cd variables
```

## Step 1: Create variables.tf and main.tf

Create a new file named `variables.tf` in your working directory and paste the following:
```terraform
variable "random_min_value" {
  type        = number
  default     = 1000
  description = "define the min value of the random number"
}
```

Create a new file named `main.tf` in your working directory and paste the following:
```terraform
resource "random_integer" "number" {
  min = var.random_min_value
  max = 9999
}
```

### Explanation

It is best practice to put all required input variables in the file `variables.tf`.

The `type` and `description` arguments are optional but good practice.


## Step 2: Apply the configuration

Run the commands
```bash
terraform init
terraform apply
```

## Step 3: Change the default value

Now to see how Terraform applies changes to your configuration,
change the default value of `random_min_value` to `2000`:
```terraform
variable "random_min_value" {
  type        = number
  default     = 1000
  description = "define the min value of the random number"
}
```

Then run the command
```bash
terraform apply
```

And terraform will display the required changes to create the configured state. 
You will see a similar plan like this:
```bash
random_integer.number: Refreshing state... [id=8731]

Terraform used the selected providers to generate the following
execution plan. Resource actions are indicated with the following
symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # random_integer.number must be replaced
-/+ resource "random_integer" "number" {
      ~ id     = "8731" -> (known after apply)
      ~ min    = 1000 -> 2000 # forces replacement
      ~ result = 8731 -> (known after apply)
        # (1 unchanged attribute hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
  ```

## Step 4: Add a local variable

Sometimes you want to modify or derive a value from a variable. This can be achieved by declaring a "local" variable in 
a `locals` block. Add the following **on the first line** of `variables.tf`:
```terraform
locals {
  random_max_value = var.random_min_value + 31337
}
```

Then modify the `resource` block in `main.tf` as followed:
```terraform
resource "random_integer" "number" {
  min = var.random_min_value
  max = local.random_max_value
}
```


### Try it out!

Remove the `default = 2000` statement from the block and run `terraform apply`