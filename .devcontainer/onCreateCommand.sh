#!/usr/bin/env bash

# Bash autocompletion
apt update && apt install -y bash-completion

echo '
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
' >> ~/.bashrc

# Install what 'golang.go' extension wants
go install github.com/ramya-rao-a/go-outline@latest
go install github.com/cweill/gotests/gotests@latest
go install github.com/fatih/gomodifytags@latest
go install github.com/josharian/impl@latest
go install github.com/haya14busa/goplay/cmd/goplay@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
go install golang.org/x/tools/gopls@latest
