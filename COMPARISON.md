# Original zsh vs New bash Worktree Manager Comparison

## Key Architectural Differences

### 1. Directory Structure

**Original (zsh):**
- Fixed location: `~/projects/`
- Centralised worktrees: `~/projects/worktrees/<project>/<branch>`
- Special handling for "core" project with legacy location

**New (bash):**
- Works from any location in the filesystem
- Sibling directory structure: `<parent>/.worktrees/<project>/<branch>`
- No special cases or legacy handling needed

### 2. Command Syntax

**Original (zsh):**
```bash
w <project> <worktree>              # Primary usage
w <project> <worktree> <command>    # Run command
w --list                            # List all worktrees
w --rm <project> <worktree>         # Remove worktree
```

**New (bash):**
```bash
wt <worktree>                        # Auto-detects current project
wt <worktree> <command>              # Run command
wt --list                            # List current project's worktrees
wt --list-all                        # List all sibling projects' worktrees
wt --rm <worktree>                   # Remove from current project
wt --project <project> <worktree>    # Cross-project operation
```

### 3. Project Detection

**Original:** Must always specify the project name explicitly

**New:** Automatically detects the current git repository, making it more intuitive when working within a project

### 4. Shell Compatibility

**Original:** 
- zsh-specific syntax (`$var/*(/N)`, `${var:t}`, etc.)
- zsh completion system

**New:** 
- Pure bash syntax
- Bash completion using `complete -F`

## Feature Comparison

| Feature | Original zsh | New bash |
|---------|-------------|----------|
| **Command name** | `w` | `wt` (avoids Unix `w` conflict) |
| **Shell** | zsh only | bash |
| **Location flexibility** | Fixed to `~/projects` | Any filesystem location |
| **Worktree storage** | Centralised | Sibling `.worktrees` directory |
| **Auto-detect project** | ❌ No | ✅ Yes |
| **Cross-project work** | Default behaviour | Via `--project` flag |
| **List current project** | N/A | `wt --list` |
| **List all projects** | `w --list` | `wt --list-all` |
| **Tab completion** | zsh completion | bash completion |
| **Legacy support** | Special "core" handling | None needed |
| **Branch naming** | `$USER/<worktree>` | `$USER/<worktree>` or just `<worktree>` |

## Migration Guide

If migrating from the original zsh version:

### Command Translation

| Old Command | New Command |
|-------------|------------|
| `w myapp feature-x` | `cd myapp && wt feature-x` |
| `w myapp feature-x git status` | `cd myapp && wt feature-x git status` |
| | OR `wt --project myapp feature-x git status` |
| `w --list` | `wt --list-all` |
| `w --rm myapp feature-x` | `cd myapp && wt --rm feature-x` |

### Directory Migration

To migrate existing worktrees to the new structure:

```bash
# Old structure: ~/projects/worktrees/myapp/feature-x
# New structure: /path/to/projects/.worktrees/myapp/feature-x

# Example migration:
cd /path/to/projects
mkdir -p .worktrees
mv ~/projects/worktrees/* .worktrees/
```

## Advantages of the New Version

1. **Portability**: Works with projects anywhere in the filesystem
2. **Simplicity**: Auto-detects current project, reducing typing
3. **Flexibility**: Sibling directory structure keeps worktrees close to projects
4. **Compatibility**: Bash is more universally available than zsh
5. **Cleaner**: No special cases or legacy handling needed

## Example Workflow Comparison

### Original zsh workflow:
```bash
cd ~/projects
w frontend header-fix
w backend api-update
w frontend header-fix npm test
w backend api-update go test
```

### New bash workflow:
```bash
cd /any/path/frontend
wt header-fix
cd ../backend
wt api-update
# Or from anywhere:
wt --project frontend header-fix npm test
wt --project backend api-update go test
```
