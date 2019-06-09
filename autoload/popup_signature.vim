
if has('vimscript-3') && has('textprop') && exists('*popup_atcursor')
    scriptversion 3
else
    finish
endif

function! popup_signature#build() abort
    call s:message('Building cache ...')
    let paths = [
            \ expand('$VIMRUNTIME/doc/usr_41.txt'),
            \ expand('$VIMRUNTIME/doc/popup.txt'),
            \ expand('$VIMRUNTIME/doc/eval.txt'),
            \ ]
    let obsoletes = ['buffer_exists', 'buffer_name', 'buffer_number', 'file_readable', 'highlight_exists']
    let lines = []
    for path in paths
        if filereadable(path)
            let lines += readfile(path)
        endif
    endfor
    call filter(lines, { i,x ->
            \ (x =~# '^\s\+[a-zA-Z0-9_]\+()') ||
            \ (x =~# '^[a-zA-Z0-9_]\+(') ||
            \ (x =~# '\*$')
            \ })
    for x in getcompletion('*', 'function')
        let funcname = matchstr(x, '^.*\ze(')
        if (funcname =~# '^[a-zA-Z0-9_]\+$') && (-1 == index(obsoletes, funcname))
            let summary = ''
            for y in range(0, len(lines) - 1)
                if lines[y] =~# ('^\s\+' .. funcname .. '()')
                    let summary = matchstr(lines[y], ')\s\+\zs.*$')
                endif
                if lines[y] =~# escape(('*' .. funcname .. '()*'), '*')
                    for z in range(y, y + 3)
                        if lines[z] =~# ('^' .. funcname .. '(')
                            let s:dict[funcname] = {
                                    \   'signature' : matchstr(lines[z], '^[^)]*)'),
                                    \   'summary' : summary,
                                    \ }
                            break
                        endif
                    endfor
                    break
                endif
            endfor
        endif
    endfor
    let s:dict.__version__ = s:__version__
    call writefile([json_encode(s:dict)], s:cachepath)
    call s:message('Has builded cache.')
endfunction

function! popup_signature#execute_cmds_in_popup(funcname) abort
    call matchadd('PopupSignatureFuncName', a:funcname, 1)
    let signature = s:dict[(a:funcname)].signature
    let xs = ['dummy', -1, -1]
    while !empty(xs[0])
        let xs = matchstrpos(signature, '{[^}]*}', xs[2])
        call matchadd('PopupSignatureFuncArgs', xs[0], 2)
    endwhile
    call matchadd('PopupSignatureFuncSummay', '\%2l', 3)
    nohlsearch
endfunction

function! popup_signature#show_popup() abort
    if (-1 != index(split(&filetype, '\.'), 'vim')) && get(g:, 'popup_signature_enable', 1)
        let s:dict = get(s:, 'dict', {})
        if empty(s:dict) && filereadable(s:cachepath)
            let s:dict = json_decode(readfile(s:cachepath)[0])
        endif
        if (get(s:dict, '__version__', 0) < s:__version__)
            call popup_signature#build()
        endif
        let funcname = expand('<cword>')
        if ('__version__' != funcname) && has_key(s:dict, funcname)
            let s:popup_id = get(s:, 'popup_id', -1)
            if -1 != s:popup_id
                call popup_close(s:popup_id)
            endif
            let lines = [(s:dict[funcname].signature)]
            if !empty(s:dict[funcname].summary)
                let lines += [printf('  %-' .. len(lines[0]) .. 's', s:dict[funcname].summary)]
            endif
            let s:popup_id = popup_atcursor(lines, {
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

function! s:message(text) abort
    echohl Title
    echomsg printf('[popup_signature] %s', a:text)
    echohl None
endfunction

let s:__version__ = 4

let s:cachepath = fnamemodify(expand('<sfile>'), ':h:h') .. '/.popup_signature'

let s:bg = s:group_name2synIDattr('Pmenu', 'bg#')
let s:fg_name = s:group_name2synIDattr('Function', 'fg#')
let s:fg_args = s:group_name2synIDattr('Special', 'fg#')
let s:fg_summary = s:group_name2synIDattr('Normal', 'fg#')

if has('gui')
    execute printf('highlight PopupSignatureFuncName   guifg=%s guibg=%s', s:fg_name, s:bg)
    execute printf('highlight PopupSignatureFuncArgs   guifg=%s guibg=%s', s:fg_args, s:bg)
    execute printf('highlight PopupSignatureFuncSummay guifg=%s guibg=%s', s:fg_summary, s:bg)
else
    execute printf('highlight PopupSignatureFuncName   ctermfg=%s ctermbg=%s', s:fg_name, s:bg)
    execute printf('highlight PopupSignatureFuncArgs   ctermfg=%s ctermbg=%s', s:fg_args, s:bg)
    execute printf('highlight PopupSignatureFuncSummay ctermfg=%s ctermbg=%s', s:fg_summary, s:bg)
endif

