if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# Enable bash completion
[ -f /etc/bash_completion ]; then
	    . /etc/bash_completion
fi
[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

# Allow root windows:
xhost +local:root > /dev/null 2>&1

# Complete some useful commands:
complete -cf sudo
complete -cf man
complete -cf kdesu

# Some shell options:
shopt -s cdspell
shopt -s checkwinsize
shopt -s dotglob
shopt -s expand_aliases
shopt -s extglob
shopt -s hostcomplete
shopt -s nocaseglob

# Few environment variables (edit to your preferences):
shopt -s histappend
shopt -s cmdhist
export HISTSIZE=10000		# Nb of lines in history
export HISTFILESIZE=${HISTSIZE}	# Limit also history filesize
export HISTCONTROL=ignoreboth	# 
export EDITOR=nano		# Some scripts and applications use this as default terminal text editor
export VISUAL=nano		# "
export XEDITOR=kate		# Added a X version

set_prompt () {
    Last_Command=$? # Must come first!
    Blue='\[\e[01;34m\]'
    White='\[\e[01;37m\]'
    Red='\[\e[01;31m\]'
    Green='\[\e[01;32m\]'
    Reset='\[\e[00m\]'
    FancyX='\342\234\227'
    Checkmark='\342\234\223'

    # Add a bright white exit status for the last command
    PS1="$White\$? "
    # If it was successful, print a green check mark. Otherwise, print
    # a red X.
    if [[ $Last_Command == 0 ]]; then
        PS1+="$Green$Checkmark "
    else
        PS1+="$Red$FancyX "
    fi
    # If root, just print the host in red. Otherwise, print the current user
    # and host in green.
    if [[ $EUID == 0 ]]; then
        PS1+="$Red\\h "
    else
        PS1+="$Green\\u@\\h "
    fi
    # Print the working directory and prompt marker in blue, and reset
    # the text color to the default.
    PS1+="$Blue\\w \\\$$Reset "
}
PROMPT_COMMAND='set_prompt'

# Source alias file if present
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases   
# Source functionns file if present
[[ -f ~/.bash_functions ]] && . ~/.bash_functions
