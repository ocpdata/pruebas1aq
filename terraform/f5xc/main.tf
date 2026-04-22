locals {
  origin_server_name = var.origin_public_dns != "" ? var.origin_public_dns : var.origin_public_ip
}

resource "volterra_app_firewall" "arcadia" {
  name      = "${var.name}-waf"
  namespace = var.xc_namespace

  allow_all_response_codes = true
  disable_anonymization    = true
  use_default_blocking_page = true
  default_bot_setting      = true
  default_detection_settings = true
  monitoring               = true
  disable_ai_enhancements  = true
}

resource "volterra_origin_pool" "arcadia" {
  name                   = "${var.name}-origin"
  namespace              = var.xc_namespace
  endpoint_selection     = var.origin_endpoint_selection
  loadbalancer_algorithm = "ROUND_ROBIN"
  port                   = var.origin_public_port
  no_tls                 = true

  origin_servers {
    public_ip {
      ip = var.origin_public_ip
    }

    labels = {
      app = var.name
    }
  }
}

resource "volterra_http_loadbalancer" "arcadia" {
  name      = var.name
  namespace = var.xc_namespace

  advertise_on_public_default_vip = true
  no_challenge                    = true
  disable_api_testing             = true
  disable_api_definition          = true
  disable_rate_limit              = true
  disable_malware_protection      = true
  disable_malicious_user_detection = true
  disable_threat_mesh             = true
  disable_trust_client_ip_headers = true
  disable_client_side_defense     = true
  default_sensitive_data_policy   = true
  no_service_policies             = true
  user_id_client_ip               = true
  l7_ddos_action_none             = true
  round_robin                     = true
  domains                         = [var.arcadia_domain]

  app_firewall {
    name      = volterra_app_firewall.arcadia.name
    namespace = var.xc_namespace
  }

  enable_api_discovery {
    api_crawler {
      disable_api_crawler = true
    }

    default_api_auth_discovery      = true
    disable_learn_from_redirect_traffic = true

    discovered_api_settings {
      purge_duration_for_inactive_discovered_apis = 2
    }
  }

  http {
    dns_volterra_managed = false
    port                 = 80
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.arcadia.name
      namespace = var.xc_namespace
    }

    priority = 1
    weight   = 1
  }
}

data "volterra_http_loadbalancer_state" "arcadia" {
  name      = volterra_http_loadbalancer.arcadia.name
  namespace = var.xc_namespace
}
