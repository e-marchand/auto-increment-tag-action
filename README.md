# Auto Increment Tag Action

This GitHub Action automatically creates and pushes release tags based on branch names with incremental versioning.

## Features

- **Automatic versioning**: Creates tags with incremental numbering (e.g., `main.1`, `main.2`, `v1.1`, `v1.2`)
- **Flexible tagging**: Uses custom tag prefix if provided, otherwise uses branch name as prefix
- **Duplicate prevention**: Checks if a tag already exists on the current commit before creating a new one
- **Customizable git identity**: Configure custom git user name and email for tag creation
- **Summary output**: Provides detailed summary of the tagging operation

## Usage

### Basic Usage

```yaml
- name: Create Release Tag
  uses: e-marchand/auto-increment-tag-action@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

### Advanced Usage

```yaml
- name: Create Release Tag
  uses: e-marchand/auto-increment-tag-action@v1
  with:
    branch: 'feature-branch'  # Optional: specify branch (defaults to current)
    tag_prefix: 'v1'          # Optional: custom tag prefix (defaults to branch name)
    git_user_name: 'Custom Bot'  # Optional: custom git user name
    git_user_email: 'bot@example.com'  # Optional: custom git user email
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `branch` | Branch to create tag for (leave empty for current branch) | No | Current branch |
| `tag_prefix` | Tag prefix to use instead of branch name (leave empty to use branch name) | No | Branch name |
| `git_user_name` | Git user name for commits | No | `github-actions[bot]` |
| `git_user_email` | Git user email for commits | No | `github-actions[bot]@users.noreply.github.com` |
| `github_token` | GitHub token with contents:write permission | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `tag` | The tag that was created or found |

## Examples

### Example 1: Simple tagging in workflow

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Create Release Tag
        id: tag
        uses: e-marchand/auto-increment-tag-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Use the tag
        run: echo "Created tag: ${{ steps.tag.outputs.tag }}"
```

### Example 2: Manual workflow dispatch

```yaml
name: Create Release Tag

on:
  workflow_dispatch:
    inputs:
      branch:
        description: 'Branch to create tag for'
        required: false
        default: ''

jobs:
  create-tag:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: ${{ inputs.branch || github.ref }}
      
      - uses: e-marchand/auto-increment-tag-action@v1
        with:
          branch: ${{ inputs.branch }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## How it works

1. **Branch Detection**: Determines the current branch or uses the specified branch
2. **Tag Prefix**: Uses the specified tag_prefix if provided, otherwise uses the branch name as prefix
3. **Existing Tag Check**: Checks if a tag already exists on the current commit
4. **Version Calculation**: Finds the highest existing tag number for the prefix and increments it
5. **Tag Creation**: Creates and pushes the new tag with an appropriate message

## Tag Format

- **With tag_prefix**: `{tag_prefix}.{number}` (e.g., `v1.1`, `v1.2`, `release.1`)
- **Without tag_prefix**: `{branch-name}.{number}` (e.g., `main.1`, `feature-branch.1`, `hotfix.2`)

## Permissions

The action requires the following permissions:

```yaml
permissions:
  contents: write  # Required to create and push tags
```

## License

This action is distributed under the MIT License.
