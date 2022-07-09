# revised .oh-my-zsh/themes/candy-mv.zsh-theme
#
PROMPT=$'╭─%{$fg[green]%}%D{[%X]} %{$fg[cyan]%}%n@%m %{$reset_color%}%{$fg[white]%}[%~]%{$reset_color%} $(virtualenv_prompt_info) $(git_prompt_info)\
%{$fg[white]%}╰──► %#%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=")"