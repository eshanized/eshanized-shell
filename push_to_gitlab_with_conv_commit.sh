#!/bin/bash

# Author        : ESHAN ROY
# Author URI    : https://eshanized.github.io

# Define the conventional commit types with new emojis
TYPES=("🚀 feat" "🐛 fix" "📝 docs" "✨ style" "🛠 refactor" "⚡️ perf" "🔬 test" "🔧 build" "🤖 ci" "🧹 chore" "⏪ revert")

# Function to display an error and exit
error_exit() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
    exit 1
}

# Ensure the script is run in a Git repository
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || error_exit "This is not a Git repository."

# Get the current branch name
branch=$(git rev-parse --abbrev-ref HEAD)

# Pull the latest changes from the GitLab remote repository
echo "Pulling latest changes from GitLab remote branch '$branch'..."
git pull origin "$branch" || error_exit "Failed to pull changes from the remote repository. Please resolve any conflicts manually."

# Prompt the user to select a commit type
echo "Select a commit type:"
select type in "${TYPES[@]}"; do
    if [[ -n "$type" ]]; then
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Extract the commit type and emoji from the selection
type_emoji=${type}
type=${type_emoji#* }
emoji=${type_emoji% *}

# Prompt the user to enter a short description
read -p "Enter a short description: " desc
if [ -z "$desc" ]; then
    error_exit "A short description is required!"
fi

# Prompt the user to enter a longer description (optional)
read -p "Enter a longer description (optional): " long_desc

# Create the commit message
commit_msg="$emoji $type: $desc"

# If a longer description was provided, add it to the commit message
if [ -n "$long_desc" ]; then
    commit_msg+="\n\n$long_desc"
fi

# Print the commit message to the console
echo -e "\nCommit message:"
echo -e "\033[1;36m$commit_msg\033[0m"

# Stage all changes
git add .

# Commit the changes with the conventional commit message
if git commit -m "$commit_msg"; then
    echo -e "\033[1;32mCommit successful!\033[0m"
else
    error_exit "Commit failed."
fi

# Push the changes to the GitLab remote repository
echo "Pushing changes to GitLab remote branch '$branch'..."
if git push origin "$branch"; then
    echo -e "\033[1;32mChanges pushed to GitLab remote branch '$branch'.\033[0m"
else
    error_exit "Push failed. Please check your connection or branch permissions."
fi

# Optional: Trigger a GitLab CI/CD pipeline (if configured)
read -p "Do you want to trigger a GitLab CI/CD pipeline? (y/n): " trigger_ci
if [[ "$trigger_ci" =~ ^[Yy]$ ]]; then
    echo "Triggering GitLab CI/CD pipeline..."
    gitlab_project_id=$(git remote -v | grep origin | head -n 1 | awk -F'[:/]' '{print $NF}' | sed 's/\.git$//')

    if [ -z "$gitlab_project_id" ]; then
        error_exit "Unable to determine GitLab project ID. Please check your repository configuration."
    fi

    # Prompt for a GitLab personal access token
    read -sp "Enter your GitLab Personal Access Token: " gitlab_token
    echo

    curl -X POST \
        -H "PRIVATE-TOKEN: $gitlab_token" \
        "https://gitlab.com/api/v4/projects/${gitlab_project_id}/trigger/pipeline?ref=${branch}"

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32mGitLab CI/CD pipeline triggered successfully.\033[0m"
    else
        error_exit "Failed to trigger GitLab CI/CD pipeline."
    fi
fi
