# revised .oh-my-zsh/themes/candy-mv.zsh-theme (simplified from original)
# https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/
# [MM/DD/YY hh:mm:ss] user@host [] (virtualenv) [master] X
local ret_status="%(?:%F{white}──►:%F{red}━━►)"
PROMPT=$'╭─%F{green}[%W %T] %(!.%F{red}%n.%F{cyan]}%n)@%m %f%F{white}[%2~]%f ${virtualenv_prompt_info} $(git_prompt_info)\
%F{white}╰${ret_status} %(!.%F{red}#.%F{white}%%)%f '

ZSH_THEME_GIT_PROMPT_PREFIX="%F{green]}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}✗%F{green}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=")"

