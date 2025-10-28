#!/usr/bin/env bash
# Multi-project worktree manager - Bash version
# 
# ASSUMPTIONS & SETUP:
# - Works from any git repository in the filesystem
# - Worktrees will be created in: <project-parent-dir>/.worktrees/<project-name>/<branch>
# - New branches will be named: <your-username>/<feature-name>
#
# DIRECTORY STRUCTURE EXAMPLE:
# /path/to/projects/
# ├── my-app/              (main git repo)
# ├── another-project/     (main git repo)
# └── .worktrees/
#     ├── my-app/
#     │   ├── feature-x/   (worktree)
#     │   └── bugfix-y/    (worktree)
#     └── another-project/
#         └── new-feature/ (worktree)
#
# INSTALLATION:
# 1. Source this file in your .bashrc:
#    source /path/to/worktree-manager.bash
#
# 2. Add bash completion (see bottom of file for setup instructions)
#
# 3. Restart your terminal or run: source ~/.bashrc
#
# USAGE:
#   wt <worktree>                        # cd to worktree (creates if needed) - uses current repo
#   wt <worktree> <command>              # run command in worktree
#   wt --list                            # list all worktrees for current repo
#   wt --list-all                        # list all worktrees for all sibling repos
#   wt --rm <worktree>                   # remove worktree
#   wt --project <project> <worktree>    # operate on a specific project
#
# EXAMPLES:
#   wt feature-x                         # cd to feature-x worktree
#   wt feature-x code .                  # open VS Code in worktree
#   wt feature-x git status              # git status in worktree
#   wt --project myapp feature-x         # work with myapp's feature-x worktree

# Find git root directory
_find_git_root() {
    local dir="$1"
    [[ -z "$dir" ]] && dir="$PWD"
    
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    return 1
}

