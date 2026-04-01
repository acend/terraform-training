#!/usr/bin/env bash
#
# Extract Terraform code blocks from training markdown files (chapters 6–8)
# and write them into chapter-organized directories.
#
# When a lab incrementally builds a file (e.g. multiple blocks target aks.tf),
# all blocks are appended with a separator comment so you can see the full
# picture for each file.
#
# Usage:
#   ./extract-terraform.sh [output_dir]
#
# Default output directory: ./extracted-terraform
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="${SCRIPT_DIR}/content/en/docs"
OUTPUT_DIR="${1:-${SCRIPT_DIR}/extracted-terraform}"

# Chapters to process
CHAPTERS=(06_azure 07_pipeline 08)

extract_blocks() {
  local md_file="$1"
  local out_dir="$2"
  local lab_name
  lab_name="$(basename "${md_file}" .md)"

  # Skip index files – they have no code
  [[ "$lab_name" == "_index" ]] && return

  local lab_dir="${out_dir}/${lab_name}"
  mkdir -p "${lab_dir}"

  local in_block=false
  local block=""
  local filename=""
  local context_buf=""      # rolling 3-line context buffer
  local block_count=0
  local block_lang=""
  local is_solution=false   # track if we're inside a details/hints block
  local heading_file=""     # filename from most recent ## heading

  while IFS= read -r line; do
    # Track solution/hint blocks to label them
    if [[ "$line" =~ \{%\ details ]]; then
      is_solution=true
    fi
    if [[ "$line" =~ \{%\ /details ]]; then
      is_solution=false
    fi

    # Track filenames mentioned in headings (e.g. "## Step 7.3.1: versions.tf")
    if [[ "$line" =~ ^##[[:space:]] ]] && [[ "$line" =~ ([a-zA-Z0-9_/.-]+\.(tf|tfvars))[[:space:]]*$ ]]; then
      heading_file="${BASH_REMATCH[1]}"
    fi

    if $in_block; then
      if [[ "$line" =~ ^\`\`\`[[:space:]]*$ ]]; then
        # End of fenced block
        in_block=false

        # Only save terraform blocks
        if [[ "$block_lang" == "terraform" ]]; then
          block_count=$((block_count + 1))

          # Fallback to heading-derived filename if no inline match
          if [[ -z "$filename" && -n "$heading_file" ]]; then
            filename="$heading_file"
          fi

          if [[ -z "$filename" ]]; then
            filename="block_$(printf '%02d' ${block_count}).tf"
          fi

          # Handle subdirectories (e.g. config/)
          if [[ "$filename" == */* ]]; then
            mkdir -p "${lab_dir}/$(dirname "${filename}")"
          fi

          local target="${lab_dir}/${filename}"
          local label=""
          $is_solution && label=" (from solution/hints)"

          if [[ -f "$target" ]]; then
            # Append with separator
            printf '\n# --- appended block%s ---\n\n' "$label" >> "$target"
            printf '%s' "$block" >> "$target"
            echo "  +> ${target}  (appended${label})"
          else
            if $is_solution; then
              printf '# NOTE: this block is from a solution/hints section\n\n' > "$target"
            fi
            printf '%s' "$block" >> "$target"
            echo "  -> ${target}${label}"
          fi
        fi

        block=""
        filename=""
        block_lang=""
      else
        block+="${line}"$'\n'
      fi
    else
      # Detect start of a fenced code block
      if [[ "$line" =~ ^\`\`\`terraform[[:space:]]*$ ]]; then
        in_block=true
        block_lang="terraform"
        block=""

        # Try to find a filename from the rolling context
        filename="$(detect_filename "$context_buf")"
      elif [[ "$line" =~ ^\`\`\`[[:space:]]*$ ]] || [[ "$line" =~ ^\`\`\`[a-z] ]]; then
        # Non-terraform fenced block — skip it
        if [[ "$line" =~ ^\`\`\`(bash|yaml|dockerfile|json|text|hcl) ]]; then
          in_block=true
          block_lang="${BASH_REMATCH[1]}"
          block=""
          filename=""
        fi
      fi

      # Keep last 3 lines as context for filename detection
      context_buf="$(printf '%s\n%s' "$context_buf" "$line" | tail -3)"
    fi
  done < "$md_file"
}

detect_filename() {
  local context="$1"

  # Patterns commonly used in the training:
  #   "Create a new file named `main.tf`"
  #   "named `variables.tf` and add"
  #   "file named `config/dev.tfvars`"
  #   "the ACI file named `aci.tf`"
  #   "Create a new file named `outputs.tf`"
  #   "Add the following content to ... `variables.tf`:"
  #   "Add ... to `aks.tf`:"
  #   "Add ... in `main.tf`:"
  #   "Append ... to ... `variables.tf`:"
  #   "modify ... `aks.tf`"
  #   "Add the following resources to `access.tf`:"
  #   "Add the following variables to `variables.tf`:"
  #   "Create a new file named `registry.tf`:"
  #   "replace the `network_profile` block"  (no filename → empty)

  local name=""

  # Check each line of context (most recent line gets priority)
  while IFS= read -r ctx_line; do
    local candidate=""

    # Match: file named `filename`
    if [[ "$ctx_line" =~ [Ff]ile[[:space:]]+named[[:space:]]+\`([^\`]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[1]}"
    # Match: "Add ... to `filename`:" / "to the end of `filename`:"
    elif [[ "$ctx_line" =~ (to|of|in)[[:space:]]+(the\ )?(end\ of\ |start\ of\ )?\`([a-zA-Z0-9_/.-]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[4]}"
    # Match: "Append ... to ... `filename`:"
    elif [[ "$ctx_line" =~ [Aa]ppend.*\`([a-zA-Z0-9_/.-]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[1]}"
    # Match: "Add ... resources to `access.tf`:" and similar
    elif [[ "$ctx_line" =~ [Aa]dd.*\`([a-zA-Z0-9_/.-]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[1]}"
    # Match: "modify ... `aks.tf`" / "replace ... in `aks.tf`"
    elif [[ "$ctx_line" =~ (modify|replace|update).*\`([a-zA-Z0-9_/.-]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[2]}"
    # Generic: any backticked .tf/.tfvars filename
    elif [[ "$ctx_line" =~ \`([a-zA-Z0-9_/.-]+\.(tf|tfvars))\` ]]; then
      candidate="${BASH_REMATCH[1]}"
    fi

    [[ -n "$candidate" ]] && name="$candidate"
  done <<< "$context"

  echo "$name"
}

# --- Main ---
echo "================================================================="
echo "Terraform Code Extractor – Chapters 6–8"
echo "================================================================="
echo ""
echo "Source:  ${CONTENT_DIR}"
echo "Output:  ${OUTPUT_DIR}"
echo ""

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

for chapter in "${CHAPTERS[@]}"; do
  chapter_dir="${CONTENT_DIR}/${chapter}"
  if [[ ! -d "$chapter_dir" ]]; then
    echo "SKIP: ${chapter_dir} (not found)"
    continue
  fi

  echo "-----------------------------------------------------------------"
  echo "Chapter: ${chapter}"
  echo "-----------------------------------------------------------------"

  out_chapter="${OUTPUT_DIR}/${chapter}"
  mkdir -p "${out_chapter}"

  # Process markdown files in order
  for md_file in "${chapter_dir}"/*.md; do
    [[ -f "$md_file" ]] || continue
    echo ""
    echo "Processing: $(basename "$md_file")"
    extract_blocks "$md_file" "$out_chapter"
  done
  echo ""
done

echo ""
echo "================================================================="
echo "Done! Extracted Terraform files are in: ${OUTPUT_DIR}"
echo ""
echo "Directory structure:"
find "${OUTPUT_DIR}" -type f | sort | sed "s|${OUTPUT_DIR}/|  |"
echo "================================================================="
