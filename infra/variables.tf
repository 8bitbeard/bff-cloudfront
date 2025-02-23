variable "api_config_file" {
  type        = string
  description = "Caminho para o arquivo YAML de configuração das APIs"

  validation {
    condition     = can(regex("(?i)\\.ya?ml$", var.api_config_file))
    error_message = "O arquivo de configuração deve ter extensão .yaml ou .yml."
  }
}