# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "my-network-rg"
  location = "eastus"
}

# VNet 1: Application Network
module "app_network" {
  source              = "../../../module/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  network_prefix      = "net"
  environment         = "prod"
  vnet_name           = "app"

  vnet_address_space = ["10.1.0.0/16"]

  subnets = {
    "frontend" = {
      address_prefix = "10.1.1.0/24"
      attach_nsg     = true
    }
    "backend" = {
      address_prefix = "10.1.2.0/24"
      attach_nsg     = true
    }
  }

  nsg_inbound_rules = {
    "ssh" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "https" = {
      priority                   = 110
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  nsg_outbound_rules = {
    "internet" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = {
    "Project" = "MyApp"
    "Purpose" = "Application"
  }
}

# VNet 2: Database Network
module "db_network" {
  source              = "../../../module/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  network_prefix      = "net"
  environment         = "prod"
  vnet_name           = "db"

  vnet_address_space = ["10.2.0.0/16"]

  subnets = {
    "primary" = {
      address_prefix = "10.2.1.0/24"
      attach_nsg     = true
    }
    "secondary" = {
      address_prefix = "10.2.2.0/24"
      attach_nsg     = true
    }
  }

  nsg_inbound_rules = {
    "sql" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.1.0.0/16" # Allow from app network
      destination_address_prefix = "*"
    }
  }

  nsg_outbound_rules = {
    "backup" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "10.1.1.1"
    }
  }

  tags = {
    "Project" = "MyApp"
    "Purpose" = "Database"
  }
}

# VNet 3: Management Network
module "mgmt_network" {
  source              = "../../../module/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  network_prefix      = "net"
  environment         = "prod"
  vnet_name           = "mgmt"

  vnet_address_space = ["10.3.0.0/16"]

  subnets = {
    "monitoring" = {
      address_prefix = "10.3.1.0/24"
      attach_nsg     = true
    }
    "admin" = {
      address_prefix = "10.3.2.0/24"
      attach_nsg     = true
    }
  }

  nsg_inbound_rules = {
    "ssh" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "monitoring" = {
      priority                   = 110
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9100"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  nsg_outbound_rules = {
    "internet" = {
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = {
    "Project" = "MyApp"
    "Purpose" = "Management"
  }
}
