variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the network resources"
  type        = string
}

variable "network_prefix" {
  description = "Prefix for network resource names"
  type        = string
  default     = "net"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
}

variable "vnet_name" {
  description = "Unique name identifier for this VNet instance"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets with their address prefixes and NSG attachment option"
  type = map(object({
    address_prefix = string
    attach_nsg     = optional(bool, true) # Optional parameter, defaults to true
  }))
  default = {
    "frontend" = {
      address_prefix = "10.0.1.0/24"
      attach_nsg     = true
    }
    "backend" = {
      address_prefix = "10.0.2.0/24"
      attach_nsg     = true
    }
  }
}

variable "nsg_inbound_rules" {
  description = "Map of inbound NSG rules"
  type = map(object({
    priority                   = number
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {
    "allow_ssh" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

variable "nsg_outbound_rules" {
  description = "Map of outbound NSG rules"
  type = map(object({
    priority                   = number
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {
    "allow_internet" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}