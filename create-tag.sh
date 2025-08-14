#!/bin/bash

# Auto Increment Tag Action Script
# This script creates and pushes incremental tags based on branch names

set -e

# Parse command line arguments
BRANCH=""
TAG_PREFIX=""
TAG_SUFFIX=""
GITHUB_TOKEN=""
GIT_DIR=""
OUTPUT_FILE=""
SUMMARY_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --tag-prefix)
      TAG_PREFIX="$2"
      shift 2
      ;;
    --tag-suffix)
      TAG_SUFFIX="$2"
      shift 2
      ;;
    --github-token)
      GITHUB_TOKEN="$2"
      shift 2
      ;;
    --git-dir)
      GIT_DIR="$2"
      shift 2
      ;;
    --output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --summary-file)
      SUMMARY_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Change to git directory if specified
if [ -n "$GIT_DIR" ]; then
  echo "Changing to git directory: $GIT_DIR"
  cd "$GIT_DIR"
fi

# Get current branch name
if [ -n "$BRANCH" ]; then
  BRANCH_NAME="$BRANCH"
else
  BRANCH_NAME=$(git branch --show-current)
fi

echo "Current branch: $BRANCH_NAME"

# Use tag_prefix if provided, otherwise use branch name
if [ -n "$TAG_PREFIX" ]; then
  TAG_PREFIX="$TAG_PREFIX"
  echo "Using provided tag prefix: $TAG_PREFIX"
else
  TAG_PREFIX="$BRANCH_NAME"
  echo "Using branch name as tag prefix: $TAG_PREFIX"
fi

# Set tag suffix if provided
if [ -n "$TAG_SUFFIX" ]; then
  echo "Using tag suffix: $TAG_SUFFIX"
fi

# Get current commit
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "Current commit: $CURRENT_COMMIT"

# Check if there's already a tag with format TAG_PREFIX.* on the current commit
TAG_PATTERN="${TAG_PREFIX}.*"
if [ -n "$TAG_SUFFIX" ]; then
  TAG_PATTERN="${TAG_PREFIX}.*${TAG_SUFFIX}"
fi

if [ -n "$TAG_SUFFIX" ]; then
  # Escape special characters in TAG_SUFFIX for grep
  ESCAPED_SUFFIX=$(echo "$TAG_SUFFIX" | sed 's/[[\.*^$()+?{|]/\\&/g')
  EXISTING_BRANCH_TAG=$(git tag --points-at $CURRENT_COMMIT | grep "^${TAG_PREFIX}\." | grep -- "${ESCAPED_SUFFIX}$" | head -1 || true)
else
  EXISTING_BRANCH_TAG=$(git tag --points-at $CURRENT_COMMIT | grep "^${TAG_PREFIX}\." | head -1 || true)
fi

PREVIOUS_TAG=""

if [ -n "$EXISTING_BRANCH_TAG" ]; then
  echo "Existing tag found on current commit: $EXISTING_BRANCH_TAG"
  TAG_TO_USE=$EXISTING_BRANCH_TAG
  echo "No new tag needed, using existing tag: $TAG_TO_USE"
