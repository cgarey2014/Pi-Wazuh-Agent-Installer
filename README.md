<img src="assets/banner.jpg" alt="cover" style="width:100%;" />


# Building a Raspberry Pi 4B Network SIEM with Wazuh and Suricata

This project aims to set up a **Security Information and Event Management (SIEM)** system on a **Raspberry Pi 4B** using **Wazuh** and **Suricata** for enhanced network security monitoring. By leveraging these powerful tools, we create a robust network monitoring system that analyzes network traffic, detects potential intrusions, and sends real-time alerts to ensure a secure environment.

## 📋 Key Features:
- **Network Monitoring**: Suricata provides detailed insights into network traffic, helping detect malicious activity at the packet level.
- **Log Analysis**: Wazuh analyzes system logs to identify threats, weaknesses, and anomalous behaviors.

## 📡 How It Works:
1. **Raspberry Pi 4B** serves as the central unit, running both **Wazuh** and **Suricata**.
2. **Wazuh** collects and analyzes logs from various sources, correlating data to detect potential threats.
3. **Suricata** captures network traffic, inspecting packets to identify suspicious activity..

## 🔧 Prerequisites:
Before running the setup, ensure you have the following:
- A **Raspberry Pi 4B** running **Ubuntu Server 22.04**.
- **Wazuh Manager** is already installed and configured on a separate system to handle log collection and analysis.
- Basic understanding of network security tools and monitoring.

## 📝 Installation and Usage:

### Install Git (if not already installed):
If git is not installed on the system, they can install it by running the following command:

```bash
sudo apt update
sudo apt install git
```
### Clone the Repository: 
To download the script from GitHub, they need to clone your repository. They can do this by running the following command in the terminal:

```bash
git clone https://github.com/cgarey2014/Pi-Wazuh-Agent-Installer.git
```

### Navigate to the Script Directory: 
After cloning the repository, they can navigate to the directory where the script is located:

```bash
cd Pi-Wazuh-Agent-Installer
```

### Make the Script Executable: 
Before running the script, you need to ensure that it has execute permissions. They can do this by running:

```bash
chmod +x pi_wazuh_setup.sh
```

### Run the Script: 
Finally, they can run the script with the following command:

```bash
./pi_wazuh_setup.sh
```
