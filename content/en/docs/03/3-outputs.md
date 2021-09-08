---
title: "3.3. Outputs"
weight: 33
sectionnumber: 3.3
onlyWhen: azure
---


## Preparation

Finish the [Variables exercise](2-variables.md) and navigate to the directory:

```bash
cd $LAB_ROOT/basics/variables
```


## Step {{% param sectionnumber %}}.1: Create outputs.tf

Create a new file named `outputs.tf` in your working directory and add the following content:

```terraform
output "number" {
  value = random_integer.number.result
  description = "random value created by terraform"
}
```


## Step {{% param sectionnumber %}}.2: Apply the configuration

Run the command

```bash
terraform apply
```

and you should see output similar to this:

```bash
Plan: 0 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + number = 15670

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes


Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

number = 15670
```


## Step {{% param sectionnumber %}}.3: Access the output

If you just want to access the output value without running apply, you can just run:

```bash
terraform output number
terraform output -raw number
```

Can you spot the difference between the outputs?


## Step {{% param sectionnumber %}}.4: Handling sensitive output

Add the `sensitive` keyword to the `outputs.tf` file as followed:

```terraform
output "number" {
  value       = "The number is ${random_integer.number.result}"
  description = "random value created by terraform"
  sensitive   = true
}
```

This will mask the console output of the value. The output is still available by
explicitly specifying the name as followed:

```bash
terraform output number
```


## Try it out

You can also print the the output in json format and use tools like `jq` to process it further:

```bash
terraform output -json | jq '.number.value'
```

This is useful when handling large JSON data structures.
