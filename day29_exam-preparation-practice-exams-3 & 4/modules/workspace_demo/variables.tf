variable "name"           { description = "Name prefix."          ; type = string }
variable "workspace_name" { description = "Current TF workspace." ; type = string }
variable "tags"           { description = "Resource tags."        ; type = map(string) ; default = {} }