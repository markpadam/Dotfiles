" ~/.vimrc

set nocompatible
syntax on
filetype plugin indent on

set number
set relativenumber
set nowrap
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set clipboard=unnamed,unnamedplus
set background=dark
set cursorline
set wildmenu
set incsearch
set hlsearch
set ignorecase
set smartcase
set laststatus=2
set backspace=indent,eol,start

" Show tabs/trailing spaces — critical when hand-editing Kubernetes YAML.
set list
set listchars=tab:>-,trail:·

" YAML (k8s manifests) must be 2-space, expandtab, no autoindent surprises.
augroup yaml_indent
    autocmd!
    autocmd FileType yaml,yml setlocal tabstop=2 shiftwidth=2 expandtab indentkeys-=0# indentkeys-=<:>
augroup END
