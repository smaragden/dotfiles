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
  
  mkdir -p $PYENV_DIR/virtualenvs/
  # Install virtualenv for python-2/3
  ( pyenv local $latest_27;
    python -m virtualenv $PYENV_DIR/virtualenvs/nvim_python2;
    $PYENV_DIR/virtualenvs/nvim_python2/bin/pip install pynvim jedi;
  )
  (
    pyenv local $latest_37;
    python -m venv $PYENV_DIR/virtualenvs/nvim_python3;
    $PYENV_DIR/virtualenvs/nvim_python3/bin/pip install pynvim jedi;
  )


)

#############################################################################################################
# Install neovim appimage
#############################################################################################################

# Install latest neovim appimage
NEOVIM_DIR=$DOT_DIR/nvim
mkdir -p $NEOVIM_DIR/bin
ln -sf --no-dereference $NEOVIM_DIR ~/.config/nvim
curl -L -o $NEOVIM_DIR/bin/nvim.appimage https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
chmod u+x $NEOVIM_DIR/bin/nvim.appimage
ln -sf $NEOVIM_DIR/bin/nvim.appimage $DOT_DIR/bin/nvim

# Setup VimPlug
curl -fLo $NEOVIM_DIR/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Create Configuration
cat > $NEOVIM_DIR/init.vim <<EOF
let g:python_host_prog = '$PYENV_DIR/virtualenvs/nvim_python2/bin/python'
let g:python3_host_prog = '$PYENV_DIR/virtualenvs/nvim_python3/bin/python'

set nocompatible              " required
filetype off                  " required

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('$NEOVIM_DIR/plugged')
$(cat $DOT_DIR/neovim_plugins.txt)
call plug#end()
EOF

# Update all plugins
$DOT_DIR/bin/nvim +'PlugClean --sync' +'PlugInstall --sync' +'PlugUpdate --sync' +qa

# Add the config for nvim
cat >> $NEOVIM_DIR/init.vim <<EOF
filetype plugin indent on    " required

:set number relativenumber

:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

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

let g:deoplete#enable_at_startup = 1

au BufNewFile,BufRead *.py
\ set tabstop=4 |
\ set softtabstop=4 |
\ set shiftwidth=4 |
\ set textwidth=79 |
\ set expandtab |
\ set autoindent |
\ set fileformat=unix

" Display tabs at the beginning of a line in Python mode as bad.
au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/

" Make trailing whitespace be flagged as bad.
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

" Use the below highlight group when displaying bad whitespace is desired.
highlight BadWhitespace ctermbg=red guibg=red

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Terraform Specific Configs
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax on
colorscheme onedark
let g:airline_theme='onedark'
EOF

# Copy theme for airline
mkdir -p ${NEOVIM_DIR}/autoload/airline/themes/
ln -sf ${NEOVIM_DIR}/plugged/onedark.vim/autoload/airline/themes/onedark.vim ${NEOVIM_DIR}/autoload/airline/themes/onedark.vim
