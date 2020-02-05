command! SpellingAddWord call spelling#AddWord()
command! SpellingUpdate call spelling#Update()
command! SpellingToggle call spelling#Toggle()

augroup spelling
    autocmd ColorScheme * highlight SpellingError cterm=underline gui=underline ctermfg=243 guifg=#727272
augroup END
