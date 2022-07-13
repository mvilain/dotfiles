# revised .oh-my-zsh/themes/candy-mv.zsh-theme
# [hh:mm:ss] user@host [] (virtualenv) [master] X
local ret_status="%(?:%{$fg[white]%}──►:%{$fg[red]%}━━►)"
PROMPT=$'╭─%{$fg[green]%}%D{[%T]} %{$fg[cyan]%}%n@%m %{$reset_color%}%{$fg[white]%}[%~]%{$reset_color%} $(virtualenv_prompt_info) $(git_prompt_info)\
%{$fg[white]%}╰${ret_status} %#%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=")"