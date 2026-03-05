---
title: "7.2. Azure Credentials for CI/CD"
weight: 72
sectionnumber: 7.2
---

Terraform needs an Azure **service principal** to authenticate from a pipeline runner — a
non-interactive identity with scoped permissions. In this lab you create the service principal
with the Azure CLI and store the resulting credentials as masked GitLab CI/CD variables.


## Preparation

Make sure you are logged in to the Azure CLI and have the correct subscription selected:

```bash
az login
az account show
```

If you need to switch subscription:

```bash
az account set --subscription "<your-subscription-id>"
```


## Step {{% param sectionnumber %}}.1: Create a service principal

Create a service principal scoped to your subscription with the **Contributor** role:

```bash
az ad sp create-for-rbac \
  --name "sp-gitlab-pipeline-<your-username>" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id>
```

The command returns JSON — keep this output, you will need the values in the next step:

```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "sp-gitlab-pipeline-<your-username>",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

You also need your subscription ID:

```bash
az account show --query id -o tsv
```

### Explanation

`create-for-rbac` creates an Azure Active Directory application and a service principal in one
step, then assigns the specified RBAC role. The `Contributor` role allows creating and managing
all resource types but not assigning roles — a safe default for Terraform pipelines. For
production workloads, scope the principal to a specific resource group instead of the whole
subscription.


## Step {{% param sectionnumber %}}.2: Store credentials as GitLab CI/CD variables

In your GitLab project navigate to **Settings → CI/CD → Variables** and add the following
four variables. Use the values from the JSON output above.

| Variable | JSON field | Masked | Protected |
| --- | --- | --- | --- |
| `ARM_CLIENT_ID` | `appId` | yes | yes |
| `ARM_CLIENT_SECRET` | `password` | yes | yes |
| `ARM_SUBSCRIPTION_ID` | output of `az account show` | yes | yes |
| `ARM_TENANT_ID` | `tenant` | yes | yes |

For each variable:

1. Click **Add variable**
2. Set the **Key** and **Value**
3. Enable **Mask variable** — this redacts the value in all job logs
4. Enable **Protect variable** — this restricts the variable to protected branches and tags only
5. Click **Add variable**

{{% alert title="Important" color="secondary" %}}
Never commit credentials to your repository. The masked variable approach ensures secrets are
injected at runtime and never visible in source code or plain-text logs.
{{% /alert %}}


## Step {{% param sectionnumber %}}.3: Verify the credentials

To quickly verify the service principal works before running a full pipeline, you can test it
locally:

```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenant>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"

az login --service-principal \
  --username $ARM_CLIENT_ID \
  --password $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

az account show
```

If the login succeeds and `az account show` returns your subscription, the credentials are valid
and Terraform will be able to authenticate using the same environment variables from the pipeline.

```bash
# Clean up the local test session
az logout
```

You are now ready to wire these credentials into a Terraform pipeline.


## Step {{% param sectionnumber %}}.4: Write a basic Terraform pipeline

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
was reviewed — preventing drift between plan and apply.


## Step {{% param sectionnumber %}}.5: Add a manual apply job

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
Restricting it to the `main` branch ensures feature branches only run validate and plan — apply
only happens after a merge.

The `dependencies:` key tells GitLab to download the `tfplan` artifact from the `plan` job so
the apply step uses the reviewed plan exactly.

{{% alert title="Note" color="secondary" %}}
For production workflows, also add a `terraform show -json tfplan | jq` step to make the planned
changes visible directly in the merge request pipeline output before someone clicks apply.
{{% /alert %}}
