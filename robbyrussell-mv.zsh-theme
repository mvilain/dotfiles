# revised .oh-my-zsh/themes/robbyrussell-mv.zsh-theme (simplified from original)
# [hh:mm:ss] user@host ~ virtualenv git:(branch*) rc$
local ret_status="%(?:%F{white}%#%f:%F{red}%#%f)"
PROMPT='[%*] %F{green}%n@%m %F{blue}%2~%f ${virtualenv_prompt_info}$(git_prompt_info)\
${ret_status} '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{cyan}git:("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%F{cyan}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
