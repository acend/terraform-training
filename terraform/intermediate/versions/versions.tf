terraform {
  required_version = "=1.1.6"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "=2.2.2"
    }
  }
}