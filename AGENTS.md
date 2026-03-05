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
  04/                      # Intermediate (versions, loops, backend state, config files)
  05/                      # Advanced (modules, meta-arguments, various, templates)
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
```

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

- ~~**`for_each` lab**~~ – **DONE**: `content/en/docs/04/3-for-each.md` created; former
  `3-backend-state.md` → `4-backend-state.md`, `4-config-files.md` → `5-config-files.md`.

- ~~**Terraform import**~~ – **DONE**: `content/en/docs/05/5-import.md` created.

- ~~**`moved` block**~~ – **DONE**: `content/en/docs/05/6-moved.md` created.

- ~~**Testing**~~ – **DONE**: `content/en/docs/05/7-testing.md` created.

### Low Priority

- ~~**Typos to fix**~~ – **DONE**: All 6 typos fixed across content files.

- ~~**Setup page**~~ – **DONE**: `mise` and `asdf` alternatives added to setup page.

- ~~**Chapter 1 links**~~ – **DONE**: Updated to `developer.hashicorp.com/terraform` domain.

- **Mermaid diagrams** – The Azure workshop uses Mermaid for solution architecture diagrams.
  Add equivalent architecture diagrams to the AWS and GCP workshops once those chapters are filled.

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
| MD022 | 1 blank line above | Headings need one blank line above them |
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

Always leave one blank line above every heading (`##`, `###`, etc.). The rule is configured with
`lines_above: 1`, so a heading immediately after a paragraph or code block will fail.

---

## Agent Task Examples

When asked to improve or extend this training, typical tasks include:

- **Add a new lab page**: create `content/en/docs/NN/M-topic.md` with correct front matter, preparation
  section, numbered steps, explanations, and code blocks following the patterns above.
- **Update a version number**: find every occurrence across all `.md` and `.tf` snippet files and update
  them consistently. Verify the syntax is still valid for the new version.
- **Fix a typo**: use the list above or search the content directory.
- **Expand the AWS/GCP workshop**: create the missing lab files in `06_aws/` or `06_gcp/` mirroring
  the Azure workshop structure, adapted for the target cloud provider.
- **Add a Terraform feature lab**: insert it into the appropriate chapter (03–05) and adjust the
  `weight` of subsequent pages so they remain in order.
