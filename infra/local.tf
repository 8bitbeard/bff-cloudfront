locals {
  config_file_content = yamldecode(file(var.api_config_file))["apis"]

  api_configs = [
    for api in local.config_file_content : {
      api_name     = api.name
      domain       = api.domain
      context_path = api.context_path
    }
  ]

  route_configs = flatten([
    for api in local.config_file_content : (
      length(lookup(api, "route_cache_configuration", [])) > 0 ? [
        for route in api.routes : {
          api_name       = api.name
          domain         = api.domain
          context_path   = api.context_path
          path_pattern   = replace(route.path_pattern, "{[^}]+}", "*") # Converte {var} para *
          cache_duration = lookup(route, "cache_duration", 0)
        }
      ] : []
    )
  ])
}
