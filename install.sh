#!/bin/bash

# Check if the script is run with sudo permissions
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo permissions."
  exit 1
fi
#!/bin/bash

# Define the repository URL
REPO="https://github.com/supervue/supersync"

# Extract the repository name from the URL
REPO_NAME=$(basename $REPO)

# Download the repository as a zip file
wget -O $REPO_NAME.zip "$REPO/archive/refs/heads/main.zip"

# Extract the zip file using Python and move the contents to the script's directory
python3 - <<END
import zipfile
import os
import shutil

# Define paths
zip_file = "$REPO_NAME.zip"
extract_to = "$REPO_NAME"

# Extract the zip file
with zipfile.ZipFile(zip_file, 'r') as zip_ref:
    zip_ref.extractall(extract_to)

# Move extracted files from the subfolder to the current directory
extracted_dir = os.path.join(extract_to, os.listdir(extract_to)[0])
for item in os.listdir(extracted_dir):
    shutil.move(os.path.join(extracted_dir, item), ".")

# Clean up
shutil.rmtree(extract_to)
END

# Clean up by removing the zip file
rm $REPO_NAME.zip

echo "Files cloned into the current directory."

cd node_monitoring
pwd

chmod +x cont_vit
chmod +x node_vit

# Function to install Docker
install_docker() {
  echo "Updating package database..."
  apt-get update -y

  echo "Installing required packages..."
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  echo "Adding Docker GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  echo "Adding Docker repository..."
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  echo "Updating package database..."
  apt-get update -y

  echo "Installing Docker..."
  apt-get install -y docker-ce

  echo "Docker installed successfully."
}

# Function to install Go using snap
install_go() {
  echo "Installing Go using snap..."
  snap install go --classic

  echo "Go installed successfully."
}

# Function to check Go version
check_go_version() {
  if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}' | cut -d'.' -f2)
    if [ "$GO_VERSION" -ge 17 ]; then
      return 0
    fi
  fi
  return 1
}

# Check if Go 1.17 or above is installed
if ! check_go_version; then
  echo "Go 1.17 or higher is not installed. Installing Go..."
  install_go
else
  echo "Go 1.17 or higher is already installed."
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing Docker..."
  install_docker
else
  echo "Docker is already installed."
fi

# Ensure the current user is added to the docker group
if ! groups $SUDO_USER | grep -q "\bdocker\b"; then
  echo "Adding user to docker group..."
  usermod -aG docker $SUDO_USER
  echo "User added to docker group. Please log out and log back in for the changes to take effect."
else
  echo "User is already in the docker group."
fi

# Check Docker permissions
docker_permission_check() {
  if ! docker run hello-world &> /dev/null; then
    echo "Docker permissions not set correctly. Fixing permissions..."
    chmod 666 /var/run/docker.sock
    echo "Permissions fixed. Please log out and log back in for the changes to take effect."
  else
    echo "Docker permissions are set correctly."
  fi
}

docker_permission_check

# Check if the @reboot command is already in the crontab
crontab -l | grep -q '@reboot /root/start_monitoring.sh'
if [ $? -ne 0 ]; then
  # If not found, add it to the crontab
  (crontab -l; echo "@reboot /root/start_monitoring.sh") | crontab -
fi

# Check if the @reboot command is already in the crontab
crontab -l | grep -q '@reboot /root/start_services.sh'
if [ $? -ne 0 ]; then
  # If not found, add it to the crontab
  (crontab -l; echo "@reboot /root/start_services.sh") | crontab -
fi
cd ..
chmod +x start_monitoring.sh
chmod +x start_services.sh
cd ~/node_monitoring/check-pull-run-kill-delete
chmod +x start_trash.sh

# Restart the systemctl service
systemctl daemon-reload
# Restart the cron service
service cron restart
echo "restarted cron service"
echo ""
echo ""
echo ""
echo "-----------------------------------"
echo ""
echo "Reboot to complete installation."
echo ""
echo "-----------------------------------"
