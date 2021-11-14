data "archive_file" "clouds" {
  type        = "zip"
  output_path = "clouds.zip"

  dynamic "source" {
    for_each = var.clouds
    content {
      filename = "${source.key}.txt"
      content  = jsonencode(source.value)
    }
  }
}