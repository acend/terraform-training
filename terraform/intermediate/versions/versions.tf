terraform {
  required_version = "=1.3.6"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "=3.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "=2.2.3"
    }
  }
}