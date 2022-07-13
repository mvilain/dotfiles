# revised .oh-my-zsh/themes/robbyrussell-mv.zsh-theme
# status--> [hh:mm:ss] user@host ~ git:branch x
local ret_status="%(?:%{$fg[white]%}──► :%{$fg[red]%}━━► )"
PROMPT='╭ [%*] %{$fg[green]%}%n@%m %{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)
╰${ret_status} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[blue]%}git:(%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
