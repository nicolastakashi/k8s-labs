terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.0.17"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }

    helm = {
      source  = "hashicorp/helm",
      version = "2.9.0"
    }
  }
}
