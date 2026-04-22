output "id"  { description = "Random ID hex. Use for state practice." ; value = random_id.this.hex }
output "b64" { description = "Random ID base64." ; value = random_id.this.b64_std }