
terraform {
  backend "s3" {
    bucket                      = "cloud-service-terraform-bucket"
    key                         = "tmp/cyyoon-cloudservice-image-auto-scale-test/cloudservice-image-auto-scale-test.terraform.tfstate"
    endpoints                   = { s3 = "https://jp-osa-1.linodeobjects.com" }
    region                      = "jp-osa-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.13.0"
    }
  }
}


provider "linode" {
  token = var.linode_token
}

resource "linode_firewall" "firewall" {
  label           = "CLOUDSVC-cy_fw"
  inbound_policy  = "ACCEPT"
  outbound_policy = "ACCEPT"
}

resource "linode_stackscript" "install_nginx" {
  label       = "CLOUDSVC-cy_test_nginx"
  description = "Installs a Package"
  script      = <<EOF
#!/bin/bash
# <UDF name="package" label="System Package to Install" example="nginx" default="">
sudo dnf install nginx wget tar  -y
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl  stop firewalld.service
sudo systemctl  disable firewalld.service
echo "check" >> /usr/share/nginx/html/check.html
echo "ok" >> /usr/share/nginx/html/index.html
set -eo
mkdir -p node_exporter
cd node_exporter || exit 1
wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
tar xvfz node_exporter-1.1.2.linux-amd64.tar.gz
sudo cp node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin/node_exporter
rm -f node_exporter-1.1.2.linux-amd64.tar.gz
sudo tee /etc/systemd/system/node_exporter.service <<EOE
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOE
sudo chmod +x /usr/local/bin/node_exporter
sudo useradd -rs /bin/false node_exporter
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
# Verify that node_exporter is running
sudo systemctl status node_exporter
echo "Node Exporter has been installed and started."
EOF
  images      = ["linode/rocky9"]
  rev_note    = "initial version"
}

resource "linode_instance" "web" {
  count          = var.instance_count
  label          = "CLOUDSVC-cy-web-${count.index + 1}"
  image          = "linode/rocky9"
  region         = "jp-osa"
  type           = "g6-standard-1"
  root_pass      = "Terraform!@34"
  private_ip     = true
  group          = "CLOUDSVC-cy"
  tags           = ["CLOUDSVC-cy"]
  stackscript_id = linode_stackscript.install_nginx.id
}

resource "linode_firewall_device" "firewall_device" {
  count       = var.instance_count
  firewall_id = linode_firewall.firewall.id
  entity_id   = linode_instance.web[count.index].id
}

resource "linode_nodebalancer" "foobar" {
  label                = "CLOUDSVC-cy-LB"
  region               = "jp-osa"
  client_conn_throttle = 20
}

resource "linode_nodebalancer_config" "foofig" {
  nodebalancer_id = linode_nodebalancer.foobar.id
  port            = 80
  protocol        = "http"
  check           = "http"
  check_path      = "/check.html"
  check_attempts  = 1
  check_timeout   = 5
  stickiness      = "http_cookie"
  algorithm       = "source"
}

resource "linode_nodebalancer_node" "foonode" {
  count           = var.instance_count
  nodebalancer_id = linode_nodebalancer.foobar.id
  config_id       = linode_nodebalancer_config.foofig.id
  address         = "${element(linode_instance.web.*.private_ip_address, count.index)}:80"
  label           = "CLOUDSVC-cy-LB-Node"
  weight          = 50
}
