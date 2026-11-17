# fish config (rice). Colors live in conf.d/rice-colors.fish, regenerated from
# the wallpaper by matugen; don't edit that file by hand.

set -g fish_greeting ""          # no "Welcome to fish" message

if status is-interactive
    # quality-of-life abbreviations (expand when you press space)
    abbr -a ll 'ls -lah'
    abbr -a g git
    abbr -a ..  'cd ..'
    abbr -a ... 'cd ../..'
end
