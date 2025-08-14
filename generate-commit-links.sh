#!/bin/bash

# Generate commit links for a tag with commit history
# Usage: generate-commit-links.sh --tag TAG_NAME --previous-tag PREVIOUS_TAG --repository REPO --output-file OUTPUT_FILE

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

if [ -z "$REPOSITORY" ]; then
    echo "Error: --repository is required"
    exit 1
fi

if [ -z "$OUTPUT_FILE" ]; then
    echo "Error: --output-file is required"
    exit 1
fi

# Generate commit links
if [ -n "$PREVIOUS_TAG" ]; then
    echo "Generating commit links from $PREVIOUS_TAG to $TAG_NAME"
    
    # Get commit range
    COMMIT_RANGE="$PREVIOUS_TAG..$TAG_NAME"
    
    # Generate commit links - use efficient redirect
    {
        git log --pretty=format:"- [%h](https://github.com/$REPOSITORY/commit/%H) %s" "$COMMIT_RANGE"
    } > tmp_commit_links.md
    
    # Use printf to avoid newline issues with heredoc
    {
        printf "links<<EOF\n"
        cat tmp_commit_links.md
        printf "\nEOF\n"
    } >> "$OUTPUT_FILE"
    
    # Clean up temporary file
    rm -f tmp_commit_links.md
else
    echo "links=Initial release" >> "$OUTPUT_FILE"
fi

echo "Commit links generated successfully"
