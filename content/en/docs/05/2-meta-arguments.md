---
title: "5.2. Meta-Arguments"
weight: 52
sectionnumber: 5.2
---


## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/advanced/meta_arguments
cd $LAB_ROOT/advanced/meta_arguments
```

Optional: Create empty files:

```bash
touch main.tf
```


## Step {{% param sectionnumber %}}.1: Missing dependency

Sometimes Terraform can not imply the dependency between resources explicitly. For such cases, a dependency
is added to one or multiple resources or data sources. Consider the following snippets.

Create a new file named `main.tf` and add the following content:

```terraform
resource "local_file" "foobar_txt" {
  content  = "4thelulz"
  filename = "foobar.txt"
}

data "local_file" "reference" {
  filename = "foobar.txt"
}
```

Now run:

```bash
terraform init
terraform apply
```

This will print the following error:

```text
╷
│ Error: open foobar.txt: no such file or directory
│
│   with data.local_file.reference,
│   on main.tf line 5, in data "local_file" "foobar_txt":
│    5: data "local_file" "reference" {
│
╵
```


### Explanation

The data source `local_file.reference` is refreshed at the execution of `terraform apply`. However at this stage,
the file does not exist yet and Terraform fails.


## Step {{% param sectionnumber %}}.2: Explicit dependency

Change the resource `local_file.reference` as followed:

{{< highlight terraform "hl_lines=4" >}}
data "local_file" "reference" {
  filename = "foobar.txt"

  depends_on = [local_file.foobar_txt]
}
{{< / highlight >}}

Now run:

```bash
terraform init
terraform apply
```

Terraform will skip trying to refresh (access) `local_file.reference` because of the explicit
dependency on the resource `local_file.foobar_txt` which does not yet exist.


## Step {{% param sectionnumber %}}.3: Ignoring external changes

We set the file content to be `4thelulz`. Now lets change it and run apply again:

```bash
echo 4real > foobar.txt
terraform apply
```

Terraform will restore the file `foobar.txt` to the configuration defined in the code. All good!

But sometimes we don't want that behaviour - we want to ignore the content.  
Luckily Terraform offers another meta-argument for this purpose.

Change the `data` `local_file.foobar_txt` as followed:

```terraform
resource "local_file" "foobar_txt" {
  content  = "4thelulz"
  filename = "foobar.txt"

  lifecycle {
    ignore_changes = [content]
  }
}
```

{{% alert title="Note" color="primary" %}}
The `content` has changed!
{{% /alert %}}

Now run:

```bash
terraform apply
```

And Terraform will happily ignore the `content = "4thelulz"`.


### Explanation

This is particularly useful in cloud engineering to set initial values for tags or secrets and expect an external
system or user to override or extend the value.
