resource "local_file" "foobar_txt" {
  content  = "13374asdf"
  filename = "foobar.txt"

  lifecycle {
    ignore_changes = [content]
  }
}

data "local_file" "reference" {
  filename = "foobar.txt"

  depends_on = [local_file.foobar_txt]
}
