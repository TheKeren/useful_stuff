syntax on
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab 
execute pathogen#infect()
call pathogen#helptags()
autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p
