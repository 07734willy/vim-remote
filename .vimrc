function! AutoCompleteFile(ArgLead, CmdLine, CursorPos)
	return system("python C:\\...\\autocomplete.py \"" . a:ArgLead . "\"")
endfunction

function! ReadFromAPI(filename)
	sil !cls
	let text = system("python C:\\...\\read.py \"" . a:filename . "\"")
	if v:shell_error
		echoerr 'Could not read file: ' a:filename
	else
		sil execute "e " . a:filename
		sil %d|sil 0put =text|sil $d|1
	endif
endfunction
	
function! WriteToAPI()
	sil !cls
	let bufferText = join(getline(1, '$'), "\n")
	let filepath = expand("%:p")
	call system("python C:\\...\\write.py \"". filepath . "\"", bufferText)
	if v:shell_error
		echoerr "Could not write file: " filepath
	else
		call setbufvar(filepath, '&modified', '0')
	endif
endfunction

com! -nargs=0 W call WriteToAPI()
com! -nargs=1 -complete=custom,AutoCompleteFile E call ReadFromAPI(<f-args>)

cnoreabbrev <expr> w getcmdtype() == ":" && getcmdline() == 'w' ? 'W' : 'W'
cnoreabbrev <expr> e getcmdtype() == ":" && getcmdline() == 'e' ? 'E' : 'e'
