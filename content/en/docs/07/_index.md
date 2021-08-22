---
title: "7. Condtionals"
weight: 7
sectionnumber: 7
---

Sometimes you need more than on resource of a specific type. Here are some examples how to archive this function.



## Task {{% param sectionnumber %}}.1: Multiple resources

By adding the identifier `count` to any resource you will get back a tuple with all the results:

```bash
resource "random_integer" "acr" {
  count = 4
  min = 1000
  max = 9999
}

output "random_result_all" {
    description = "example output"
    value       = random_integer.acr
}

output "random_result_one" {
    description = "example output"
    value       = random_integer.acr[0].result
}
```

This example has not a big usage at all, but imagine you'll have to give one permission to a list of users. With count it would look like:

```
variable "user_groups" {
  type        = list(string)
  description = "user groups for permissions"
  default     = ['user1', 'user2', 'user3']
}

resource "azurerm_role_assignment" "read_permission" {
  count                = lenght(var.user_groups)
  scope                = example.id
  role_definition_name = "Read Permission"
  principal_id         = var.user_groups[count.index]]
}
```


## Task {{% param sectionnumber %}}.2: Optional resources

It is a bit tricky to create those type of function. Therefore we can use the `count` operator as well to enable or disable resources based on a variable (feature token):

```bash
variable "random_enabled" {
  type        = bool
  description = "enable random number"
  default     = true
}

locals {
    random_enabled = var.random_enabled == true ? 1 : 0
}

resource "random_integer" "acr" {
  count = local.random_enabled
  min   = 1000
  max   = 9999
}
```

Other resources could react on this to create, or not, resources based on this information.


## Task {{% param sectionnumber %}}.3: Loops

There are "real" loops as well. But there are only working with `sets` or `maps` as their content is unique. Here just an example how to create a list of users:

```
variable "user_names" {
  description = "IAM usernames"
  type        = set(string)
  default     = ["user1", "user2", "user3"]
}

resource "azuread_user" "users" {
  for_each            = var.user_names
  user_principal_name = "${each.value}@examle.onmicrosoft.com"
  display_name        = each.value
  password            = random_password.example.result
}
```

