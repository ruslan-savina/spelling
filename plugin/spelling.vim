augroup SpellingGroup
    command! SpellingAddWord call spelling#AddWord()
    command! SpellingUpdate call spelling#Update()
    command! SpellingToggle call spelling#Toggle()
augroup END
