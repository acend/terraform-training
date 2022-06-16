terraform {
  required_version = "=1.2.3"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "=3.3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "=2.2.2"
    }
  }
}