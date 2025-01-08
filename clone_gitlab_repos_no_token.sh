#!/bin/bash

# Author: Eshanized
# Contact: m.eshanized@gmail.com
# GitHub: https://github.com/eshanized
# Description:
#   This script fetches and clones all public repositories of a specified GitLab user.
#   It checks for necessary dependencies, handles errors gracefully, and avoids duplications.

# Check if necessary commands are installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed. Please install curl to proceed."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed. Please install jq to parse JSON responses."
  exit 1
fi

# GitLab API configuration
GITLAB_API_URL="https://gitlab.com/api/v4"
USERNAME=""

# Prompt for username if not already set
if [ -z "$USERNAME" ]; then
  read -p "Enter GitLab username: " USERNAME
fi

# Validate username
if [ -z "$USERNAME" ]; then
  echo "Error: No username provided. Exiting."
  exit 1
fi

# Fetch repositories for the user
echo "Fetching public repositories for user $USERNAME..."
REPOS=$(curl -s "${GITLAB_API_URL}/users/${USERNAME}/projects?per_page=100&visibility=public")

# Check if the API call was successful
if [ $? -ne 0 ]; then
  echo "Error: Unable to fetch repositories. Please check the username."
  exit 1
fi

# Parse repository URLs
REPO_URLS=$(echo "$REPOS" | jq -r '.[].ssh_url_to_repo')

if [ -z "$REPO_URLS" ]; then
  echo "No public repositories found for user $USERNAME."
  exit 0
fi

# Clone each repository
echo "Cloning repositories..."
for REPO_URL in $REPO_URLS; do
  REPO_NAME=$(basename "$REPO_URL" .git)
  if [ -d "$REPO_NAME" ]; then
    echo "Skipping $REPO_NAME (already exists)."
  else
    echo "Cloning $REPO_URL..."
    git clone "$REPO_URL"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to clone $REPO_URL. Skipping."
    fi
  fi
done

echo "All public repositories cloned successfully."
