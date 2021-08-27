resource "random_pet" "filename" { }

resource "random_password" "content" {
  length = var.size
}

resource "local_file" "this" {
  filename = "${random_pet.filename.id}.${var.extension}"
  content = random_password.content.result
}