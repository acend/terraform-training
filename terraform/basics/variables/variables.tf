locals {
  random_max_value = var.random_min_value + 31337
}

variable "random_min_value" {
  type        = number
  default     = 1000
  description = "define the min value of the random number"
}