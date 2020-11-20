let s:cmd = "aspell --mode=none --ignore=2 --byte-offsets --dont-backup --dont-suggest --run-together --run-together-limit=1000 --run-together-min=3 -a --lang=en"

let s:aspell_error_symbols = ['?', '#']
let s:aspell_special_characters = ['*', '&', '@', '+', '-', '\~', '#', '!', '%', '\^', '''']
let s:aspell_special_characters_pattern = join(s:aspell_special_characters, '\|')

func! spelling#GetMisspelledWord()
    let l:result = ''
    let l:line = line('.')
    let l:column = col('.')
    for l:match in getmatches()
        let l:i = 1
        while l:i <= 8
            let l:pos = get(l:match, 'pos' . l:i)
            if empty(l:pos)
                break
            endif
            let l:match_line = l:pos[0]
            let l:match_column_start = l:pos[1]
            let l:match_column_end = l:match_column_start + l:pos[2] - 1
            if l:match.group == 'SpellBad' &&
                \   l:match_line == l:line &&
                \   l:column >= l:match_column_start &&
                \   l:column <= l:match_column_end
                let l:result = getline('.')[l:match_column_start - 1: l:match_column_end - 1]
            endif
            let l:i += 1
        endwhile
    endfor
    return l:result
endfunc

func! spelling#Split(str)
    let l:results = []
    call substitute(
    \   a:str,
    \   '\v\C[[:lower:],[:upper:]][[:lower:]]+|[[:upper:]]+([[:lower:]]@!)',
    \   '\=add(l:results, submatch(0))',
    \   'g'
    \)
    return l:results
endfunc

func! spelling#GetBufferText()
    let l:results = []
    for l:line in getline(1, '$')
        if empty(l:line)
            let l:line = ' '
        else
            let l:line = substitute(
            \   l:line, s:aspell_special_characters_pattern,
            \   " ",
            \   "g"
            \)
        endif
        call add(l:results, l:line)
    endfor
    return join(l:results, "\n")
endfunc

func! spelling#GetRunTogetherDataText(data)
    let l:results = []
    for l:item in a:data
        call add(l:results, join(l:item.words, ' '))
    endfor
    return join(l:results, "\n")
endfunc

func! spelling#GetErrorData(str)
    let l:error = split(
    \   split(
    \       a:str, ":"
    \   )[0]
    \   , " "
    \)
    let l:word = l:error[1]
    let l:result = {
    \   'word': l:word,
    \   'word_length': strlen(l:word),
    \   'column_number': str2nr(l:error[-1])
    \}
    return l:result
endfunc

func! spelling#JobCallback(job_id, data, event) dict
    call spelling#Clear()
    if empty(a:data) || self.bufnr != bufnr()
        return
    endif

    let l:run_together_words = []
    let l:line_number = 0
    let l:positions = []
    for l:str in a:data[1:]
        if index(s:aspell_error_symbols, l:str[0]) >= 0
            let l:error_data = spelling#GetErrorData(l:str)
            let l:words = spelling#Split(l:error_data.word)
            if len(l:words) == 1
                call add(
                \   l:positions,
                \   [
                \       l:line_number + 1,
                \       l:error_data.column_number + 1,
                \       l:error_data.word_length,
                \   ]
                \)
                if len(l:positions) == 8
                    call matchaddpos('SpellBad', l:positions, -1)
                    let l:positions = []
                endif
            else
                call add(
                \   l:run_together_words,
                \   {
                \       'words': l:words,
                \       'line_number': l:line_number,
                \       'column_number': l:error_data.column_number,
                \   }
                \)
            endif
        endif
        if empty(l:str)
            let l:line_number += 1
        endif
    endfor
    if !empty(l:positions)
        call matchaddpos('SpellBad', l:positions, -1)
    endif

    if has_key(b:, 'spelling_run_together_job_id') && !empty(b:spelling_run_together_job_id)
        silent! call jobstop(b:spelling_run_together_job_id)
        let b:spelling_run_together_job_id = v:null
    endif
    let b:spelling_run_together_job_id = jobstart(
    \   s:cmd,
    \   {
    \       'on_stdout': 'spelling#RunTogetherJobCallback',
    \       'stdout_buffered': v:true,
    \       'words': l:run_together_words,
    \   }
    \)
    call chansend(b:spelling_run_together_job_id, spelling#GetRunTogetherDataText(l:run_together_words))
    call chanclose(b:spelling_run_together_job_id, 'stdin')
endfunc

func! spelling#RunTogetherJobCallback(job_id, data, event) dict
    if empty(a:data)
        return
    endif
    let l:line_number = 0
    let l:run_together_words_count = 0
    let l:positions = []
    for l:str in a:data[1:]
        if index(s:aspell_error_symbols, l:str[0]) >= 0
            let l:error_data = spelling#GetErrorData(l:str)
            let l:run_together_word_data = self.words[l:line_number]
            call add(
            \   l:positions,
            \   [
            \       l:run_together_word_data.line_number + 1,
            \       l:error_data.column_number + l:run_together_word_data.column_number - l:run_together_words_count + 1,
            \       l:error_data.word_length,
            \   ]
            \)
            if len(l:positions) == 8
                call matchaddpos('SpellBad', l:positions, -1)
                let l:positions = []
            endif
        endif
        let l:run_together_words_count += 1
        if empty(l:str)
            let l:line_number += 1
            let l:run_together_words_count = 0
        endif
    endfor
    if !empty(l:positions)
        call matchaddpos('SpellBad', l:positions, -1)
    endif
endfunc

func! spelling#Update()
    if !g:spelling_enabled || &readonly || empty(&filetype) || index(g:spelling_ignore_buffer_types, &filetype) >= 0
        return
    endif
    if has_key(b:, 'spelling_job_id') && !empty(b:spelling_job_id)
        silent! call jobstop(b:spelling_job_id)
        let b:spelling_job_id = v:null
    endif
    let b:spelling_job_id = jobstart(
    \   s:cmd,
    \   {
    \       'on_stdout': 'spelling#JobCallback',
    \       'stdout_buffered': v:true,
    \       'bufnr': bufnr(),
    \   }
    \)
    call chansend(b:spelling_job_id, spelling#GetBufferText())
    call chanclose(b:spelling_job_id, 'stdin')
endfunc

func! spelling#Clear()
    for l:match in getmatches()
        if l:match.group == 'SpellBad'
            call matchdelete(l:match.id)
        endif
    endfor
endfunc

func! spelling#Toggle()
    if g:spelling_enabled
        let g:spelling_enabled = 0
        call spelling#Clear()
    else
        let g:spelling_enabled = 1
        call spelling#Update()
    endif
endfunc

func! spelling#AddWord()
    let l:word = spelling#GetMisspelledWord()
    if !empty(l:word)
        call system('echo -e "*' . l:word . '\n#" | aspell -a')
        call spelling#Update()
        echo 'Spelling: word "' . l:word . '" successfully added.'
    else
        echo 'Spelling: no misspelled word found'
    endif
endfunc

