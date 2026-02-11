#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt update

# List upgradeable packages
echo -e "\nUpgradeable packages:"
apt list --upgradable 2>/dev/null | grep -v "^Listing..."

