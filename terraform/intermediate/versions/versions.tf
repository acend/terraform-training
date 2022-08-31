terraform {
  required_version = "=1.2.8"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "=3.4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "=2.2.3"
    }
  }
}