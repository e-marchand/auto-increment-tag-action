#!/bin/bash

# Generate release notes for a tag with commit history
# Usage: generate-release-notes.sh --tag TAG_NAME [--previous-tag PREVIOUS_TAG] [--repository REPO] --output-file OUTPUT_FILE
# Note: If repository is not specified, it will be auto-detected from git remote origin

set -e

# Default values
TAG_NAME=""
PREVIOUS_TAG=""
REPOSITORY=""
OUTPUT_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TAG_NAME="$2"
            shift 2
            ;;
        --previous-tag)
            PREVIOUS_TAG="$2"
            shift 2
            ;;
        --repository)
            REPOSITORY="$2"
            shift 2
            ;;
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$TAG_NAME" ]; then
    echo "Error: --tag is required"
    exit 1
fi

if [ -z "$OUTPUT_FILE" ]; then
    echo "Error: --output-file is required"
    exit 1
fi

# If repository is not provided, try to get it from git remote
if [ -z "$REPOSITORY" ]; then
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ "$REMOTE_URL" == git@github.com:* ]]; then
        # Extract repository from SSH URL
        REPOSITORY=$(echo "$REMOTE_URL" | sed 's|git@github.com:||' | sed 's|\.git$||')
    elif [[ "$REMOTE_URL" == https://github.com/* ]]; then
        # Extract repository from HTTPS URL
        REPOSITORY=$(echo "$REMOTE_URL" | sed 's|https://github.com/||' | sed 's|\.git$||')
    fi
fi

# Generate release notes
if [ -n "$PREVIOUS_TAG" ]; then
    echo "Generating release notes from $PREVIOUS_TAG to $TAG_NAME"
    
    # Get commit range
    COMMIT_RANGE="$PREVIOUS_TAG..$TAG_NAME"
    
    # Get the remote URL from git and convert to web URL
    REMOTE_URL=$(git config --get remote.origin.url)
    if [[ "$REMOTE_URL" == git@github.com:* ]]; then
        # Convert SSH URL to HTTPS
        WEB_URL=$(echo "$REMOTE_URL" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
    elif [[ "$REMOTE_URL" == https://github.com/* ]]; then
        # Already HTTPS, just remove .git suffix if present
        WEB_URL=$(echo "$REMOTE_URL" | sed 's|\.git$||')
    else
        # Fallback to the passed repository parameter for non-GitHub repos
        WEB_URL="https://github.com/$REPOSITORY"
    fi
    
    # Generate release notes with commit links - use efficient redirect
    {
        echo "## Changes since $PREVIOUS_TAG"
        echo ""
        echo "### Commits:"
        git log --pretty=format:"- [%h]($WEB_URL/commit/%H) %s" "$COMMIT_RANGE"
    } > tmp_release_notes.md
    
    # Use printf to avoid newline issues with heredoc
    {
        printf "notes<<EOF\n"
        cat tmp_release_notes.md
        printf "\nEOF\n"
    } >> "$OUTPUT_FILE"
    
    # Clean up temporary file
    rm -f tmp_release_notes.md
else
    echo "notes=Initial release" >> "$OUTPUT_FILE"
fi

echo "Release notes generated successfully"
