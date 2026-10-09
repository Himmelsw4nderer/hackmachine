# Hackmachine oh-my-zsh theme: cocoa terminal, pastel prompt.
#
#   ╭─λ nbax@nobara-pc ─ ~/proj/kde-rice ─  main ✓
#   ╰─❯                                   (base) 3s ✗ 1 16:34
#
# mint λ + prompt (coral after a failed command), lilac user, lavender host, sky path,
# lilac git branch with a mint ✓ or peach ● when dirty; right side: conda/venv in teal,
# how long the last command took in peach (if ≥ 2s), its exit code in coral, the time.

typeset -g HM_LINE='#4a3f38' HM_FAINT='#7d6d62' HM_MUTED='#bfae9f'
typeset -g HM_MINT='#a6e6bf' HM_SKY='#a3cdf5' HM_LAV='#c4b2f5' HM_LILAC='#e2b5f0'
typeset -g HM_PEACH='#f9c49a' HM_CORAL='#f7a59a' HM_TEAL='#94dcd6'

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$HM_LINE}─%f %F{$HM_LILAC} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{$HM_PEACH}●%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{$HM_MINT}✓%f"
VIRTUAL_ENV_DISABLE_PROMPT=1

zmodload zsh/datetime
autoload -Uz add-zsh-hook
_hm_preexec() { typeset -g _hm_start=$EPOCHREALTIME }
_hm_precmd() {
  typeset -g _hm_took=""
  if [[ -n $_hm_start ]]; then
    local d=$(( EPOCHREALTIME - _hm_start ))
    if (( d >= 2 )); then
      local t
      if (( d >= 60 )); then t="$(( ${d%.*} / 60 ))m$(( ${d%.*} % 60 ))s"
      else t="$(printf '%.1fs' $d)"; fi
      _hm_took="%F{$HM_PEACH}$t%f "
    fi
  fi
  unset _hm_start
  print ""   # one blank line between commands
}
add-zsh-hook preexec _hm_preexec
add-zsh-hook precmd _hm_precmd

_hm_env() {
  local env=${CONDA_DEFAULT_ENV:-${VIRTUAL_ENV:t}}
  [[ -n $env ]] && print -n "%F{$HM_TEAL}($env)%f "
}

PROMPT='%F{$HM_LINE}╭─%f%F{$HM_MINT}λ%f %F{$HM_LILAC}%n%f%F{$HM_FAINT}@%f%F{$HM_LAV}%m%f %F{$HM_LINE}─%f %F{$HM_SKY}%~%f$(git_prompt_info)
%F{$HM_LINE}╰─%f%(?.%F{$HM_MINT}.%F{$HM_CORAL})❯%f '
RPROMPT='$(_hm_env)$_hm_took%(?..%F{$HM_CORAL}✗ %?%f )%F{$HM_FAINT}%D{%H:%M}%f'
PROMPT2='%F{$HM_LINE}  %f%F{$HM_FAINT}…%f '
