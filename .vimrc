fun! Clear() abort
	noh
	let filepath = expand("%")
	call sign_unplacelist([{'buffer': filepath, 'group': 'vcsign'}])
endfun

let arg1 = "foobar_arg1"
let arg2 = "foobar_arg2"

set scl=yes

highlight SignColumn ctermbg=Black

highlight breakpointhl ctermfg=DarkRed ctermbg=Black
sign define breakpoint text=-> texthl=breakpointhl

highlight vclineadd ctermfg=Green      ctermbg=Black
highlight vclinemod ctermfg=DarkYellow ctermbg=Black
highlight vclinedel ctermfg=Red        ctermbg=Black

sign define vclineadd text=+ texthl=vclineadd
sign define vclinemod text=~ texthl=vclinemod
sign define vclinedel text=- texthl=vclinedel

let SIGNNUM = 1

fun! DiffFromAPI(text, filepath, arg1) abort
	let data = {
		\'action': 'diff',
		\'text': a:text,
		\'path': a:filepath,
		\'arg1': a:arg1,
	\}
	let response = SendAPI(data)
	if response['error'] != ""
		throw 'Could not diff file: ' . a:filepath
	else
		return response['result']
	endif
endfun
	
fun! DiffPlaceSign(filepath, linenos, name) abort
	let signs = []
	for lineno in a:linenos
		call add(signs, {
			\'buffer': a:filepath, 
			\'group': 'vcsign', 
			\'id': g:SIGNNUM, 
			\'lnum': lineno, 
			\'name': a:name, 
			\'priority': 15
		\})
		let g:SIGNNUM += 1
	endfor
	call sign_placelist(signs)
endfun

fun! DiffFile() abort
	let filepath = expand("%")
	let bufferText = join(getline(1, '$'), "\n")
	let diff = DiffFromAPI(bufferText, filepath, g:arg1)

	call DiffPlaceSign(filepath, diff['added'],    'vclineadd')
	call DiffPlaceSign(filepath, diff['modified'], 'vclinemod')
	call DiffPlaceSign(filepath, diff['deleted'],  'vclinedel')
endfun


fun! ToggleBreak(lineno) abort
	let filepath = expand("%")
	let signs = sign_getplaced(filepath, {'group': 'breakpoint', 'lnum': a:lineno})
	let breakpoints = signs[0]['signs']
	if len(breakpoints) > 0
		let id = breakpoints[0]['id']
		call sign_unplace('breakpoint', {'buffer': filepath, 'id': id})
	else
		call sign_place(g:SIGNNUM, 'breakpoint', 'breakpoint', filepath, {'lnum': a:lineno})
		let g:SIGNNUM += 1
	endif
endfun

fun! GetBreakPoints() abort
	let json = {}
	let buffers = map(filter(copy(getbufinfo()), 'v:val.listed'), 'v:val.bufnr')
	for buffer in buffers
		let buffersigns = sign_getplaced(buffer, {'group': 'breakpoint'})[0]
		if len(buffersigns['signs']) > 0
			let filepath = bufname(buffersigns['bufnr'])
			let json[filepath] = get(json, filepath, [])
		endif
		for sign in buffersigns['signs']
			call add(json[filepath], sign['lnum'])
		endfor
	endfor
	return json_encode(json)
endfun

fun! RunFromAPI(filepath, arg1, arg2) abort
	let command = "python C:\\Users\\dillon\\Desktop\\vimTesting\\run.py"
	let command .= ' --file="' . shellescape(a:filepath) . '"'
	let command .= ' --arg1="' . shellescape(a:arg1) . '"'
	let command .= ' --arg2="' . shellescape(a:arg2) . '"'
	let command .= ' -- ' . shellescape(GetBreakPoints())

	sil !cls
	execute "!" . command
endfun

fun! SendAPI(data) abort
	let request = json_encode(a:data)
	let channel = ch_open("localhost:8765")
	let response = ch_evalexpr(channel, request)
	call ch_close(channel)
	return json_decode(response)
endfun

fun! ReadFromAPI(filepath, arg1) abort
	let data = {
		\'action': 'read',
		\'path': a:filepath,
		\'arg1': a:arg1,
	\}
	let response = SendAPI(data)
	if response['error'] != ""
		throw 'Could not read file: ' . a:filepath
	else
		return response['result']
	endif
endfun
	
function! WriteToAPI(text, filepath, arg2) abort
	let data = {
		\'action': 'write',
		\'text': a:text,
		\'path': a:filepath,
		\'arg2': a:arg2,
	\}
	let response = SendAPI(data)
	if response['error'] != ""
		throw "Could not write file: " . a:filepath
	endif
endfunction

function! AutoCompleteFromAPI(fileExpr, arg1, arg2) abort
	let data = {
		\'action': 'autocomplete',
		\'file_expr': a:fileExpr,
		\'arg1': a:arg1,
		\'arg2': a:arg2,
	\}
	let response = SendAPI(data)
	if response['error'] != ""
		throw "Could not write file: " . a:filepath
	else
		return response['result']
	endif
endfunction

fun! EditFile(filepath) abort
	let text = ReadFromAPI(a:filepath, g:arg1)
	sil execute "e " . a:filepath
	sil %d|sil 0put =text|sil $d|1
	call setbufvar(a:filepath, '&modified', '0')
endfun

fun! WriteFile(...) abort
	let filepath = get(a:, 1, expand("%"))
	let bufferText = join(getline(1, '$'), "\n")
	call WriteToAPI(bufferText, filepath, g:arg2)
	sil execute "f " . filepath
	call setbufvar(filepath, '&modified', '0')
endfun

fun! AutoCompleteFilePath(ArgLead, CmdLine, CursorPos)
	let results = AutoCompleteFromAPI(a:ArgLead, g:arg1, g:arg2)
	return results
endfun


nnoremap <leader>b :call ToggleBreak(line('.'))<CR>
nnoremap <leader>d :call DiffFile()<CR>

com! -nargs=? -complete=customlist,AutoCompleteFilePath Write call WriteFile(<f-args>)
com! -nargs=1 -complete=customlist,AutoCompleteFilePath Edit call EditFile(<f-args>)

cnoreabbrev <expr> w getcmdtype() == ":" && getcmdline() == 'w' ? 'Write' : 'W'
cnoreabbrev <expr> e getcmdtype() == ":" && getcmdline() == 'e' ? 'Edit' : 'e'
