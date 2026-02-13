locals {
    organization_name = "signalroom"
    agent_pool_name   = "signalroom-iac-tfc-agents-pool"
    workspace_name    = "iac-cc-app-resources-example"
}

data "tfe_organization" "signalroom" {
  name = local.organization_name
}

data "tfe_workspace" "workspace" {
  name         = local.workspace_name
  organization = data.tfe_organization.signalroom.name
}

data "tfe_agent_pool" "workspace_agent_pool" {
  name          = local.agent_pool_name
  organization  = data.tfe_organization.signalroom.name
}

resource "tfe_agent_pool_allowed_workspaces" "agent-pool-allowed-workspaces" {
  agent_pool_id         = data.tfe_agent_pool.workspace_agent_pool.id
  allowed_workspace_ids = [data.tfe_workspace.workspace.id]
}

resource "tfe_workspace_settings" "workspace_settings" {
  workspace_id   = data.tfe_workspace.workspace.id
  agent_pool_id  = tfe_agent_pool_allowed_workspaces.agent-pool-allowed-workspaces.agent_pool_id
  execution_mode = "agent"
}