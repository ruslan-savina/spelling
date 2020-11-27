let g:spelling_enabled = get(g:, 'spelling_enabled', 1)
let g:spelling_ignore_buffer_types = get(g:, 'spelling_ignore_buffer_types', ['qf', 'tagbar'])
let g:spelling_update_events = get(g:, 'spelling_update_events', [])

command! SpellingAddWord call spelling#AddWord()
command! SpellingUpdate call spelling#Update()
command! SpellingToggle call spelling#Toggle()

augroup spelling_autocmds
    autocmd!
    exe 'autocmd '.join(g:spelling_update_events, ',').' * call spelling#Update()'
augroup END
