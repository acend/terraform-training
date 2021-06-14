---
title: "10. Terraform Modules"
weight: 10
sectionnumber: 10
---

You can also build a kind of Terraform libraries, so named "modules". These modules can be reused if they are build well.


## Container Registry

We will create a new folder called `module` and create some base files in there:

main.tf
```bash
```

acr.tf
```bash
```

variables.tf
```bash
```

outputs.tf
```bash
```


## Input/Outputs

The important thing in modules is, you can abstract a lot of things which you normally would have to configure.

The usage of the created module would look like:
```bash
```


## Change our base

Now change our existing acr config to use the module instead of the direct usage.

