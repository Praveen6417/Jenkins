variable "cidr_blocks" {
    type = list(string)
    default = ["0.0.0.0/0"]
}

variable ingress_port_no{
    type = number
    default = 8080
}

variable instance_type{
    type = string
    default = "t2.micro"
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