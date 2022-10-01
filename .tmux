#!/bin/zsh

autoload -Uz tmux_create_or_attach_session
sess_name='cmp_markdown_link'

tmux_create_or_attach_session $sess_name 'nvim'

if [ $? -eq 1 ]; then
  tmux new-window -t $sess_name -n 'README'
  tmux new-window -t $sess_name -n 'docs'
  tmux send-keys -t ${sess_name}:README 'v README.md' Enter
  tmux send-keys -t ${sess_name}:docs 'v doc/cmp-markdown-link.txt' Enter

  tmux send-keys -t ${sess_name}:nvim 'v' Enter

  tmux attach -t ${sess_name}:nvim
fi
