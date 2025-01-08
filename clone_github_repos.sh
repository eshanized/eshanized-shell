#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ -z "$1" ]; then
  echo -e "${RED}Usage: $0 <github-username> [destination-directory]${RESET}"
  exit 1
fi

GITHUB_USER=$1
DEST_DIR=${2:-./$GITHUB_USER-repos}
GITHUB_API="https://api.github.com/users/$GITHUB_USER/repos?per_page=100"

clone_repos() {
  echo -e "${CYAN}Fetching repositories for user: ${BLUE}$GITHUB_USER${RESET}"

  response=$(curl -s -w "%{http_code}" "$GITHUB_API")
  http_status=${response: -3}
  repo_data=${response:0:$((${#response} - 3))}
  
  if [[ "$http_status" -ne 200 ]]; then
    echo -e "${RED}Error: Failed to fetch repositories (HTTP Status: $http_status).${RESET}"
    exit 1
  fi

  repos=$(echo "$repo_data" | jq -r '.[].clone_url' 2>/dev/null)
  
  if [ -z "$repos" ]; then
    echo -e "${YELLOW}No repositories found or user does not exist.${RESET}"
    exit 1
  fi

  echo -e "${GREEN}Found repositories. Cloning into: ${BLUE}$DEST_DIR${RESET}"
  mkdir -p "$DEST_DIR"
  cd "$DEST_DIR" || exit

  for repo in $repos; do
    repo_name=$(basename "$repo" .git)
    if [ -d "$repo_name" ]; then
      echo -e "${YELLOW}Skipping ${BLUE}$repo_name${YELLOW} (already exists).${RESET}"
    else
      echo -e "${CYAN}Cloning ${BLUE}$repo...${RESET}"
      git clone "$repo"
    fi
  done

  echo -e "${GREEN}All repositories cloned successfully!${RESET}"
}

if ! command -v jq &>/dev/null; then
  echo -e "${RED}The jq tool is required but not installed. Please install it and try again.${RESET}"
  exit 1
fi

clone_repos
