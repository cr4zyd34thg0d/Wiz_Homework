# update and basic tools
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates gnupg lsb-release apt-transport-https jq

# Install kubectl (official)
curl -fsSL https://dl.k8s.io/release/stable.txt -o /tmp/k8sver
KVER=$(cat /tmp/k8sver)
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl /tmp/k8sver

# Install kind
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install psql client (Postgres client)
sudo apt install -y postgresql-client

# Quick check
kubectl version --client --short
kind --version
psql --version
