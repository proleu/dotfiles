" unused
" set mouse=a                 " enable mouse click
" set mouse=v                 " middle-click paste with
" set spell                 " enable spell check (may need to download language package)
" set noswapfile            " disable creating swap file
" set backupdir=~/.cache/vim " Directory to store backup files.
" set clipboard=unnamedplus   " using system clipboard

set nocompatible            " disable compatibility to old-time vi
" search configs
set hlsearch                " highlight search
set ignorecase              " case insensitive
set incsearch               " incremental search
set showmatch               " show matching
" behavioral configs
set autoindent              " indent a new line the same amount as the line just typed
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set tabstop=4               " number of columns occupied by a tab
" ui configs
set cursorline              " highlight current cursorline
set number                  " add line numbers
" open new split panes to right and below
set splitright
set splitbelow
set ttyfast                 " Speed up scrolling in Vim
set wildmode=longest,list   " get bash-like tab completions
set cc=80                  " set an 80 column border for good coding style
" code file configs
syntax on                   " syntax highlighting
" plugin stuff
filetype plugin on
filetype plugin indent on   "allow auto-indenting depending on file type

" automatically load plugins
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" plugin loading
call plug#begin('~/.vim/plugged')
 Plug 'dracula/vim' " theme
 Plug 'github/copilot.vim' " Copilot
 Plug 'mhinz/vim-startify'
 Plug 'scrooloose/nerdtree'
 Plug 'tpope/vim-commentary'
 Plug 'tpope/vim-surround'
call plug#end()

" automatically color stuff
if (has('termguicolors'))
 set termguicolors
 endif
 syntax enable
colorscheme dracula
" automatically jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif
autocmd VimEnter * NERDTree | wincmd p
