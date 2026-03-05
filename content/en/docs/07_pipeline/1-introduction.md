---
title: "7.1. Introduction to GitLab CI/CD"
weight: 71
sectionnumber: 7.1
---


## Building Blocks of a GitLab Pipeline

Before writing any Terraform CI/CD configuration, let's understand the key concepts.

A GitLab pipeline is defined in a file called `.gitlab-ci.yml` at the root of your repository.

| Concept | Description |
| --- | --- |
| **Pipeline** | The top-level process triggered by a git push or manually |
| **Stage** | A named phase (`build`, `test`, `deploy`). Stages run sequentially |
| **Job** | A unit of work inside a stage. Jobs in the same stage run in parallel |
| **Runner** | An agent (VM or container) that executes job scripts |
| **Variable** | A key/value pair, either defined in `.gitlab-ci.yml` or in GitLab project settings |


## Preparation

Create a new GitLab project and clone it:

```bash
mkdir -p $LAB_ROOT/pipeline
cd $LAB_ROOT/pipeline
git init
git remote add origin <your-gitlab-repo-url>
```


## Step {{% param sectionnumber %}}.1: Your first pipeline – Hello World

Create a file named `.gitlab-ci.yml` at the root of your repository:

```yaml
---
stages:
  - greet

hello:
  stage: greet
  script:
    - echo "Hello, World!"
    - echo "Running on runner: $CI_RUNNER_DESCRIPTION"
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "Commit: $CI_COMMIT_SHORT_SHA"
```

Commit and push:

```bash
git add .gitlab-ci.yml
git commit -m "ci: hello world pipeline"
git push
```

Navigate to **CI/CD → Pipelines** in your project. You should see a green pipeline with one job.

### Explanation

GitLab automatically picks up `.gitlab-ci.yml` from the repository root on every push.
Each job runs inside a fresh container (using the shared runner's default image). Built-in
variables like `$CI_COMMIT_BRANCH` and `$CI_RUNNER_DESCRIPTION` are injected automatically —
no configuration needed.


## Step {{% param sectionnumber %}}.2: Write a basic Terraform pipeline

{{% alert title="Prerequisites" color="secondary" %}}
The following steps require Azure credentials stored as GitLab CI/CD variables.
Complete [Lab 7.2](../2-azure-credentials/) before continuing.
{{% /alert %}}

Copy your existing Azure Terraform code into the pipeline repository:

```bash
cp -r $LAB_ROOT/azure/. $LAB_ROOT/pipeline/
```

Create (or replace) `.gitlab-ci.yml` at the root of your repository:

```yaml
---
image: hashicorp/terraform:1.12.2

stages:
  - validate
  - plan

variables:
  TF_VAR_FILE: "config/dev.tfvars"
  TF_BACKEND_CONFIG: "config/dev_backend.tfvars"
  TF_PLUGIN_CACHE_DIR: "/cache/plugin-cache"
  TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE: "1"

before_script:
  - mkdir -p $TF_PLUGIN_CACHE_DIR
  - terraform init -backend-config=$TF_BACKEND_CONFIG

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -var-file=$TF_VAR_FILE -out=tfplan
  artifacts:
    paths:
      - tfplan
    expire_in: 1 day
```

Push to GitLab and watch the pipeline run:

```bash
git add .gitlab-ci.yml
git commit -m "ci: add terraform validate and plan pipeline"
git push
```

Navigate to **CI/CD → Pipelines** in your GitLab project to see the result.


### Explanation

The `image:` key sets the Docker image used for all jobs. Using the official HashiCorp image pins
the Terraform version to match `versions.tf`.

The `before_script:` block runs before every job script, making `terraform init` a single
place to maintain.

Saving the plan as an **artifact** lets the apply job (added next) use the exact same plan that
was reviewed—preventing drift between plan and apply.


## Step {{% param sectionnumber %}}.3: Add a manual apply job

Extend `.gitlab-ci.yml` by appending the following:

```yaml
apply:
  stage: apply
  script:
    - terraform apply -auto-approve tfplan
  dependencies:
    - plan
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
  environment:
    name: production
```

Also extend the `stages:` list:

```yaml
stages:
  - validate
  - plan
  - apply
```

Push the change, open a merge request, and observe that the `apply` job appears but requires a
manual click to execute.

### Explanation

`rules: when: manual` means the job is created but waits for a human to click the play button.
Restricting it to the `main` branch ensures feature branches only run validate and plan—apply
only happens after a merge.

The `dependencies:` key tells GitLab to download the `tfplan` artifact from the `plan` job so
the apply step uses the reviewed plan exactly.

{{% alert title="Note" color="secondary" %}}
For production workflows, also add a `terraform show -json tfplan | jq` step to make the planned
changes visible directly in the merge request pipeline output before someone clicks apply.
{{% /alert %}}