# Multi-project worktree manager
wt() {
    # Handle special flags first
    if [[ "$1" == "--list" ]]; then
        local git_root
        git_root=$(_find_git_root)
        if [[ $? -ne 0 ]]; then
            echo "Error: Not in a git repository"
            return 1
        fi
        
        local project_name
        project_name=$(basename "$git_root")
        local parent_dir
        parent_dir=$(dirname "$git_root")
        local worktrees_dir="$parent_dir/.worktrees/$project_name"
        
        echo "=== Worktrees for $project_name ==="
        if [[ -d "$worktrees_dir" ]]; then
            for wt in "$worktrees_dir"/*; do
                if [[ -d "$wt" ]]; then
                    echo "  • $(basename "$wt")"
                fi
            done
        else
            echo "  No worktrees found"
        fi
        return 0
    elif [[ "$1" == "--list-all" ]]; then
        local git_root
        git_root=$(_find_git_root)
        if [[ $? -ne 0 ]]; then
            echo "Error: Not in a git repository"
            return 1
        fi
        
        local parent_dir
        parent_dir=$(dirname "$git_root")
        local worktrees_base="$parent_dir/.worktrees"
        
        if [[ ! -d "$worktrees_base" ]]; then
            echo "No worktrees directory found"
            return 0
        fi
        
        echo "=== All Worktrees ==="
        for project in "$worktrees_base"/*; do
            if [[ -d "$project" ]]; then
                local project_name
                project_name=$(basename "$project")
                echo ""
                echo "[$project_name]"
                for wt in "$project"/*; do
                    if [[ -d "$wt" ]]; then
                        echo "  • $(basename "$wt")"
                    fi
                done
            fi
        done
        return 0
    elif [[ "$1" == "--rm" ]]; then
        shift
        local worktree="$1"
        
        if [[ -z "$worktree" ]]; then
            echo "Usage: wt --rm <worktree>"
            return 1
        fi
        
        local git_root
        git_root=$(_find_git_root)
        if [[ $? -ne 0 ]]; then
            echo "Error: Not in a git repository"
            return 1
        fi
        
        local project_name
        project_name=$(basename "$git_root")
        local parent_dir
        parent_dir=$(dirname "$git_root")
        local wt_path="$parent_dir/.worktrees/$project_name/$worktree"
        
        if [[ ! -d "$wt_path" ]]; then
            echo "Worktree not found: $wt_path"
            return 1
        fi
        
        (cd "$git_root" && git worktree remove "$wt_path")
        return $?
    elif [[ "$1" == "--project" ]]; then
        shift
        local project="$1"
        local worktree="$2"
        shift 2
        local command=("$@")
        
        if [[ -z "$project" || -z "$worktree" ]]; then
            echo "Usage: wt --project <project> <worktree> [command...]"
            return 1
        fi
        
        # Find the project directory
        local git_root
        git_root=$(_find_git_root)
        if [[ $? -ne 0 ]]; then
            echo "Error: Not in a git repository"
            return 1
        fi
        
        local parent_dir
        parent_dir=$(dirname "$git_root")
        local project_dir="$parent_dir/$project"
        
        if [[ ! -d "$project_dir" ]] || [[ ! -d "$project_dir/.git" ]]; then
            echo "Project not found: $project_dir"
            return 1
        fi
        
        # Handle worktree operations for the specified project
        local worktrees_dir="$parent_dir/.worktrees/$project"
        local wt_path="$worktrees_dir/$worktree"
        
        # Create worktree if it doesn't exist
        if [[ ! -d "$wt_path" ]]; then
            echo "Creating new worktree: $worktree for project $project"
            
            # Ensure worktrees directory exists
            mkdir -p "$worktrees_dir"
            
            # Determine branch name (use current username prefix if available)
            local branch_name
            if [[ -n "$USER" ]]; then
                branch_name="$USER/$worktree"
            else
                branch_name="$worktree"
            fi
            
            # Create the worktree
            (cd "$project_dir" && git worktree add "$wt_path" -b "$branch_name") || {
                echo "Failed to create worktree"
                return 1
            }
        fi
        
        # Execute command or cd to worktree
        if [[ ${#command[@]} -eq 0 ]]; then
            cd "$wt_path"
        else
            local old_pwd="$PWD"
            cd "$wt_path"
            "${command[@]}"
            local exit_code=$?
            cd "$old_pwd"
            return $exit_code
        fi
        return 0
    fi
    
    # Normal usage: w <worktree> [command...]
    local worktree="$1"
    shift
    local command=("$@")
    
    if [[ -z "$worktree" ]]; then
        cat <<EOF
Usage: 
  wt <worktree> [command...]           # Work with worktree in current repo
  wt --list                             # List worktrees for current repo
  wt --list-all                         # List all worktrees for sibling repos
  wt --rm <worktree>                    # Remove worktree
  wt --project <project> <worktree>     # Work with specific project's worktree
EOF
        return 1
    fi
    
    # Find git root of current directory
    local git_root
    git_root=$(_find_git_root)
    if [[ $? -ne 0 ]]; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    local project_name
    project_name=$(basename "$git_root")
    local parent_dir
    parent_dir=$(dirname "$git_root")
    local worktrees_dir="$parent_dir/.worktrees/$project_name"
    local wt_path="$worktrees_dir/$worktree"
    
    # If worktree doesn't exist, create it
    if [[ ! -d "$wt_path" ]]; then
        echo "Creating new worktree: $worktree"
        
        # Ensure worktrees directory exists
        mkdir -p "$worktrees_dir"
        
        # Determine branch name (use current username prefix if available)
        local branch_name
        if [[ -n "$USER" ]]; then
            branch_name="$USER/$worktree"
        else
            branch_name="$worktree"
        fi
        
        # Create the worktree
        (cd "$git_root" && git worktree add "$wt_path" -b "$branch_name") || {
            echo "Failed to create worktree"
            return 1
        }
    fi
    
    # Execute based on number of arguments
    if [[ ${#command[@]} -eq 0 ]]; then
        # No command specified - just cd to the worktree
        cd "$wt_path"
    else
        # Command specified - run it in the worktree without cd'ing
        local old_pwd="$PWD"
        cd "$wt_path"
        "${command[@]}"
        local exit_code=$?
        cd "$old_pwd"
        return $exit_code
    fi
}

# Bash completion for the wt function
_wt_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # First argument - could be a flag or worktree name
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        opts="--list --list-all --rm --project"
        
        # Also add existing worktrees for current project
        local git_root
        git_root=$(_find_git_root 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            local project_name
            project_name=$(basename "$git_root")
            local parent_dir
            parent_dir=$(dirname "$git_root")
            local worktrees_dir="$parent_dir/.worktrees/$project_name"
            
            if [[ -d "$worktrees_dir" ]]; then
                for wt in "$worktrees_dir"/*; do
                    if [[ -d "$wt" ]]; then
                        opts="$opts $(basename "$wt")"
                    fi
                done
            fi
        fi
        
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
    
    # Handle flag-specific completions
    case "${COMP_WORDS[1]}" in
        --rm)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                # Complete with existing worktrees
                local git_root
                git_root=$(_find_git_root 2>/dev/null)
                if [[ $? -eq 0 ]]; then
                    local project_name
                    project_name=$(basename "$git_root")
                    local parent_dir
                    parent_dir=$(dirname "$git_root")
                    local worktrees_dir="$parent_dir/.worktrees/$project_name"
                    
                    if [[ -d "$worktrees_dir" ]]; then
                        local worktrees=""
                        for wt in "$worktrees_dir"/*; do
                            if [[ -d "$wt" ]]; then
                                worktrees="$worktrees $(basename "$wt")"
                            fi
                        done
                        COMPREPLY=( $(compgen -W "${worktrees}" -- ${cur}) )
                    fi
                fi
            fi
            ;;
        --project)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                # Complete with sibling projects
                local git_root
                git_root=$(_find_git_root 2>/dev/null)
                if [[ $? -eq 0 ]]; then
                    local parent_dir
                    parent_dir=$(dirname "$git_root")
                    local projects=""
                    
                    for proj in "$parent_dir"/*; do
                        if [[ -d "$proj/.git" ]]; then
                            projects="$projects $(basename "$proj")"
                        fi
                    done
                    COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
                fi
            elif [[ ${COMP_CWORD} -eq 3 ]]; then
                # Complete with worktrees for the specified project
                local project="${COMP_WORDS[2]}"
                local git_root
                git_root=$(_find_git_root 2>/dev/null)
                if [[ $? -eq 0 ]]; then
                    local parent_dir
                    parent_dir=$(dirname "$git_root")
                    local worktrees_dir="$parent_dir/.worktrees/$project"
                    
                    if [[ -d "$worktrees_dir" ]]; then
                        local worktrees=""
                        for wt in "$worktrees_dir"/*; do
                            if [[ -d "$wt" ]]; then
                                worktrees="$worktrees $(basename "$wt")"
                            fi
                        done
                        COMPREPLY=( $(compgen -W "${worktrees}" -- ${cur}) )
                    fi
                fi
            fi
            ;;
        *)
            # For worktree names followed by commands, use default command completion
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=( $(compgen -c -- ${cur}) )
            fi
            ;;
    esac
}

# Register bash completion
complete -F _wt_completion wt

# Installation help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat <<EOF
Worktree Manager - Bash Version

To install, add this line to your ~/.bashrc:
    source $(realpath "${BASH_SOURCE[0]}")

Then restart your terminal or run:
    source ~/.bashrc

The 'wt' command will then be available with tab completion.

Usage examples:
    wt feature-x                  # Create/switch to feature-x worktree
    wt feature-x git status       # Run git status in worktree
    wt --list                     # List current project's worktrees
    wt --list-all                 # List all sibling projects' worktrees
    wt --rm feature-x             # Remove feature-x worktree
    wt --project myapp feature-y  # Work with myapp's feature-y worktree
EOF
fi
