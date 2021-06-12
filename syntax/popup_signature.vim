
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
	return synIDattr(synIDtrans(syn_id), a:what)
endfunction

let s:bg = s:group_name2synIDattr('Pmenu', 'bg#')
let s:fg_name = s:group_name2synIDattr('Function', 'fg#')
let s:fg_args = s:group_name2synIDattr('Special', 'fg#')
let s:fg_summary = s:group_name2synIDattr('Normal', 'fg#')

let s:mode = (s:bg =~# '^#') ? 'gui' : 'cterm'

execute printf('highlight PopupSignatureFuncName   %sfg=%s %sbg=%s', s:mode, s:fg_name, s:mode, s:bg)
execute printf('highlight PopupSignatureFuncArgs   %sfg=%s %sbg=%s', s:mode, s:fg_args, s:mode, s:bg)
execute printf('highlight PopupSignatureFuncSummay %sfg=%s %sbg=%s', s:mode, s:fg_summary, s:mode, s:bg)
