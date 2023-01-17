terraform {
  required_version = "=1.3.5"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "=3.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
  }
}