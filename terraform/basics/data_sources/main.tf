resource "random_integer" "number" {
  min = 1000
  max = 9999
}

resource "local_file" "random" {
  content  = random_integer.number.result
  filename = "random.txt"
}

data "local_file" "propaganda" {
  filename = "propaganda.txt"
}

