module "first" {
  source    = "./random_file"
  extension = "txt"
  size      = 1337
}

module "second" {
  source    = "./random_file"
  extension = "txt"
  size      = 42
}

output "filenames" {
  value = [
    module.first.filename,
    module.second.filename
  ]
}