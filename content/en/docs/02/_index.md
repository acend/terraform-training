---
title: "2. First steps"
weight: 2
sectionnumber: 2
---

In this chapter you will learn the basics of Terraform.

The Terraform configuration is based on files. The filename does not serve special purpose; Terraform internally
merges all files ending with `.tf`.

A typical project structure looks as followed:

* main.tf
* variables.tf
* outputs.tf

In the next lab chapters you will create these files and understand how and when so group the content.


## First Steps

Start your IDE in an empty project directory and launch a UNIX shell.

Make sure you are using the latest version of the Terraform CLI by running:

```bash
tfenv install 1.0.5
tfenv use 1.0.5
terraform version
```
