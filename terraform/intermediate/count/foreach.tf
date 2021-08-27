locals {
  files = {
    "aws.txt"   = "Jeff Bezos"
    "azure.txt" = "Bill Gates"
    "gcp.txt"   = "Larry Page and Sergey Brin"
  }
}

resource "local_file" "cloud_godfathers" {
  for_each = local.files

  filename = each.key
  content  = each.value
}