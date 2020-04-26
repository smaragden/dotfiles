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

cat >> $DOTRC <<EOF


# PyEnv Setup
export PYENV_ROOT="$PYENV_DIR/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "\$(pyenv init -)"
fi
EOF

# Install Python versions
(
  . $DOTRC
  pyenv install --skip-existing $(pyenv install --list | egrep "^\s+2\.7" | grep -v - | grep -v a | tail -1)
  pyenv install --skip-existing $(pyenv install --list | egrep "^\s+3\.6" | grep -v - | grep -v a | tail -1)
  pyenv install --skip-existing $(pyenv install --list | egrep "^\s+3\.7" | grep -v - | grep -v a | tail -1)
  pyenv install --skip-existing $(pyenv install --list | egrep "^\s+3\.8" | grep -v - | grep -v a | tail -1)
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
" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('$NEOVIM_DIR/config/plugged')
Plug 'davidhalter/jedi-vim'
call plug#end()
EOF

$DOT_DIR/bin/nvim +'PlugClean --sync' +'PlugInstall --sync' +'PlugUpdate --sync' +qa



