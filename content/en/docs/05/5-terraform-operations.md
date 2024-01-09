---
title: "5.5. Terraform CLI"
weight: 55
sectionnumber: 5.5
---


There are many more topics regarding Terraform. Here we will a have look over some of them:

* state inspection
* state remove
* import
* debugging
* tflint


## Task {{% param sectionnumber %}}.1: State Inspection

As you have learned, the Terraform state represents the applied objects that have been successfully applied. Here is the example from our first applied config:

```
{
  "version": 4,
  "terraform_version": "1.0.0",
  "serial": 1,
  "lineage": "e16466b0-a1f7-f0d0-ac77-263f52a3a511",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "random_integer",
      "name": "acr",
      "provider": "provider[\"registry.terraform.io/hashicorp/random\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "1073",
            "keepers": null,
            "max": 9999,
            "min": 1000,
            "result": 1073,
            "seed": null
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    }
  ]
}
```

You see a normal JSON file that contains every needed information.

{{% alert title="Warning" color="secondary" %}}
This file should be handled as sensible data, as it can contain passwords as well! Nobody should access it, except Terraform itself!
{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Remove States from file

Now remove the line "result" from this file and apply again, what happened? Terraform won't update the result field again! Because everything is done from his perspective. Try to delete the complete field of the `acr` resource in the file.

If you think that this is tricky, you are right. And that is why you shouldn't try to edit this state file. Instead, use `terraform destroy` or delete the resource file in the folder.


## Task {{% param sectionnumber %}}.3: Import

Sometimes you have already created resources in your environment. By describing them afterward in a Terraform config, Terraform will complain these resources exist already. If you are not able to delete for re-creation you can import it in the actual state file.

For more information check out this HashiCorp Learn example: https://learn.hashicorp.com/tutorials/terraform/state-import?in=terraform/state


## Task {{% param sectionnumber %}}.4: Debugging

{{% alert title="info" color="secondary" %}}
As Terraform is really noisy, you should be able to resolve issues by the error message.
{{% /alert %}}

By setting the system env variable `TF_LOG`, Terraform will provide much more information about what's going on. Log Levels are:

* TRACE, DEBUG, INFO, WARN or ERROR

```bash
export TF_LOG="DEBUG"
```


## Task {{% param sectionnumber %}}.5: Linting

The use of linting your Terraform config is always a good thing. You can define rules for naming conventions and force people to write readable code.

One example is `tflint` (https://github.com/terraform-linters/tflint). It has a small binary that can be included everywhere and executes fast. Here an output of our simple example from above by running `tflint .`:

```
2 issue(s) found:

Warning: terraform "required_version" attribute is required (terraform_required_version)

  on  line 0:
   (source code not available)

Reference: https://github.com/terraform-linters/tflint/blob/v0.29.0/docs/rules/terraform_required_version.md

Warning: Missing version constraint for provider "random" in "required_providers" (terraform_required_providers)

  on main.tf line 1:
   1: resource "random_integer" "acr" {

Reference: https://github.com/terraform-linters/tflint/blob/v0.29.0/docs/rules/terraform_required_providers.md
```

You see 2 warnings:

* terraform_required_version is missing
* terraform_required_providers is missing

This is because of the default recommendation to declare and versionize everything correctly. Make the linter happy!
