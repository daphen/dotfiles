function clean_nvim_swap --description 'Clean Neovim swap files'
  set -l swap_dir ~/.local/share/nvim/swap

  if test -d $swap_dir
    set -l count (count $swap_dir/*)
    if test $count -gt 0
      rm -f $swap_dir/*
      echo "Cleaned $count swap files from Neovim swap directory"
    end
  else
    echo "Neovim swap directory not found at $swap_dir"
  end
end
