#!/bin/bash

# Author: Eshanized
# Contact: m.eshanized@gmail.com
# GitHub: https://github.com/eshanized
# Description:
#   This script fetches and clones all repositories of a specified GitLab user
#   using their personal access token (PAT). It ensures necessary dependencies are installed
#   and provides meaningful error messages for better user experience.

# Check if necessary commands are installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed. Install jq to parse JSON."
  exit 1
fi

# GitLab configuration
GITLAB_API_URL="https://gitlab.com/api/v4"
USERNAME=""
TOKEN=""

# Prompt for username and token if not already set
if [ -z "$USERNAME" ]; then
  read -p "Enter GitLab username: " USERNAME
fi

if [ -z "$TOKEN" ]; then
  read -sp "Enter your GitLab Personal Access Token: " TOKEN
  echo
fi

# Fetch repositories for the user
echo "Fetching repositories for user $USERNAME..."
RESPONSE=$(curl -s --header "Private-Token: $TOKEN" "${GITLAB_API_URL}/users/${USERNAME}/projects?per_page=100")
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --header "Private-Token: $TOKEN" "${GITLAB_API_URL}/users/${USERNAME}/projects?per_page=100")

# Check if the API call was successful
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: Unable to fetch repositories (HTTP Status: $HTTP_STATUS). Please check your username and token."
  exit 1
fi

# Parse repository URLs
REPO_URLS=$(echo "$RESPONSE" | jq -r '.[].ssh_url_to_repo')

if [ -z "$REPO_URLS" ]; then
  echo "No repositories found for user $USERNAME."
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
  fi
done

echo "All repositories cloned successfully."
