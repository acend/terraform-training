---
title: "3.3. Outputs"
weight: 33
sectionnumber: 3.3
---

## Preparation

Finish the "Variables" exercise and navigate to the directory:
```bash
cd variables
```

## Step 1: Create outputs.tf

Create a new file named `outputs.tf` in your working directory and paste the following:
```terraform
output "number" {
  value = random_integer.number.result
  description = "random value created by terraform"
}
```

## Step 2: Apply the configuration

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

## Step 3: Access the output

If you just want to access the output value without running apply, you can just run:
```bash
terraform output number
terraform output -raw number
```

Can you spot the difference between the ouputs?

## Step 4: Handling sensitive output

Add the `sensitive` keyword to the output as followed:
```terraform
output "number" {
  value       = random_integer.number.result
  description = "random value created by terraform"
  sensitive   = true
}
```

This will mask the console output of the value. The output is still available by
explicitly specifying the name as followed:
```bash
terraform output number
```

## Try it out!

You can also print the the output in json format and use tools like `jq` to process it further:
```bash
terraform output -json | jq '.number.value'
```

This is useful when handling large data structures.