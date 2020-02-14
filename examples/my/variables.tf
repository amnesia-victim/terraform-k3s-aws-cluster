# region
variable "k3s_region" {
  default = "us-east-1"
  description = "Default region for k3s installation"
}

variable "aws_profile" {
  default = "default"
  description = "Default aws profile"
}

variable "aws_azs" {
  type = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}




variable "name" {
  default = "k4s"
  description = "domain for k3s cluser"
}

variable "domain" {
  default = "lab.polyakov.space"
  description = "domain zone for k3s cluster"
}

variable "ssh_keys" {
  type        = list
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvXfGGHHEc4qI1iOxxEME3G4ONzBN/0YFpCMZD5+cqPaMd4usSu6ChT0ZGeLCR/jpAKY0dTboU5fV6Afv2phnX6ggB1rWRi86CZBO/HKdLWP8sveK3u2jRGgYAKj+sQcUoYZjA12Zfnxw3O+s3hW4ZYfHfzsMWuLUo9yGiA+i1CiX7OPtaLoYLkaJpWc+rS5bA087m9vVaGhnQCHGrFutQdklMEa8dKqQumWIaKGau3DvhLaCfKorHKMeARudijwprjF8imeE0izttAO2SSX/Ftet5LHyJTZGKojtEEpkZeqB7inMocGQcgcNH5musGnQEvez/OEU3ClLEu9kAbbGf amnesiax@Dmitrys-MacBook-Pro.local"] 
  description = "SSH keys to inject into Rancher instances"
}


