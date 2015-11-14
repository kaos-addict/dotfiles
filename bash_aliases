### Taken back from bashrc kaos defaults
alias grep='grep --color=tty -d skip'		# Make coloured grep
alias cp="cp -i"		# confirm before overwriting something
alias df='df -h'		# human-readable sizes
alias free='free -m'		# show sizes in MB
alias np='nano PKGBUILD'		# edit PKGBUILD file
alias ns='nano SPLITBUILD'		# edit SPLITBUILD file
alias dvdburn='growisofs -Z /dev/sr0 -R -J'		# Burn cd/dvd
###

# Directory listing and better ls commands
alias ldir="ls -l | egrep '^d'"
alias ll='ls -l --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'
alias la='ls -la --group-directories-first --time-style=+"%d.%m.%Y %H:%M" --color=auto -F'

# Human-readable sizes
alias df='df -h'

# Show sizes in MB
alias free='free -m'

# Encrypt file with ssl
alias encssl="openssl aes-256-cbc -e -a -salt -in $@"

# Decrypt file with ssl
alias decssl="openssl aes-256-cbc -d -a -salt -in $@"

# List dir with details, sorted by time, colored, with ISO dates, ...
alias ls='ls -AlFhrt --time-style=long-iso --color=auto'

# List all process
alias psall='/usr/bin/ps aux'

# Find in all process
alias pg='/usr/bin/ps aux | grep'
# Forget sudo? Re-run last command as root
alias redo='\sudo !!'

# TODO: Get aliases
#alias alias-get='\wget -t 3 -q -O - "$@" https://'

# Cp like with progress
alias cpr="rsync --partial --progress --append"

# Rm like with progress
alias rmv="rsync --partial --progress --append --remove-sent-files"

# Directory listing
alias ldir="ls -l | egrep '^d'"

# Make coloured grep
#alias grep='grep -i --color'

# Get off comments
alias cgrep="grep -E -v '^(#|$|;)'"

# Show me my ssh public keys
alias ssh-showkeys="tail +1 ~/.ssh/*.pub"

# Display aliases file
alias shalias='cgrep ~/.bash_aliases && alias'

# Display functions file
alias shfunct='cgrep ~/.bash_functions'

# List top ten largest files/directories in current directory
alias ducks='du -cks *|sort -rn|head -11'

##TODO: what's best of these two:
# Clean comments and empty lines:
alias cleancom="sed -i 's/#.*$//;/^$/d'"

# Get off comments
alias cgrep="grep -E -v '^(#|$|;)'"
