variable "xc_api_p12_file" {
  description = "Path to the XC API credential bundle reconstructed on the runner"
  type        = string
  sensitive   = true
}

variable "xc_api_url" {
  description = "F5 Distributed Cloud API URL"
  type        = string
}

variable "xc_namespace" {
  description = "Namespace where F5 XC resources will be created"
  type        = string
  default     = "default"
}

variable "name" {
  description = "Base name for F5 XC resources"
  type        = string
  default     = "arcadia"
}

variable "arcadia_domain" {
  description = "Public domain to publish through the XC HTTP load balancer"
  type        = string
}

variable "origin_public_ip" {
  description = "Public IP of the Arcadia origin host"
  type        = string
}

variable "origin_public_dns" {
  description = "Public DNS name of the Arcadia origin host"
  type        = string
  default     = ""
}

variable "origin_public_port" {
  description = "Public port exposed by the Arcadia origin"
  type        = number
  default     = 80
}

variable "origin_endpoint_selection" {
  description = "Origin endpoint selection policy for XC origin pools"
  type        = string
  default     = "LOCAL_PREFERRED"
}
