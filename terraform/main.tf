terraform {
    cloud {
      organization = "signalroom"

        workspaces {
            name = "iac-cc-app-resources-example"
        }
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.32.0"
        }
        confluent = {
            source  = "confluentinc/confluent"
            version = "2.62.0"
        }
        time = {
            source  = "hashicorp/time"
            version = "~> 0.13.1"
        }
        tfe = {
            source = "hashicorp/tfe"
            version = "~> 0.73.0"
        }
    }
}
