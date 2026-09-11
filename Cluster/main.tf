terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# ---------------------------------------------------------
# Resource Group
# ---------------------------------------------------------

resource "azurerm_resource_group" "devopsshack_rg" {
  name     = "devopsshack-rg"
  location = var.location

  tags = {
    Name = "devopsshack-rg"
  }
}

# ---------------------------------------------------------
# Virtual Network
# AWS VPC equivalent
# ---------------------------------------------------------

resource "azurerm_virtual_network" "devopsshack_vnet" {
  name                = "devopsshack-vnet"
  location            = azurerm_resource_group.devopsshack_rg.location
  resource_group_name = azurerm_resource_group.devopsshack_rg.name

  address_space = ["10.0.0.0/16"]

  tags = {
    Name = "devopsshack-vnet"
  }
}

# ---------------------------------------------------------
# Subnet 1
# AWS subnet equivalent
# ---------------------------------------------------------

resource "azurerm_subnet" "devopsshack_subnet_1" {
  name                 = "devopsshack-subnet-1"
  resource_group_name  = azurerm_resource_group.devopsshack_rg.name
  virtual_network_name = azurerm_virtual_network.devopsshack_vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

# ---------------------------------------------------------
# Subnet 2
# ---------------------------------------------------------

resource "azurerm_subnet" "devopsshack_subnet_2" {
  name                 = "devopsshack-subnet-2"
  resource_group_name  = azurerm_resource_group.devopsshack_rg.name
  virtual_network_name = azurerm_virtual_network.devopsshack_vnet.name

  address_prefixes = ["10.0.2.0/24"]
}

# ---------------------------------------------------------
# Network Security Group
# AWS Security Group equivalent
# ---------------------------------------------------------

resource "azurerm_network_security_group" "devopsshack_node_nsg" {
  name                = "devopsshack-node-nsg"
  location            = azurerm_resource_group.devopsshack_rg.location
  resource_group_name = azurerm_resource_group.devopsshack_rg.name

  # SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTP
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "devopsshack-node-nsg"
  }
}

# ---------------------------------------------------------
# Associate NSG with Subnet 1
# ---------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "subnet_1" {
  subnet_id                 = azurerm_subnet.devopsshack_subnet_1.id
  network_security_group_id = azurerm_network_security_group.devopsshack_node_nsg.id
}

# ---------------------------------------------------------
# Associate NSG with Subnet 2
# ---------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "subnet_2" {
  subnet_id                 = azurerm_subnet.devopsshack_subnet_2.id
  network_security_group_id = azurerm_network_security_group.devopsshack_node_nsg.id
}

# ---------------------------------------------------------
# AKS Cluster
# AWS EKS equivalent
# ---------------------------------------------------------

resource "azurerm_kubernetes_cluster" "devopsshack" {
  name                = "devopsshack-cluster"
  location            = azurerm_resource_group.devopsshack_rg.location
  resource_group_name = azurerm_resource_group.devopsshack_rg.name

  dns_prefix = "devopsshack"

  # Free tier for practice
  sku_tier = "Free"

  # -------------------------------------------------------
  # Managed Identity
  # -------------------------------------------------------

  identity {
    type = "SystemAssigned"
  }

  # -------------------------------------------------------
  # Node Provisioning
  # Required by current AzureRM provider
  # -------------------------------------------------------

  node_provisioning_profile {
    mode = "Auto"
  }

  # -------------------------------------------------------
  # Default Node Pool
  # -------------------------------------------------------

  default_node_pool {
    name = "default"

    node_count = 3

    # Similar size to AWS t2.large
    vm_size = "Standard_D2s_v5"

    vnet_subnet_id = azurerm_subnet.devopsshack_subnet_1.id

    tags = {
      Name = "devopsshack-node"
    }
  }

  # -------------------------------------------------------
  # Linux SSH Access
  # -------------------------------------------------------

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = file(var.ssh_public_key_path)
    }
  }

  # -------------------------------------------------------
  # Networking
  # -------------------------------------------------------

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  tags = {
    Name = "devopsshack-cluster"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.subnet_1
  ]
}

