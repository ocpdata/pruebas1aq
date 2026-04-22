output "http_lb_name" {
  description = "Name of the F5 XC HTTP load balancer"
  value       = volterra_http_loadbalancer.arcadia.name
}

output "http_lb_cname" {
  description = "Assigned XC CNAME for the HTTP load balancer"
  value       = data.volterra_http_loadbalancer_state.arcadia.cname
}

output "http_lb_ip_address" {
  description = "Assigned XC IP address for the HTTP load balancer"
  value       = data.volterra_http_loadbalancer_state.arcadia.ip_address
}

output "app_firewall_name" {
  description = "App Firewall profile attached to the load balancer"
  value       = volterra_app_firewall.arcadia.name
}
