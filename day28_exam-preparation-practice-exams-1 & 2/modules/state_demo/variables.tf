variable "name"        { description = "Name prefix." ; type = string }
variable "environment" { description = "Environment name." ; type = string }
variable "tags"        { description = "Resource tags." ; type = map(string) ; default = {} }