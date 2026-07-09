#!/usr/bin/env bash
# Claude Code status line — mirrors Starship Catppuccin Mocha prompt
# Catppuccin Mocha palette (ANSI approximations)
TEAL='\033[38;2;148;226;213m'
BLUE='\033[38;2;137;180;250m'
PINK='\033[38;2;245;194;231m'
MAUVE='\033[38;2;203;166;247m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
BOLD='\033[1m'
RESET='\033[0m'

# make_bar <percent> <label> -> echoes a colored "label [▓▓▓░░░] NN%" segment.
# Color thresholds: green <60, yellow 60-79, red 80+. Bar is 10 cells, filled with
# ▓ and padded with ░ by replacing runs of spaces (per the Claude Code docs pattern).
make_bar() {
  local pct="$1" label="$2" color width filled empty fill pad bar
  if [ "$pct" -ge 80 ]; then color="$RED"
  elif [ "$pct" -ge 60 ]; then color="$YELLOW"
  else color="$GREEN"; fi
  width=10
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar=""
  [ "$filled" -gt 0 ] && printf -v fill "%${filled}s" && bar="${fill// /▓}"
  [ "$empty" -gt 0 ]  && printf -v pad  "%${empty}s"  && bar="${bar}${pad// /░}"
  printf '%s%s[%s] %s%%%s' "${label:+$label }" "$color" "$bar" "$pct" "$RESET"
}

input=$(cat)

# --- hostname ---
hostname_s=$(hostname -s)

# --- directory (truncate to 3 parts, relative to repo root if inside one) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home_cwd="${cwd/#$HOME/~}"
# Keep last 3 path components
dir=$(echo "$home_cwd" | awk -F'/' '{
  n=NF; start=(n>3)?n-2:1;
  sep="";
  for(i=start;i<=n;i++){printf "%s%s",sep,$i; sep="/"}
  print ""
}')

# --- git branch & status ---
branch=""
git_info=""
repo_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
if [ -n "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
  branch=$(git -C "$repo_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    modified=$(git -C "$repo_dir" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged=$(git -C "$repo_dir" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$repo_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    ahead=$(git -C "$repo_dir" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$repo_dir" --no-optional-locks rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    status_parts=""
    [ "$staged" -gt 0 ]    && status_parts="${status_parts}${GREEN}+${staged}${RESET} "
    [ "$modified" -gt 0 ]  && status_parts="${status_parts}${YELLOW}~${modified}${RESET} "
    [ "$untracked" -gt 0 ] && status_parts="${status_parts}\033[38;2;243;139;168m?${untracked}${RESET} "
    [ "$ahead" -gt 0 ]     && status_parts="${status_parts}${MAUVE}⇡${ahead}${RESET} "
    [ "$behind" -gt 0 ]    && status_parts="${status_parts}${MAUVE}⇣${behind}${RESET} "
    git_info="${BOLD}${PINK} ${branch}${RESET} ${status_parts}"
  fi
fi

# --- model ---
model=$(echo "$input" | jq -r '.model.display_name // empty')

# --- context used percentage (from .context_window.used_percentage) ---
used_int=$(echo "$input" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)
ctx_str=""
[ -n "$used_int" ] && ctx_str=$(make_bar "$used_int" "ctx")

# --- rate-limit usage (Claude.ai Pro/Max only; absent otherwise) ---
# .rate_limits.five_hour / .seven_day each carry used_percentage (0-100) and
# resets_at (Unix epoch seconds). Show the 5h window's reset time in local TZ.
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
rl_str=""
if [ -n "$five_h" ]; then
  rl_str=$(make_bar "$five_h" "5h")
  if [ -n "$five_h_reset" ]; then
    # date -r <epoch> works on macOS/BSD; fall back to GNU date -d @<epoch>.
    reset_fmt=$(date -r "$five_h_reset" "+%-I:%M %p %Z" 2>/dev/null \
      || date -d "@$five_h_reset" "+%-I:%M %p %Z" 2>/dev/null)
    [ -n "$reset_fmt" ] && rl_str="${rl_str} ${MAUVE}↻${RESET} ${reset_fmt}"
  fi
fi
[ -n "$week" ]   && rl_str="${rl_str:+$rl_str  ${MAUVE}│${RESET}  }$(make_bar "$week" "7d")"

# --- assemble: line 1 = host/dir/git/model, line 2 = context + rate limits ---
line1="${BOLD}${TEAL}${hostname_s}${RESET} ${BOLD}${BLUE}${dir}${RESET}"
[ -n "$git_info" ] && line1="${line1} ${git_info}"
[ -n "$model" ]    && line1="${line1} ${MAUVE}${model}${RESET}"

line2=""
[ -n "$ctx_str" ] && line2="$ctx_str"
[ -n "$rl_str" ]  && line2="${line2:+$line2  ${MAUVE}│${RESET}  }$rl_str"

printf '%b\n' "$line1"
[ -n "$line2" ] && printf '%b\n' "$line2"
exit 0
