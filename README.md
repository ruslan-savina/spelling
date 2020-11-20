# Asynchronous spelling checker for Neovim
### Requirements: aspell. You might also need to install aspell english dictionary.
### Installing
```
Plug 'ruslan-savina/spelling'
```
`:PlugInstall`

### Supports
```
camelCase
PascalCase
snake_case
kebab-case
```

### Config example
```
let g:spelling_update_events = ['TextChanged', 'InsertLeave', 'BufRead']

autocmd ColorScheme * highlight SpellBad cterm=underline gui=underline ctermfg=243 guifg=#727272

nnoremap <leader>st :SpellingToggle<cr>
nnoremap <leader>sa :SpellingAddWord<cr>
```
