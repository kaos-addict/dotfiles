# ~/.profile: Executed by Bourne-compatible login SHells.

. /etc/locale.conf

# Path to personal scripts and executables (~/.local/bin).
if [ -d "$HOME/.local/bin" ] ; then
	PATH=$HOME/.local/bin:$PATH
	export PATH
fi

# colored prompt
PS1='\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;33m\]\w\[\e[0m\]\$ '

EDITOR='nano'
PAGER='less -EM'

export PS1 EDITOR PAGER

umask 022

# Source bashrc file if present for compatibility
if [ -f .bashrc ]; then source .bashrc;fi
