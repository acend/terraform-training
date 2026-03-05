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


{{% alert title="Next" color="secondary" %}}
Continue with [Lab 7.2](../2-azure-credentials/) to set up Azure credentials, then wire them
into a Terraform pipeline.
{{% /alert %}}
