variable "cidr_blocks" {
    type = list(string)
    default = ["0.0.0.0/0"]
}

variable ingress_port_no{
    type = number
    default = 22
}

variable instance_type{
    type = string
    default = "t2.micro"
}

variable ami_id{
    type = string
    default = "ami-090252cbe067a9e58"
}

variable "instance_names" {
    type = list(string)
    default = ["Jenkins-Master", "Jenkins-Node"]
}

variable "common_tags" {
    default = {
        terraform = true
    }
}