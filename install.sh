#!/bin/bash
set -e


#############################################################################################################
# Setup Folder Structures
#############################################################################################################

DOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Create a bin folder if it doesn't exists
mkdir -p $DOT_DIR/bin/
DOTRC=$DOT_DIR/.dotfilesrc

cat > $DOTRC <<EOF
PATH=$DOT_DIR/bin:\$PATH
export PATH

EOF

#############################################################################################################
# Install PyEnv
###############################################i##############################################################
PYENV_DIR=$DOT_DIR/pyenv
mkdir -p $PYENV_DIR
if [ -d "$PYENV_DIR/.pyenv" ]; then
	(cd $PYENV_DIR/.pyenv && git pull)
else
	git clone https://github.com/pyenv/pyenv.git $PYENV_DIR/.pyenv
fi
ln -sf $PYENV_DIR/.pyenv/bin/pyenv $DOT_DIR/bin/pyenv

cat >> $DOTRC <<EOF
# PyEnv Setup
export PYENV_ROOT="$PYENV_DIR/.pyenv"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "\$(pyenv init -)"
fi

EOF

# Install Python versions
(
  . $DOTRC
  latest_27=$(pyenv install --list | egrep "^\s+2\.7" | grep -v - | grep -v a | tail -1)
  latest_36=$(pyenv install --list | egrep "^\s+3\.6" | grep -v - | grep -v a | tail -1)
  latest_37=$(pyenv install --list | egrep "^\s+3\.7" | grep -v - | grep -v a | tail -1)
  latest_38=$(pyenv install --list | egrep "^\s+3\.8" | grep -v - | grep -v a | tail -1)

  pyenv install --skip-existing $latest_27
  pyenv install --skip-existing $latest_36
  pyenv install --skip-existing $latest_37
  pyenv install --skip-existing $latest_38

  ( pyenv local $latest_27; pip install --user neovim)
  ( pyenv local $latest_36; pip install --user neovim)
  ( pyenv local $latest_37; pip install --user neovim)
  ( pyenv local $latest_38; pip install --user neovim)

)

#############################################################################################################
# Install neovim appimage
#############################################################################################################

# Install latest neovim appimage
NEOVIM_DIR=$DOT_DIR/nvim
mkdir -p $NEOVIM_DIR/{bin,config}
ln -sf $NEOVIM_DIR/config ~/.config/nvim
curl -L -o $NEOVIM_DIR/bin/nvim.appimage https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
chmod u+x $NEOVIM_DIR/bin/nvim.appimage
ln -sf $NEOVIM_DIR/bin/nvim.appimage $DOT_DIR/bin/nvim

# Setup VimPlug
curl -fLo $NEOVIM_DIR/config/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Create Configuration
cat > $NEOVIM_DIR/config/init.vim <<EOF
set nocompatible              " required
filetype off                  " required

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('$NEOVIM_DIR/config/plugged')
$(cat $DOT_DIR/neovim_plugins.txt)
call plug#end()

filetype plugin indent on    " required

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Split Window
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set splitbelow
set splitright

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Code Folding
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable folding
set foldmethod=indent
set foldlevel=99

" Enable folding with the spacebar
nnoremap <space> za

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Python Specific Configs
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set encoding=utf-8

au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

au BufNewFile,BufRead *.py
    \ set tabstop=4
    \ set softtabstop=4
    \ set shiftwidth=4
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax on
colorscheme onedark

EOF

$DOT_DIR/bin/nvim +'PlugClean --sync' +'PlugInstall --sync' +'PlugUpdate --sync' +qa



