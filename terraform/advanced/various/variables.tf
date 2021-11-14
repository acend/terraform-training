variable "clouds" {
  default = {
    aws = {
      company    = "Amazon"
      founder    = "Jeff Bezos"
      cloud_rank = 1
    }
    azure = {
      company    = "Microsoft"
      founder    = "Bill Gates"
      cloud_rank = 2
    }
    gcp = {
      company    = "Google"
      founder    = "Larry Page and Sergey Brin"
      cloud_rank = 3
    }
  }
  type = map(object({
    company    = string
    founder    = string
    cloud_rank = number
  }))
}