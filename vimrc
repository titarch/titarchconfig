" ~/.vimrc

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" https://github.com/tpope/vim-sensible
Plugin 'tpope/vim-sensible'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

runtime! plugin/sensible.vim

set encoding=utf-8 fileencodings=
syntax on

set number
set cc=80

autocmd Filetype make setlocal noexpandtab

set list listchars=tab:??,trail:?


" per .git vim configs
" just `git config vim.settings "expandtab sw=4 sts=4"` in a git repository
" change syntax settings for this repository
let git_settings = system("git config --get vim.settings")
if strlen(git_settings)
 exe "set" git_settings
endif

" My modifs //////////////////////////////////////////////////////////////////
Plugin 'dracula/vim', { 'name': 'dracula' }
set hlsearch
"inoremap ( ()<left>
"inoremap (( (
"inoremap () ()
"inoremap ) <right>
"inoremap )) )
"
"inoremap [ []<left>
"inoremap [[ [
"inoremap [] []
"inoremap ] <right>
"inoremap ]] ]
"
"inoremap { {}<left>
"inoremap {<CR>  {<CR>}<Esc>O
"inoremap {{     {
"inoremap {}     {}
"inoremap } <right>
"inoremap }} }

"set t_Co=256
""set background=dark
colorscheme dracula
hi Normal guibg=NONE ctermbg=NONE
"highlight Normal ctermbg=NONE
"highlight nonText ctermbg=NONE


" show existing tab with 4 spaces width
set tabstop=8
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab
set shiftwidth=4

Plugin 'itchyny/lightline.vim'
Plugin 'scrooloose/nerdtree'
map <C-o> :NERDTreeToggle<CR>
map <C-t> :tab new<CR>
set mouse=a

set foldmethod=syntax
set foldlevelstart=20
set foldcolumn=4

Plugin 'scrooloose/syntastic'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
nnoremap <C-a> :lclose<CR>
Plugin 'rhysd/vim-clang-format'
let g:clang_format#detect_style_file = 1
Plugin 'chrisbra/colorizer'
let g:colorizer_auto_color = 1
"let g:colorizer_hex_pattern = ['#', '\%(\x\{3}\|\x\{6}\)', '']
