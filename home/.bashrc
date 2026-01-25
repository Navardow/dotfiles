# Git prompt support
source /usr/share/git/completion/git-prompt.sh
unset GIT_PS1_SHOWDIRTYSTATE
unset GIT_PS1_SHOWUNTRACKEDFILES
export GIT_PS1_SHOWSTASHSTATE=1


#
# ~/.bashrc
#

#Colors
# Reset
CLR_RESET="\033[0m"
# Foreground colors
CLR_GRAY="\033[90m"
CLR_RED="\033[31m"
CLR_GREEN="\033[32m"
CLR_YELLOW="\033[33m"
CLR_PURPLE="\033[38;2;189;147;249m"
CLR_MAGENTA="\033[35m"
CLR_CYAN="\033[36m"
CLR_WHITE="\033[97m"


#Icons
FOLDER_ICON="󰉋"
GIT_ICON=""
ARROW_ICON="╰─❯"
PLUS_ICON="+"   
X_ICON="✗"      
CHECK_ICON="✓" 
TOP_ARROW="╭─"



#functions
git_state() {
    git rev-parse --is-inside-work-tree &>/dev/null || return

    # staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
        printf "${CLR_YELLOW}${PLUS_ICON}${CLR_RESET}"
        return
    fi

    # unstaged or untracked changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        printf "${CLR_RED}${X_ICON}${CLR_RESET}"
        return
    fi

    # clean repo — only show ✓ if NO stash exists
    if ! git stash list | grep -q .; then
        printf "${CLR_GREEN}${CHECK_ICON}${CLR_RESET}"
    fi
}


# Prompt
PS1=""
PS1+="${CLR_WHITE}${TOP_ARROW}"
PS1+="${CLR_GRAY} \u "
PS1+="${CLR_PURPLE}\w "
PS1+="${CLR_GREEN}\$(__git_ps1 \"(${GIT_ICON}:%s)\")\$(git_state)"
PS1+="\n${CLR_WHITE}${ARROW_ICON}${CLR_RESET}"


## aliases
alias update='sudo pacman -Syu --color=auto'
alias grep='grep --color=auto'
alias si='sudo pacman -S --color=auto'
alias bashrc='nvim ~/.bashrc'
alias dot='nvim ~/dotfiles'

#ls aliases
alias ls='ls --color=auto'
alias ll='ls -l --color=auto' #list contents in a list.
alias la='ls -Al --color=auto' #list all (including .files, except (.) and (..)" also in a list.
alias lt='ls -ltr --color=auto' #list contents sort by time(default newest first) of modification and reverse(so oldest first newest last).

#change dirs
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'

#copy and move with prompting for overrides
alias cp='cp -vi'
alias mv='mv -vi'

#fd alias
alias fdh='fd --hidden --color=auto' #include hidden files
alias fdd='fd -t d --color=auto' #only search for dir
alias fdf='fd -t f --color=auto' #only search for files

#directory aliases

alias mk='mkdir -pv'
alias del='rm -riv'

#gnu stow aliases
alias sustow='stow -Dnv'
alias unstow='stow -D'

#power control
alias gts='systemctl sleep'


export PATH="/usr/local/bin:$PATH"




