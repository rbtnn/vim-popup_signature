
if has('vimscript-3') && has('textprop') && exists('*popup_atcursor')
    scriptversion 3
else
    finish
endif

syntax match  PopupSignatureFuncName      /^[a-zA-Z0-9_]\+/
syntax region PopupSignatureFuncArgs      start='{'  end='}'
syntax match  PopupSignatureFuncSummay    /\%2l/ 

function! s:group_name2synIDattr(group_name, what) abort
    let syn_id = 1
    while a:group_name != synIDattr(syn_id, 'name')
        let syn_id += 1
    endwhile
    return synIDattr(syn_id, a:what)
endfunction

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

