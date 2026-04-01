---
title: "5.7. Testing"
weight: 57
sectionnumber: 5.7
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/advanced/testing
cd $LAB_ROOT/advanced/testing
```

Optional: Create empty files:

```bash
touch {main,variables,outputs,versions}.tf
```


## Step {{% param sectionnumber %}}.1: Module under test

We will test a small module that generates a formatted greeting string. First, create the module
directory and source files:

```bash
mkdir -p modules/greeting
```

Create `modules/greeting/variables.tf`:

```terraform
variable "name" {
  description = "Name to greet."
  type        = string
}

variable "language" {
  description = "Language code: 'en' or 'de'."
  type        = string
  default     = "en"

  validation {
    condition     = contains(["en", "de"], var.language)
    error_message = "language must be 'en' or 'de'."
  }
}
```

Create `modules/greeting/outputs.tf`:

```terraform
output "message" {
  description = "Formatted greeting."
  value       = var.language == "de" ? "Hallo, ${var.name}!" : "Hello, ${var.name}!"
}
```

Create `modules/greeting/versions.tf`:

```terraform
terraform {
  required_version = ">= 1.12.0"
}
```

Call the module from the root `main.tf`:

```terraform
module "greeting" {
  source   = "./modules/greeting"
  name     = "Terraform"
  language = "en"
}
```

And expose the output in `outputs.tf`:

```terraform
output "greeting" {
  value = module.greeting.message
}
```

Create `versions.tf`:

```terraform
terraform {
  required_version = "= 1.12.2"
}
```

Run `terraform init` and `terraform apply` to confirm the module works:

```bash
terraform init
terraform apply
```

```text
Outputs:

greeting = "Hello, Terraform!"
```


## Step {{% param sectionnumber %}}.2: Write a test file

`terraform test` (introduced in Terraform 1.6) reads `.tftest.hcl` files and runs the assertions
defined inside. Each test file can contain multiple **`run` blocks**, each of which executes a
plan or apply and then checks **`assert` blocks**.

Create a directory for tests and a first test file:

```bash
mkdir tests
```

Create `tests/greeting.tftest.hcl`:

```terraform
# Test the default English greeting
run "english_greeting" {
  variables {
    name     = "World"
    language = "en"
  }

  module {
    source = "./modules/greeting"
  }

  assert {
    condition     = output.message == "Hello, World!"
    error_message = "Expected English greeting but got: ${output.message}"
  }
}

# Test the German greeting
run "german_greeting" {
  variables {
    name     = "Welt"
    language = "de"
  }

  module {
    source = "./modules/greeting"
  }

  assert {
    condition     = output.message == "Hallo, Welt!"
    error_message = "Expected German greeting but got: ${output.message}"
  }
}
```

Run the tests:

```bash
terraform test
```

```text
tests/greeting.tftest.hcl... in progress
  run "english_greeting"... pass
  run "german_greeting"... pass
tests/greeting.tftest.hcl... tearing down
tests/greeting.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

### Explanation

Each `run` block:

| Property | Description |
| --- | --- |
| `command` | `plan` (default) or `apply` – use `apply` when assert values depend on computed attributes |
| `variables` | Override input variables for this run only |
| `module` | Target a child module directly instead of the root module |
| `assert` | One or more conditions; test fails if any condition is `false` |

By default `terraform test` uses the `plan` command, which is fast and does **not** create real
infrastructure. Use `command = apply` when you need to test computed output values that are only
known after apply.


## Step {{% param sectionnumber %}}.3: Test for validation errors

You can also verify that Terraform correctly rejects invalid input. Add a second test file to cover
the `validation` block in the `language` variable:

Create `tests/validation.tftest.hcl`:

```terraform
run "invalid_language_is_rejected" {
  variables {
    name     = "Test"
    language = "fr"
  }

  module {
    source = "./modules/greeting"
  }

  # We expect this run to fail with a validation error
  expect_failures = [
    var.language,
  ]
}
```

Run the tests again:

```bash
terraform test
```

```text
tests/greeting.tftest.hcl... pass
tests/validation.tftest.hcl... in progress
  run "invalid_language_is_rejected"... pass
tests/validation.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

### Explanation

`expect_failures` accepts a list of resource/variable addresses that are **expected** to produce
a validation error. If the run succeeds (no error), the test itself fails. This pattern lets you
write negative tests that confirm your guards are working correctly.

{{% alert title="Best Practice" color="secondary" %}}
Keep the majority of tests using the default `command = plan` for speed. Add `command = apply`
tests only for critical paths that require real resource attributes, and always clean up with
`terraform destroy` or use short-lived resources to avoid cost accumulation.
{{% /alert %}}
