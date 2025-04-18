#!/bin/bash

# Begin with prerequisites
echo "Starting bridge protocol"
echo "Updating System. Please wait..."
sudo apt update && sudo apt upgrade -y
if [[ $? -ne 0 ]]; then
  echo "An error occurred during system update. Exiting."
  exit 1
fi
echo "Update complete."

echo "Installing dependencies. One moment..."
sudo apt install bridge-utils netplan.io -y
if [[ $? -ne 0 ]]; then
  echo "An error occurred during dependencies installation. Exiting."
  exit 1
fi
echo "Installation complete."

# Backup and adjust Netplan
echo "Adjusting Netplan. Please wait."
if [[ -f /etc/netplan/01-netcfg.yaml ]]; then
  echo "Backing up existing /etc/netplan/01-netcfg.yaml"
  sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak
fi

sudo tee /etc/netplan/01-netcfg.yaml > /dev/null << EOF
network:
  version: 2 
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
    eth1: 
      dhcp4: no  
  bridges:
    br0:
      interfaces: [eth0, eth1]
      dhcp4: yes
EOF
echo "Adjustment complete."

echo "Applying new configuration..."
sudo netplan apply
if ! ip addr show br0 | grep -q "inet"; then
  echo "Bridge interface br0 is not up. Exiting."
  exit 1
fi

# Verify the bridge connection
if ip addr show br0 &>/dev/null; then
  echo "br0 exists. Continuing with Wazuh installation..."

  # Import the Wazuh GPG key
  echo "Adding GPG key and APT repository for Wazuh:"
  curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg 

  # Add the Wazuh APT repository
  echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

  # Update the package list and install Wazuh
  echo "Starting install. Please wait.."
  sudo apt update && sudo apt install wazuh-agent -y
  if [[ $? -ne 0 ]]; then
    echo "An error occurred during Wazuh installation. Exiting."
    exit 1
  fi

  # Ask user for Wazuh server IP
  read -p "Please enter the IP address of the Wazuh server: " wazuh_Server

  # Validate the input is not empty
  if [[ -z "$wazuh_Server" ]]; then
    echo "No IP address entered. Exiting."
    exit 1
  fi

  # Define path to the Wazuh config file
  config_file="/var/ossec/etc/ossec.conf"

  # Make a backup before modifying
  sudo cp "$config_file" "${config_file}.bak"

  # Replace the server IP in the XML
  if ! sudo sed -i "s|<server-ip>yourserverip</server-ip>|<server-ip>${wazuh_Server}</server-ip>|" "$config_file"; then
    echo "Failed to update Wazuh server IP. Exiting."
    exit 1
  fi

  echo "Wazuh server IP updated in /var/ossec/etc/ossec.conf."
  
  # Enable the Wazuh Service and start
  echo "Enabling Wazuh Agent system service"
  sudo systemctl enable wazuh-agent
  sudo systemctl start wazuh-agent
  # Check if wazuh-agent is active and enabled
  if systemctl is-active --quiet wazuh-agent && systemctl is-enabled --quiet wazuh-agent; then
    echo "Wazuh installation complete. Service is enabled at startup and running."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Begin Suricat installation
  echo "Installing Suricata. Please wait..."
  sudo apt install suricata -y
  if [[ $? -ne 0 ]]; then
    echo "An error occurred during Suricata installation. Exiting."
    exit 1
  fi
  echo "Suricata installation complete."
  
  # Enable Suricata to start on boot
  echo "Enabling Suricata system service"
  sudo systemctl enable suricata
  sudo systemctl start suricata
  
  # Check if suricata is active and enabled
  if systemctl is-active --quiet suricata && systemctl is-enabled --quiet suricata; then
    echo "Suricata installation complete. Service is enabled at startup and running."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Configure Suricata to monitor the bridged interface br0
  echo "Configuring Suricata to monitor the bridged interface br0"
  sudo sed -i 's/af-packet:/af-packet:\n  - interface: br0/' /etc/suricata/suricata.yaml
  
  # Restart Suricata to apply changes
  echo "Restarting Suricata to apply changes"
  sudo systemctl restart suricata
  
  # Check if suricata is active and enabled
  if systemctl is-active --quiet suricata && systemctl is-enabled --quiet suricata; then
    echo "suricata.yaml has been updated to monitor br0 and restarted."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Enable Suricata rule sources
  echo "Enabling Suricata rule sources"
  sudo suricata-update
  
  # Check if suricata-update is active and enabled
  if systemctl is-active --quiet suricata-update && systemctl is-enabled --quiet suricata-update; then
    echo "Suricata rule sources have been enabled."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Restart Suricata to apply changes
  echo "Restarting Suricata to apply changes"
  sudo systemctl restart suricata
  
  # Check if suricata is active and enabled
  if systemctl is-active --quiet suricata && systemctl is-enabled --quiet suricata; then
    echo "Suricata rule sources have been enabled and Suricata has been restarted."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Integrate Suricata logs with Wazuh
  echo "Integrating Suricata logs with Wazuh"
  sudo mkdir -p /var/ossec/logs/archives
  sudo mkdir -p /var/ossec/logs/archives/suricata
  sudo chown -R wazuh:wazuh /var/ossec/logs/archives/suricata
  sudo chmod -R 750 /var/ossec/logs/archives/suricata
  
  # Create a symbolic link to Suricata logs
  echo "Creating symbolic link to Suricata logs"
  sudo ln -s /var/log/suricata/eve.json /var/ossec/logs/archives/suricata/eve.json
  
  # Check if the symbolic link was created successfully
  if [[ -L /var/ossec/logs/archives/suricata/eve.json ]]; then
    echo "Symbolic link to Suricata logs created successfully."
  else
    echo "Failed to create symbolic link to Suricata logs. Exiting."
    exit 1
  fi
  
  # Restart Wazuh agent to apply changes
  echo "Restarting Wazuh agent to apply changes"
  sudo systemctl restart wazuh-agent
  
  # Check if wazuh-agent is active and enabled
  if systemctl is-active --quiet wazuh-agent && systemctl is-enabled --quiet wazuh-agent; then
    echo "Wazuh agent has been restarted."
  else
    echo "Error encountered enabling service. Please check system logs for more information."
  fi
  
  # Let user know the installation is complete
  echo "Installation complete. Wazuh agent and Suricata are installed and configured to monitor the bridged interface br0."
  echo "Please check the logs for any errors or issues."
  echo "You can view the Suricata logs at /var/log/suricata/eve.json"
  echo "You can view the Wazuh logs at /var/ossec/logs/archives/suricata/eve.json"
  echo "You can view the Wazuh agent logs at /var/ossec/logs/ossec.log"
else
  echo "br0 does not exist. Exiting."
  exit 1
fi
