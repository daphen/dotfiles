# Direnv - automatically load environment variables when entering directories
if command -v direnv >/dev/null 2>&1
    direnv hook fish | source
end
