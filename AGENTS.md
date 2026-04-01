# Terraform Training – Agent Instructions

This file provides context and guidelines for AI agents contributing to the **acend Terraform Training** content.
The training is a Hugo-based static site using the [Docsy theme](https://www.docsy.dev/) and targets customers
learning infrastructure-as-code with Terraform.

---

## Project Structure

```
content/en/docs/           # Main lab content (one folder per chapter)
  01/                      # Introduction
  02/                      # First Steps
  03/                      # Basics (resources, variables, outputs, data sources, types)
  04/                      # Intermediate (versions, count/loops, for_each, backend state, config files)
  05/                      # Advanced (modules, meta-arguments, various, templates, import, moved, testing)
  06_azure/                # Azure Workshop (primary cloud)
  06_aws/                  # AWS Workshop (stub – needs content)
  06_gcp/                  # GCP Workshop (stub – needs content)
  07_pipeline/             # Terraform with Pipeline (GitLab CI/CD)
  08/                      # Challenges (ch. 8)
  09/                      # Cleanup (ch. 9)
content/en/setup/          # Pre-lab setup instructions
config/_default/           # Default Hugo config (Azure-flavored)
config/aws/                # AWS environment override
config/gcp/                # GCP environment override
extract-terraform.sh       # Script to extract Terraform/YAML from chapters 6–8
extracted-terraform/       # (gitignored) output of extract-terraform.sh
  06_azure/                #   per-lab extracted blocks (one folder per lab page)
  06_azure_combined/       #   merged runnable project for chapters 6.1–6.6
  07_pipeline/             #   per-lab extracted blocks
  08/                      #   per-lab extracted blocks
```

---

## Slide Deck Reference

The canonical training presentation is `slides/Terraform on Azure Basics.odp` (101 slides, last updated
Feb 2026). When authoring or reviewing lab content, use the slide deck as the source of truth for learning
goals, exercise titles, and conceptual explanations.

### Slide-to-chapter mapping

| Slides | Topic | Lab chapter |
| --- | --- | --- |
| 5–12 | Public Cloud Engineering | ch. 1 & 2 (intro / first steps) |
| 13–24 | Terraform Introduction | ch. 1 & 2 (intro / first steps) |
| 26–33 | Terraform Basics | ch. 03 |
| 34–41 | Terraform Intermediate | ch. 04 |
| 42–48 | Terraform Advanced | ch. 05 |
| 49–52 | Container Basics | **slides only – no lab chapter** |
| 53–67 | Kubernetes Basics | **slides only – no lab chapter** |
| 68–81 | Azure Workshop | ch. 06\_azure |
| 82–93 | GitLab CI/CD | ch. 07\_pipeline |
| 94–100 | Best Practices | **slides only – no lab chapter** |

### Slides vs. repo deviations

* **ch. 04 – `for_each` lab**: Slides bundle `for_each` as a bullet under Exercise #2 ("count / loops").
  The repo adds a dedicated lab `04/3-for-each.md`; as a result `backend-state` and `config-files` shift
  by one (now labs 4 and 5).
* **ch. 05 – extra labs**: Slides cover 4 Advanced exercises (modules, meta-arguments, various, templates).
  The repo adds three more labs (`5-import.md`, `6-moved.md`, `7-testing.md`) that go beyond the slides.
* **lab 6.5 – MySQL vs MariaDB**: Slide 80 titles the exercise "MariaDB"; the lab (`5-mysql.md`) uses
  `azurerm_mysql_flexible_server` (Azure Database for MySQL Flexible Server). The slides contain a stale
  reference and should be updated to say "MySQL".
* **lab 6.7 – Container Instances**: `06_azure/7-container-instances.md` is a bonus standalone exercise
  added to the repo; it is not covered in the slide deck.

---

## Content Authoring Conventions

### Front Matter

Every lab page must include the following YAML front matter:

```yaml
---
title: "N.M. Title"
weight: NM           # e.g. 31 for section 3.1
sectionnumber: N.M   # e.g. 3.1
---
```

Cloud-specific pages also require:

```yaml
onlyWhen: azure   # or: aws | gcp
```

### Naming Conventions

- Chapter index files: `N/_index.md`
- Lab files: `N/M-short-name.md` (e.g. `03/1-resources.md`)
- Weight for chapter index = chapter number (e.g. `weight: 3`)
- Weight for sub-pages = chapter × 10 + sub-page index (e.g. `weight: 31`)

### Step Structure

Labs follow a consistent structure:

````markdown
## Preparation

Create a new directory for this exercise:

```bash
mkdir -p $LAB_ROOT/<path>
cd $LAB_ROOT/<path>
```

## Step N.M.1: Title

...instructions...

### Explanation

...why this matters...

## Step N.M.2: Next Step
````

### Hugo Shortcodes

Use the following shortcodes where appropriate:

| Shortcode | Purpose |
| --- | --- |
| `{{% alert title="..." color="secondary" %}}...{{% /alert %}}` | Important notices / warnings |
| `{{% details title="Hints" %}}...{{% /details %}}` | Collapsible hint/solution blocks |
| `{{% param sectionnumber %}}` | Inject the current section number |

### Code Blocks

- Terraform code: ` ```terraform `
- Shell commands: ` ```bash `
- Expected output: ` ```text `
- Mermaid diagrams: ` ```mermaid ` (supported via `[params.mermaid] enable = true` in config)

### Placeholder Conventions

Lab content uses the following standard placeholders that students replace with their own values:

| Placeholder | Meaning |
| --- | --- |
| `YOUR_USERNAME` | Student's assigned workshop username (lowercase, alphanumeric only) |
| `YOUR_ACCOUNT` | Azure storage account name (from `echo $ACCOUNT` in lab 6.2) |
| `<your-subscription-id>` | Azure subscription ID |
| `<your-gitlab-repo-url>` | Student's GitLab repository URL |
| `<your-username>` | Same as `YOUR_USERNAME` but in angle-bracket style |
| `<your-tag>` | Student's GitLab runner tag |

Use these exact placeholders when authoring new content to stay consistent.

### Terraform Code Quality

All Terraform snippets in the training must follow these standards:

- Use `required_version` and `required_providers` with pinned versions in every `versions.tf` example
- Prefer `for_each` over `count` for resource sets (except when demonstrating conditionals)
- Always include `description` on `variable` blocks
- Sensitive outputs must set `sensitive = true`
- Follow HashiCorp naming conventions: `snake_case` for resource names and variable names

---

## Cloud Environments

The config key `enabledModule` controls which sections are rendered:

| Environment | `enabledModule` | Active Workshop |
| --- | --- | --- |
| default | `base azure` | Azure (ch. 06_azure) |
| aws | `base aws` | AWS (ch. 06_aws) |
| gcp | `base gcp` | GCP (ch. 06_gcp) |

Pages using `onlyWhen: azure` (or `aws`/`gcp`) are only rendered in the matching environment.

---

## Azure Workshop – Provider & File Dependencies

The Azure workshop (ch. 6) builds up a project incrementally. Each lab adds providers and
modifies files from earlier labs. This map is essential when merging labs into a combined
folder or understanding cross-references.

| Chapter | New providers added | Files created | Files modified from earlier labs |
| --- | --- | --- | --- |
| 6.1 | `azurerm`, `random`, `azuread` | `main.tf`, `variables.tf`, `versions.tf`, `config/dev.tfvars`, `network.tf`, `aks.tf`, `analytics_workspace.tf`, `iam.tf`, `acr.tf` | — |
| 6.2 | — | `config/dev_backend.tfvars` | `main.tf` (add `backend "azurerm"`) |
| 6.3 | `kubernetes`, `helm` | `nginx_ingress.tf`, `dns.tf` | `main.tf` (add kubernetes + helm providers), `aks.tf` (add public IP + role assignment) |
| 6.4 | — | `cert_manager.tf`, `helm/cert_manager_issuer/` | — |
| 6.5 | — | `mysql.tf`, `outputs.tf` | `aks.tf` (add egress IP + `load_balancer_profile`) |
| 6.6 | — | `tests/workload.yaml` | — (uses `kubectl` only) |
| 6.7 | — | separate folder: `main.tf`, `variables.tf`, `aci.tf` | — (standalone exercise; bonus, not in slide deck) |

---

## Known Gaps & Improvement Areas

### High Priority

- **AWS Workshop** (`content/en/docs/06_aws/`) – The chapter index exists but no lab pages have been created.
  Implement labs equivalent to the Azure workshop:
  1. Provider setup + first resource (e.g. `aws_s3_bucket` or `aws_vpc`)
  2. Remote state with S3 backend
  3. EKS cluster provisioning
  4. DNS / Load balancer
  5. RDS database
  6. Demo application deployment

- **GCP Workshop** (`content/en/docs/06_gcp/`) – Same situation as AWS; the index is a stub.
  Suggested labs:
  1. Provider setup + project configuration
  2. Remote state with GCS backend
  3. GKE cluster provisioning
  4. Cloud DNS / Load balancer
  5. Cloud SQL
  6. Demo application deployment

### Medium Priority

- **Version currency** – The pinned provider versions in `04/1-versions.md` and all Azure workshop examples
  are likely outdated. Update to current stable releases:
  - `hashicorp/random`, `hashicorp/local`
  - `hashicorp/azurerm`
  - `hashicorp/kubernetes`, `hashicorp/helm`
  - AKS Kubernetes version, cert-manager Helm chart version

- **Slides say "MariaDB" for lab 6.5** – Slide 80 titles exercise 5 as "MariaDB" but the lab uses
  `azurerm_mysql_flexible_server` (MySQL Flexible Server). Update the slide deck to say "MySQL Flexible
  Server" to match the lab content and the current Azure provider resource.

- ~~**`for_each` lab**~~ – **DONE**: `content/en/docs/04/3-for-each.md` created; former
  `3-backend-state.md` → `4-backend-state.md`, `4-config-files.md` → `5-config-files.md`.

- ~~**Terraform import**~~ – **DONE**: `content/en/docs/05/5-import.md` created.

- ~~**`moved` block**~~ – **DONE**: `content/en/docs/05/6-moved.md` created.

- ~~**Testing**~~ – **DONE**: `content/en/docs/05/7-testing.md` created.

### Low Priority

- ~~**Kaniko image-build lab**~~ – **DONE**: `content/en/docs/07_pipeline/4-build-docker-image.md`
  created (lab 7.4). Former `4-linting.md` → `5-linting.md` (weight 75, sectionnumber 7.5).
  Lab 7.4 extends Terraform from 7.3 to grant the service principal `AcrPush` on the ACR from
  Ch. 6, creates the `Dockerfile`, stores the registry server as a CI variable, and wires up a
  Kaniko `build-image` CI job. Lab 7.5 (linting) removes the manual docker-build steps and
  references the image built in 7.4.

- ~~**Typos to fix**~~ – **DONE**: All 6 typos fixed across content files.

- ~~**Setup page**~~ – **DONE**: `mise` and `asdf` alternatives added to setup page.

- ~~**Chapter 1 links**~~ – **DONE**: Updated to `developer.hashicorp.com/terraform` domain.

- **Mermaid diagrams** – The Azure workshop uses Mermaid for solution architecture diagrams.
  Add equivalent architecture diagrams to the AWS and GCP workshops once those chapters are filled.

- **Slides-only theory sections** – Container Basics (slides 49–52), Kubernetes Basics (slides 53–67),
  and Best Practices (slides 94–100) are covered in the slide deck but have no corresponding lab chapter.
  Consider adding a brief reference page or pointers in the adjacent lab chapters if students need
  anchors to the slide content.

- **Lab 6.7 not in slide deck** – `06_azure/7-container-instances.md` is a bonus exercise added to
  the repo. If it becomes a regular part of the training, add a matching slide to the presentation.

---

## Terraform Code Extraction

The script `extract-terraform.sh` parses markdown files from chapters 6–8 and writes all
` ```terraform ` code blocks into standalone `.tf` files, organized by chapter and lab page.
It also detects target filenames from surrounding context (e.g. "Create a file named `main.tf`")
and appends multiple blocks that target the same file with separator comments.

```bash
./extract-terraform.sh              # output to ./extracted-terraform/
./extract-terraform.sh /tmp/tf      # custom output directory
```

The output directory is listed in `.gitignore`.

### Combined folder: `06_azure_combined/`

A hand-curated merge of chapters 6.1–6.6 into a single runnable Terraform project with the
Azure remote backend configured from the start. It includes:

* All `.tf` files (main, variables, versions, aks, network, acr, iam, dns, nginx\_ingress,
  cert\_manager, mysql, outputs, analytics\_workspace)
* `config/dev.tfvars` and `config/dev_backend.tfvars`
* `helm/cert_manager_issuer/` chart (Chart.yaml + ClusterIssuer template)
* `tests/` directory with Kubernetes YAML manifests (http.yaml, https.yaml, workload.yaml)

To run:

```bash
cd extracted-terraform/06_azure_combined
# Edit config/dev.tfvars and config/dev_backend.tfvars with your values
terraform init -backend-config=config/dev_backend.tfvars
terraform apply -var-file=config/dev.tfvars
```

---

## How to Preview Changes Locally

```bash
export HUGO_VERSION=$(grep "FROM docker.io/floryn90/hugo" Dockerfile | sed 's/FROM docker.io\/floryn90\/hugo://g' | sed 's/ AS builder//g')
docker run --rm -it --publish 8080:8080 -v $(pwd):/src floryn90/hugo:${HUGO_VERSION} server -p 8080 --bind 0.0.0.0
```

Open http://localhost:8080 in your browser.

To preview a specific cloud environment (e.g. AWS):

```bash
docker run --rm -it --publish 8080:8080 -v $(pwd):/src floryn90/hugo:${HUGO_VERSION} server --environment=aws -p 8080 --bind 0.0.0.0
```

## Linting

All markdown files are linted with [markdownlint](https://github.com/DavidAnson/markdownlint).
Run before committing:

```bash
npm install
npm run mdlint
```

Or with Docker (no local Node.js needed):

```bash
docker run --rm -it -v $(pwd):/src floryn90/hugo:${HUGO_VERSION}-ci /bin/bash -c "set -euo pipefail; npm install; npm run mdlint;"
```

### Active markdownlint rules (`.markdownlint.json`)

The project enables all default rules with the following overrides:

| Rule | Setting | Effect |
| --- | --- | --- |
| MD003 | `atx` | Headings must use `#` style |
| MD004 | `asterisk` | Unordered lists must use `*` |
| MD012 | max 2 | At most two consecutive blank lines |
| MD013 | disabled | No line-length limit |
| MD022 | 2 blank lines above | Headings need two blank lines above them |
| MD024 | disabled | Duplicate heading text is allowed |
| MD031 | disabled | Fenced code blocks inside lists allowed |
| MD034 | disabled | Bare URLs are allowed |
| MD035 | `---` | Horizontal rules must use `---` |
| MD040 | disabled | Fenced code blocks without language tag allowed |
| MD048 | `backtick` | Fenced code blocks must use backticks |

### Common pitfalls to avoid

#### MD060 – Table column style

Use **compact-style** separators (`| --- | --- |`) for all tables. Fixed-width separators that
match the header width (e.g. `|--------|-------------|`) trigger "aligned" style detection; if any
data row is then wider than the header, markdownlint raises MD060 errors across every pipe in the
table.

```markdown
<!-- correct – compact style -->
| Symbol | Description |
| --- | --- |
| `each.key` | The current map key |

<!-- wrong – aligned style -->
| Symbol | Description |
|--------|-------------|
| `each.key` | The current map key |
```

#### Hugo shortcodes inside fenced blocks

Do not place Hugo shortcodes (e.g. `{{% param sectionnumber %}}`) inside fenced code blocks;
Hugo will try to render them even inside backtick fences when `unsafe` rendering is enabled.

#### Blank lines around headings (MD022)

Always leave two blank lines above every heading (`##`, `###`, etc.). The rule is configured with
`lines_above: 2`, so a heading immediately after a paragraph or code block will fail.

---

## Agent Task Examples

When asked to improve or extend this training, typical tasks include:

- **Add a new lab page**: create `content/en/docs/NN/M-topic.md` with correct front matter, preparation
  section, numbered steps, explanations, and code blocks following the patterns above.
- **Update a version number**: find every occurrence across all `.md` and `.tf` snippet files and update
  them consistently. Also update `extracted-terraform/06_azure_combined/` if it exists. Verify the
  syntax is still valid for the new version.
- **Fix a typo**: search the content directory for the term.
- **Expand the AWS/GCP workshop**: create the missing lab files in `06_aws/` or `06_gcp/` mirroring
  the Azure workshop structure, adapted for the target cloud provider.
- **Add a Terraform feature lab**: insert it into the appropriate chapter (03–05) and adjust the
  `weight` of subsequent pages so they remain in order.
- **Merge labs into a combined folder**: use the Provider & File Dependencies table above to
  understand which files are created vs. modified, then produce a single coherent project.
  Always include the `backend "azurerm"` block from the start when merging chapter 6.
