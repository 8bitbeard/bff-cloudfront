locals {
  config_file_content = try(
    yamldecode(file(var.api_config_file))["apis"],
    error("Falha ao ler ou analisar o arquivo YAML '${var.api_config_file}'. Verifique se o arquivo existe e é um YAML válido com a chave 'apis'.")
  )

  api_configs = [
    for api in local.config_file_content : {
      api_name = try(
        api.name,
        error("Campo 'name' ausente em um dos objetos presentes na configuração da API")
      )
      domain = try(
        api.domain,
        error("Campo 'domain' ausente para a API '${try(api.name, "sem nome")}'")
      )
      context_path = try(
        api.context_path,
        error("Campo 'context_path' ausente para a API '${try(api.name, "sem nome")}'")
      )
    }
  ]

  route_configs = flatten([
    for api in local.config_file_content : (
      length(lookup(api, "route_cache_configuration", [])) > 0 ? [
        for route in api.route_cache_configuration : {
          api_name     = api.name
          domain       = api.domain
          context_path = api.context_path
          path_pattern = replace(
            try(
              route.path_pattern,
              error("Campo 'path_pattern' ausente em 'route_cache_configuration' para a API '${api.name}'")
            ),
            "{[^}]+}",
            "*"
          )
          cache_duration = try(
            route.cache_duration,
            error("Campo 'cache_duration' ausente em 'route_cache_configuration' para a API '${api.name}'. Caso não deseje configurar cache para esta rota, a adição da mesma no campo 'route_cache_configuration' não é necessária")
          )
        }
      ] : []
    )
  ])
}