else
  echo "No tag with format ${TAG_PREFIX}.*${TAG_SUFFIX} found on current commit, creating new tag"
  
  # List existing tags for this prefix and suffix combination
  if [ -n "$TAG_SUFFIX" ]; then
    # Escape special characters in TAG_SUFFIX for grep
    ESCAPED_SUFFIX=$(echo "$TAG_SUFFIX" | sed 's/[[\.*^$()+?{|]/\\&/g')
    EXISTING_TAGS=$(git tag -l "${TAG_PREFIX}.*" | grep -- "${ESCAPED_SUFFIX}$" | sort -V)
  else
    EXISTING_TAGS=$(git tag -l "${TAG_PREFIX}.*" | sort -V)
  fi
  
  if [ -z "$EXISTING_TAGS" ]; then
    # First tag for this prefix and suffix combination
    if [ -n "$TAG_SUFFIX" ]; then
      NEW_TAG="${TAG_PREFIX}.1${TAG_SUFFIX}"
    else
      NEW_TAG="${TAG_PREFIX}.1"
    fi
    echo "First tag for prefix/suffix combination: $NEW_TAG"
  else
    # Find the highest tag and increment
    HIGHEST_TAG=$(echo "$EXISTING_TAGS" | tail -1)
    PREVIOUS_TAG=$HIGHEST_TAG
    echo "Highest existing tag: $HIGHEST_TAG"
    
    # Extract the number and increment
    if [ -n "$TAG_SUFFIX" ]; then
      # Remove both prefix and suffix to get the number
      LAST_NUMBER=$(echo $HIGHEST_TAG | sed "s/^${TAG_PREFIX}\.//" | sed "s/${TAG_SUFFIX}$//" )
    else
      LAST_NUMBER=$(echo $HIGHEST_TAG | cut -d'.' -f2)
    fi
    NEW_NUMBER=$((LAST_NUMBER + 1))
    
    if [ -n "$TAG_SUFFIX" ]; then
      NEW_TAG="${TAG_PREFIX}.${NEW_NUMBER}${TAG_SUFFIX}"
    else
      NEW_TAG="${TAG_PREFIX}.${NEW_NUMBER}"
    fi
    echo "New tag calculated: $NEW_TAG"
  fi
  
  # Create the tag
  git tag -a $NEW_TAG -m "$NEW_TAG"
  echo "Tag $NEW_TAG created"
  
  # Push the tag
  git push origin $NEW_TAG
  echo "Tag $NEW_TAG pushed to origin"
  
  TAG_TO_USE=$NEW_TAG
fi

echo "Final tag used: $TAG_TO_USE"

# Ensure the tag is pushed (in case it was created but not pushed)
git push origin $TAG_TO_USE || echo "Tag $TAG_TO_USE already exists on remote"

# Get commit hashes
TAG_COMMIT=$(git rev-list -n 1 $TAG_TO_USE)
if [ -n "$PREVIOUS_TAG" ]; then
  PREVIOUS_TAG_COMMIT=$(git rev-list -n 1 $PREVIOUS_TAG)
else
  PREVIOUS_TAG_COMMIT=""
fi

# Set output for potential use in other steps
if [ -n "$OUTPUT_FILE" ]; then
  echo "tag=$TAG_TO_USE" >> "$OUTPUT_FILE"
  echo "tag_commit=$TAG_COMMIT" >> "$OUTPUT_FILE"
  if [ -n "$PREVIOUS_TAG" ]; then
    echo "previous_tag=$PREVIOUS_TAG" >> "$OUTPUT_FILE"
    echo "previous_tag_commit=$PREVIOUS_TAG_COMMIT" >> "$OUTPUT_FILE"
  else
    echo "previous_tag=" >> "$OUTPUT_FILE"
    echo "previous_tag_commit=" >> "$OUTPUT_FILE"
  fi
else
  echo "OUTPUT: tag=$TAG_TO_USE"
  echo "OUTPUT: tag_commit=$TAG_COMMIT"
  if [ -n "$PREVIOUS_TAG" ]; then
    echo "OUTPUT: previous_tag=$PREVIOUS_TAG"
    echo "OUTPUT: previous_tag_commit=$PREVIOUS_TAG_COMMIT"
  else
    echo "OUTPUT: previous_tag="
    echo "OUTPUT: previous_tag_commit="
  fi
fi

# Create a summary
SUMMARY_CONTENT="## Release Tag Summary
- **Branch**: $BRANCH_NAME
- **Tag Prefix**: $TAG_PREFIX
- **Tag Suffix**: $TAG_SUFFIX
- **Tag**: $TAG_TO_USE
- **Tag Commit**: $TAG_COMMIT"

if [ -n "$PREVIOUS_TAG" ]; then
  SUMMARY_CONTENT="$SUMMARY_CONTENT
- **Previous Tag**: $PREVIOUS_TAG
- **Previous Tag Commit**: $PREVIOUS_TAG_COMMIT"
else
  SUMMARY_CONTENT="$SUMMARY_CONTENT
- **Previous Tag**: None (first tag)"
fi

if [ "$TAG_TO_USE" = "$NEW_TAG" ]; then
  SUMMARY_CONTENT="$SUMMARY_CONTENT
- **Action**: New tag created and pushed"
else
  SUMMARY_CONTENT="$SUMMARY_CONTENT
- **Action**: Using existing tag (no new tag needed)"
fi

if [ -n "$SUMMARY_FILE" ]; then
  echo "$SUMMARY_CONTENT" >> "$SUMMARY_FILE"
else
  echo "SUMMARY:"
  echo "$SUMMARY_CONTENT"
fi
