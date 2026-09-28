{ pkgs, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      # ==========================================================
      # Theme
      # ==========================================================
      onedark-vim

      # ==========================================================
      # Navigation / UI
      # ==========================================================
      nerdtree
      nerdtree-git-plugin
      vim-devicons
      vim-nerdtree-syntax-highlight
      goyo-vim

      # ==========================================================
      # Editing
      # ==========================================================
      nerdcommenter

      # ==========================================================
      # Git
      # ==========================================================
      vim-gitgutter

      # ==========================================================
      # Languages / formats
      # ==========================================================
      vim-markdown
      nginx-vim
      vim-terraform
      vim-toml
      vim-vagrant
      vim-yaml

      # ==========================================================
      # Encryption
      # ==========================================================
      vim-gnupg
    ];

    extraConfig = ''
      " ==========================================================
      " Basic configuration
      " ==========================================================

      syntax on

      filetype on
      filetype plugin indent on

      set nocompatible

      set background=dark
      set number
      set cursorline
      set ruler

      set autoindent
      set smartindent

      set nobackup
      set autowriteall

      set encoding=UTF-8
      set fileformat=unix

      set backspace=indent,eol,start
      set showmatch

      set complete=.,w,b,u

      set updatetime=100

      set hlsearch
      set incsearch
      set ignorecase

      set expandtab
      set shiftwidth=2
      set tabstop=2
      set softtabstop=2

      set termguicolors


      " ==========================================================
      " Theme - OneDark
      " ==========================================================

      let g:onedark_termcolors = 256
      let g:onedark_hide_endofbuffer = 1
      let g:onedark_terminal_italics = 1

      colorscheme onedark


      " ==========================================================
      " Status line
      " ==========================================================

      set laststatus=2

      set statusline=
      set statusline+=\ %Y\ %F\ %M\ %R
      set statusline+=%=
      set statusline+=\ row:\ %l\ col:\ %c\ percent:\ %p%%


      " ==========================================================
      " Leader
      " ==========================================================

      let mapleader = ','


      " ==========================================================
      " GitGutter
      " ==========================================================

      nmap <C-g> :GitGutterEnable<CR>


      " ==========================================================
      " Goyo
      " ==========================================================

      let g:goyo_width = '100%'
      let g:goyo_height = '100%'

      nmap <C-f> :Goyo<CR>


      " ==========================================================
      " Terminal
      " ==========================================================

      nmap <C-d> :below terminal<CR>


      " ==========================================================
      " NERDTree
      " ==========================================================

      let g:NERDTreeMinimalUI = 1
      let g:NERDTreeDirArrows = 0
      let g:NERDTreeShowHidden = 0
      let g:NERDTreeAutoDeleteBuffer = 1
      let g:NERDTreeRespectWildIgnore = 1

      let g:NERDTreeIgnore = [
        \ '\.git$',
        \ '\.svn$',
        \ '\.hg$',
        \ '\.DS_Store$',
        \ '\.devcontainer$',
        \ '\.vscode$',
        \ '__pycache__$',
        \ '\.terraform$',
        \ '\.terraform.lock.hcl$',
        \ '\.terragrunt-cache$',
        \ '\.pyc$'
        \ ]

      nmap <C-t> :NERDTreeToggle<CR>
      nmap <C-n> :NERDTreeFind<CR>


      " ==========================================================
      " Devicons
      " ==========================================================

      let g:webdevicons_enable = 1
      let g:webdevicons_enable_nerdtree = 1
      let g:WebDevIconsUnicodeDecorateFileNodes = 1
      let g:webdevicons_conceal_nerdtree_brackets = 1
      let g:WebDevIconsUnicodeDecorateFolderNodes = 1


      " ==========================================================
      " NERDTree startup
      " ==========================================================

      autocmd StdinReadPre * let s:std_in = 1

      autocmd VimEnter * if argc() == 1 &&
            \ isdirectory(argv()[0]) &&
            \ !exists('s:std_in') |
            \ execute 'NERDTree' argv()[0] |
            \ wincmd p |
            \ enew |
            \ execute 'cd ' . argv()[0] |
            \ endif


      " If another buffer replaces NERDTree,
      " restore NERDTree in the other window.

      autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' &&
            \ bufname('%') !~ 'NERD_tree_\d\+' &&
            \ winnr('$') > 1 |
            \ let buf = bufnr() |
            \ buffer# |
            \ execute "normal! \<C-W>w" |
            \ execute 'buffer' . buf |
            \ endif


      " Exit Vim if NERDTree is the only remaining window.

      autocmd BufEnter * if tabpagenr('$') == 1 &&
            \ winnr('$') == 1 &&
            \ exists('b:NERDTree') &&
            \ b:NERDTree.isTabTree() |
            \ quit |
            \ endif


      " Close tab if NERDTree is the only remaining window.

      autocmd BufEnter * if winnr('$') == 1 &&
            \ exists('b:NERDTree') &&
            \ b:NERDTree.isTabTree() |
            \ quit |
            \ endif


      " ==========================================================
      " Markdown
      " ==========================================================

      let g:vim_markdown_folding_disabled = 1


      " ==========================================================
      " Terraform / HCL
      " ==========================================================

      let g:hcl_align = 1
      let g:terraform_align = 1
      let g:terraform_fmt_on_save = 1


      " ==========================================================
      " YAML
      " ==========================================================

      autocmd FileType yaml setlocal
            \ ts=2
            \ sts=2
            \ sw=2
            \ expandtab
            \ indentkeys-=0#
            \ indentkeys-=<:>
            \ foldmethod=indent
            \ nofoldenable


      " ==========================================================
      " Search
      " ==========================================================

      nnoremap <C-L> :nohlsearch<CR><C-L>


      " ==========================================================
      " Macro
      " ==========================================================

      let @a = "ggi#! /bin/bash\n\n"
    '';
  };

}
