
if has('vimscript-3') && has('textprop') && exists('*popup_atcursor')
	scriptversion 3
else
	finish
endif

let s:__version__ = 6
let s:cachepath = fnamemodify(expand('<sfile>'), ':h:h') .. '/.popup_signature'

function! popup_signature#build() abort
	call s:message('Building cache ...')
	let s:dict = {}
	let paths = [
		\ expand('$VIMRUNTIME/doc/usr_41.txt'),
		\ expand('$VIMRUNTIME/doc/popup.txt'),
		\ expand('$VIMRUNTIME/doc/channel.txt'),
		\ expand('$VIMRUNTIME/doc/terminal.txt'),
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
		\ (x =~# '^\s\+|\?[a-zA-Z0-9_]\+()|\?') ||
		\ (x =~# '^[a-zA-Z0-9_]\+(') ||
		\ (x =~# '\*$')
		\ })
	for x in getcompletion('*', 'function')
		let funcname = matchstr(x, '^.*\ze(')
		if (funcname =~# '^[a-zA-Z0-9_]\+$') && (-1 == index(obsoletes, funcname))
			let summary = ''
			let signature = ''
			for y in range(0, len(lines) - 1)
				if lines[y] =~# ('^\s\+|\?' .. funcname .. '()|\?')
					let summary = matchstr(lines[y], ')|\?\s\+\zs.*$')
					break
				endif
			endfor
			for y in range(0, len(lines) - 1)
				if lines[y] =~# escape(('*' .. funcname .. '()*'), '*')
					for z in range(y, y + 3)
						if lines[z] =~# ('^' .. funcname .. '(')
							let signature = matchstr(lines[z], '^[^)]*)')
							break
						endif
					endfor
					break
				endif
			endfor
			if !empty(summary) && !empty(signature)
				let s:dict[funcname] = {
					\ 'summary' : summary,
					\ 'signature' : signature,
					\ }
			endif
		endif
	endfor
	let s:dict.__version__ = s:__version__
	call writefile([json_encode(s:dict)], s:cachepath)
	call s:message('Has builded cache.')
endfunction

function! popup_signature#close_popup() abort
	let s:popup_id = get(s:, 'popup_id', -1)
	if -1 != s:popup_id
		call popup_close(s:popup_id)
	endif
endfunction

function! popup_signature#show_popup() abort
	let funcname = expand('<cword>')
	if !get(g:, 'popup_signature_enable', 1)
		return
	endif
	if -1 == index(split(&filetype, '\.'), 'vim')
		return
	endif
	if '__version__' == funcname
		return
	endif
	if -1 == stridx(getline('.'), funcname .. '(')
		return
	endif
	let s:dict = get(s:, 'dict', {})
	if empty(s:dict) && filereadable(s:cachepath)
		let s:dict = json_decode(readfile(s:cachepath)[0])
	endif
	if get(s:dict, '__version__', 0) < s:__version__
		call popup_signature#build()
	endif
	if !has_key(s:dict, funcname)
		return
	endif
	" delay the popup window.
	if -1 != get(s:, 'timer_id', -1)
		call timer_stop(s:timer_id)
	endif
	let s:timer_id = timer_start(&timeoutlen, function('s:delay_popup', [funcname]))
endfunction

function! s:delay_popup(funcname, timer) abort
	try
		call popup_signature#close_popup()
		let lines = [get(s:dict[a:funcname], 'signature', '')]
		if !empty(get(s:dict[a:funcname], 'summary', ''))
			let lines += [printf('  %-' .. len(lines[0]) .. 's', get(s:dict[a:funcname], 'summary', ''))]
		endif
		let s:popup_id = popup_atcursor(lines, {
			\   'padding' : [1, 1, 1, 1],
			\ })
		if has('win32')
			if has('gui_running')
				call win_execute(s:popup_id, 'setfiletype popup_signature')
			else
				if has('vcon') && has('termguicolors')
					if &termguicolors
						call win_execute(s:popup_id, 'setfiletype popup_signature')
					endif
				endif
			endif
		else
			if 256 <= &t_Co
				call win_execute(s:popup_id, 'setfiletype popup_signature')
			endif
		endif
	catch
	finally
		let s:timer_id = -1
	endtry
endfunction

function! s:message(text) abort
	echohl Title
	echomsg printf('[popup_signature] %s', a:text)
	echohl None
endfunction

