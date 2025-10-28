# Worktree Manager - Bash Version

This is a bash adaptation of the zsh [worktree manager](https://gist.github.com/rorydbain/e20e6ab0c7cc027fc1599bd2e430117d) with improved flexibility and directory structure. The command is named `wt` (short for "worktree") to avoid conflicts with the Unix `w` command.

## Key Improvements

1. **Works anywhere in the filesystem** - No longer restricted to `~/projects`
2. **Sibling `.worktrees` directory** - Each project's worktrees are stored in a `.worktrees` subdirectory at the same level as the project
3. **Bash compatibility** - Fully rewritten for bash with proper bash completion
4. **Project-aware** - Automatically detects the current git repository

## Directory Structure

Instead of the original centralised structure:
```
~/projects/
├── my-app/              
├── another-project/     
└── worktrees/           # Centralised worktrees
    ├── my-app/
    └── another-project/
```

This version uses a sibling structure that works anywhere:
```
/any/path/to/projects/
├── my-app/              (main git repo)
├── another-project/     (main git repo)
└── .worktrees/          # Sibling directory for all worktrees
    ├── my-app/
    │   ├── feature-x/   (worktree)
    │   └── bugfix-y/    (worktree)
    └── another-project/
        └── new-feature/ (worktree)
```

## Installation

1. Save the script somewhere accessible:
   ```bash
   mkdir -p ~/bin
   cp worktree-manager.bash ~/bin/
   chmod +x ~/bin/worktree-manager.bash
   ```

2. Add to your `~/.bashrc`:
   ```bash
   source ~/bin/worktree-manager.bash
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc
   ```

## Usage

### Basic Commands

```bash
# From within any git repository:
wt feature-x                      # Create/switch to feature-x worktree
wt feature-x git status           # Run git status in feature-x worktree
wt feature-x code .               # Open VS Code in worktree

# List worktrees
wt --list                         # List current repo's worktrees
wt --list-all                     # List all sibling repos' worktrees

# Remove worktree
wt --rm feature-x                 # Remove feature-x worktree

# Work with other projects (from anywhere)
wt --project myapp feature-y      # Work with myapp's feature-y worktree
```

### Examples

1. **Create a new worktree and switch to it:**
   ```bash
   cd /path/to/my-project
   wt new-feature
   # Creates: /path/to/.worktrees/my-project/new-feature
   # Branch: <username>/new-feature
   ```

2. **Run commands in a worktree without changing directory:**
   ```bash
   wt new-feature npm test
   wt new-feature git commit -m "Add feature"
   ```

3. **Work with multiple projects:**
   ```bash
   # From any project directory
   wt --project frontend header-update
   wt --project backend api-refactor
   ```

## Differences from Original

| Feature | Original (zsh) | This Version (bash) |
|---------|---------------|-------------------|
| Shell | zsh only | bash |
| Location | Fixed to `~/projects` | Works anywhere |
| Worktree storage | `~/projects/worktrees/<project>` | `<parent>/.worktrees/<project>` |
| Project switching | `w <project> <worktree>` | `wt --project <project> <worktree>` |
| Current repo | Must specify project | Auto-detects from PWD |
| List all worktrees | `w --list` | `wt --list-all` |
| List current repo | N/A | `wt --list` |

## Branch Naming Convention

New worktrees automatically create branches with the format: `<username>/<worktree-name>`

For example, if your username is `john` and you create a worktree called `feature-x`, the branch will be `john/feature-x`.

## Tips

- The `.worktrees` directory is created at the same level as your git repositories
- You can work with any project's worktrees using `--project` flag
- Tab completion works for worktree names and project names
- The script automatically detects if you're in a git repository

## Troubleshooting

**"Not in a git repository" error:**
- Make sure you're inside a git repository or use `--project` flag

**Tab completion not working:**
- Ensure you've sourced the script in your `.bashrc`
- Restart your terminal completely

**Worktree creation fails:**
- Check you have write permissions in the parent directory
- Ensure the branch name doesn't already exist
