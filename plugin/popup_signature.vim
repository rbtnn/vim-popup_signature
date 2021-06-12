
if has('vimscript-3') && has('textprop') && exists('*popup_atcursor')
	scriptversion 3
else
	finish
endif

let g:loaded_popup_signature = 1

augroup popup_signature
	autocmd!
	autocmd CursorMoved * :call popup_signature#show_popup()
augroup END

