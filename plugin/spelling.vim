let g:spelling_enabled = get(g:, 'spelling_enabled', 1)
let g:spelling_ignore_buffer_types = get(g:, 'spelling_ignore_buffer_types', ['qf', 'tagbar'])
let g:spelling_update_events = get(g:, 'spelling_update_events', v:null)
let g:spelling_file_types = get(g:, 'spelling_file_types', v:null)

command! SpellingAddWord call spelling#AddWord()
command! SpellingUpdate call spelling#Update()
command! SpellingToggle call spelling#Toggle()

if exists('g:loaded_spelling')
  finish
endif
let g:loaded_spelling = 1

if empty(g:spelling_update_events)
    finish
endif

let s:update_events = join(g:spelling_update_events, ',')
let s:file_types = !empty(g:spelling_file_types) ? 
\   join(map(copy(g:spelling_file_types), {index, value -> printf('*.%s', value)}), ',') : '*'

augroup spelling_autocmds
    autocmd!
    exe 'autocmd ' . s:update_events . ' ' . s:file_types . ' call spelling#Update()'
augroup END
