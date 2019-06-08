
if has('vimscript-3') && has('textprop') && exists('*popup_atcursor')
    scriptversion 3
else
    finish
endif

let s:cachepath = fnamemodify(expand('<sfile>'), ':h:h') .. '/.popup_signature'

function! popup_signature#rebuild(...) abort
    let paths = (0 < a:0) ? (a:000) : [expand('$VIMRUNTIME/doc/popup.txt'), expand('$VIMRUNTIME/doc/eval.txt')]
    let obsoletes = ['buffer_exists', 'buffer_name', 'buffer_number', 'file_readable', 'highlight_exists']
    let lines = []
    for path in paths
        if filereadable(path)
            let lines += readfile(path)
        endif
    endfor
    call filter(lines, { i,x -> (x =~# '^[a-zA-Z_]\+(') || (x =~# '\*$') })
    for x in getcompletion('*', 'function')
        let funcname = matchstr(x, '^.*\ze(')
        if (funcname =~# '^[a-zA-Z_]\+$') && (-1 == index(obsoletes, funcname))
            for y in range(0, len(lines) - 1)
                if lines[y] =~# escape(('*' .. funcname .. '()*'), '*')
                    for z in range(y, y + 3)
                        if lines[z] =~# ('^' .. funcname .. '(')
                            let s:dict[funcname] = matchstr(lines[z], '^[^)]*)')
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

function! popup_signature#execute_cmds_in_popup(funcname) abort
    let w:popup_signature = get(w:, 'popup_signature', {})
    if empty(w:popup_signature)
        let w:popup_signature = {
                \   'bg' : s:group_name2synIDattr(empty(&wincolor) ? 'Pmenu' : &wincolor, 'bg#'),
                \   'fg_name' : s:group_name2synIDattr('Normal', 'fg#'),
                \   'fg_args' : s:group_name2synIDattr('Special', 'fg#'),
                \ }
    endif
    execute printf('highlight PopupSignatureFuncName guifg=%s guibg=%s', w:popup_signature.fg_name, w:popup_signature.bg)
    execute printf('highlight PopupSignatureFuncArgs guifg=%s guibg=%s', w:popup_signature.fg_args, w:popup_signature.bg)
    call matchadd('PopupSignatureFuncName', a:funcname)
    let str = s:dict[(a:funcname)]
    let xs = ['dummy', -1, -1]
    while !empty(xs[0])
        let xs = matchstrpos(str, '{[^}]*}', xs[2])
        call matchadd('PopupSignatureFuncArgs', xs[0])
    endwhile
endfunction

function! popup_signature#show_popup() abort
    if (-1 != index(split(&filetype, '\.'), 'vim')) && get(g:, 'popup_signature_enable', 1)
        let s:dict = get(s:, 'dict', {})
        if empty(s:dict)
            if filereadable(s:cachepath)
                let s:dict = json_decode(readfile(s:cachepath)[0])
            else
                call popup_signature#rebuild()
            endif
        endif
        let funcname = expand('<cword>')
        if has_key(s:dict, funcname)
            let s:popup_id = get(s:, 'popup_id', -1)
            if -1 != s:popup_id
                call popup_close(s:popup_id)
            endif
            let s:popup_id = popup_atcursor(s:dict[funcname], {
                    \   'padding' : [1, 1, 1, 1],
                    \ })
            call win_execute(s:popup_id, printf('call popup_signature#execute_cmds_in_popup(%s)', string(funcname)))
        endif
    endif
endfunction

function! s:group_name2synIDattr(group_name, what) abort
    let syn_id = 1
    while a:group_name != synIDattr(syn_id, 'name')
        let syn_id += 1
    endwhile
    return synIDattr(syn_id, a:what)
endfunction

