
if exists(':scriptversion') && exists('*popup_atcursor')
    scriptversion 3
else
    finish
endif

let s:cachepath = fnamemodify(expand('<sfile>'), ':h:h') .. '/.popup_signature'

function! popup_signature#rebuild() abort
    let obsolete_keys = ['buffer_exists', 'buffer_name', 'buffer_number', 'file_readable', 'highlight_exists']
    let lines = []
    for path in [expand('$VIMRUNTIME/doc/popup.txt'), expand('$VIMRUNTIME/doc/eval.txt')]
        if filereadable(path)
            let lines += readfile(path)
        endif
    endfor
    call filter(lines, { i,x -> (x =~# '^[a-z_]\+(') || (x =~# '\*$') })
    for _ in getcompletion('*', 'function')
        let funcname = matchstr(_, '^.*\ze(')
        if (funcname =~# '^[a-z_]\+$') && (-1 == index(obsolete_keys, funcname))
            for i in range(0, len(lines) - 1)
                if lines[i] =~# escape(('*' .. funcname .. '()*'), '*')
                    let s = i
                    let e = i
                    for e in range(i, i + 3)
                        if lines[e] =~# ('^' .. funcname .. '(')
                            let s:dict[funcname] = matchstr(lines[e], '^[^)]*)')
                            break
                        endif
                    endfor
                    break
                endif
            endfor
        endif
    endfor
    call writefile([json_encode(s:dict)], s:cachepath)
endfunction

function! popup_signature#show_popup() abort
    if 'vim' == &filetype
        let s:dict = get(s:, 'dict', {})
        if empty(s:dict)
            if filereadable(s:cachepath)
                let s:dict = json_decode(readfile(s:cachepath)[0])
            else
                call popup_signature#rebuild()
            endif
        endif
        let key = expand('<cword>')
        if has_key(s:dict, key)
            let s:popup_id = get(s:, 'popup_id', -1)
            if -1 != s:popup_id
                call popup_close(s:popup_id)
            endif
            let s:popup_id = popup_atcursor(s:dict[key], {})
        endif
    endif
endfunction

