" --------------------------------------------------------------------------------
" view-marked.vim :: markdown preview to Marked 2 App
" --------------------------------------------------------------------------------

" Don't do anything if we're not on OS X.
if !has('unix') || system('uname -s') != "Darwin\n"
    finish
endif


" Save cpoptions.
let s:cpo_save = &cpo
set cpo&vim

" path variable
let s:tmpMarkdownPath='/private/tmp/'
let s:tmpMarkdownFileName='.preview.md'
let s:tmpMarkdown='/private/tmp/.preview.md'

let s:tmpMarkdownAnotherBuffer = '.tmp.md'

" generate markdown preview file
function! s:makeTempMarkdown()

    " If Can't write file, delete and re-generate file
	if filereadable(s:tmpMarkdown)
        silent execute '!rm'.' '.s:tmpMarkdown
        silent execute '!touch'.' '.s:tmpMarkdown
	endif

	try
        let lines = join(getline('^', '$'),'\r')
        let lines = substitute(lines, '`', '\\\`', 'g')
        execute writefile(getline('^','$'), s:tmpMarkdown, "a")

	catch /^Vim\%((\a\+)\)\=:E139/
        " case :: if open it another buffer
		silent execute '%yank'
		silent execute 'sbuffer' fnameescape(s:tmpMarkdownAnotherBuffer)
		silent execute	'%d'
		$put
		silent execute 'save '.s:tmpMarkdown
		hide
	endtry
endfunction



" check open preview file in Marked
function! s:isOpen(path)
    let cmd  = " -e 'try'"
    let cmd .= " -e '	if application \"Marked 2\" is running then'"
    let cmd .= " -e '		tell application \"Marked 2\"'"
    let cmd .= " -e '   		repeat with isFile in documents'"
    let cmd .= " -e '			    if path of isFile is equal to \"".a:path."\" then'"
    let cmd .= " -e '		    		return 1'"
    let cmd .= " -e '	    		end if'"
    let cmd .= " -e '   		end repeat'"
    let cmd .= " -e '		end tell'"
    let cmd .= " -e '	end if'"
    let cmd .= " -e 'end try'"
    return exists(system("osascript ".cmd))
endfunction


" check file exist
function! s:isFile(path)
    if filereadable(expand(a:path)) && !empty(expand(a:path))
        return 1
    else
        return 0
    endif
endfunction


" marked 실행
" run marked
function s:openMarked(path)
    let l:filename = a:path
    " silent execute '! open -a Marked\ 2.app -g'.' '.l:filename
    silent execute '! open -a Marked\ 2.app '.' '.l:filename
    redraw!
endfunction




" quit marked
function! s:quitMarked(path)
    let cmd  = " -e 'try'"
    let cmd .= " -e '   if application \"Marked\ 2.app\" is running then'"
    let cmd .= " -e '       tell application \"Marked\ 2.app\"'"
    let cmd .= " -e '           close (every window whose name is \"".a:path."\")'"
    let cmd .= " -e '           if count of documents is equal to 0 then'"
    let cmd .= " -e '               quit'"
    let cmd .= " -e '           end if'"
    let cmd .= " -e '       end tell'"
    let cmd .= " -e '   end if'"
    let cmd .= " -e 'end try'"

    silent exe "!osascript ".cmd
    redraw!
endfunction

function! s:closeMarkdown()
    if (&ft != "markdown" && &ft != "vimwiki")
        return
    endif

    let s:isFile = s:isFile(expand('%:p'))

    if (!s:isFile)
        call s:quitMarked(s:tmpMarkdownFileName)
    else
        call s:quitMarked(expand('%:t'))
    endif
endfunction


function! s:previewMarkdown()
    if (&ft != "markdown" && &ft != "vimwiki")
        return
    endif

    " check marked preview window
    let s:isFile = s:isFile(expand('%:p'))
    let s:isOpen = s:isOpen(expand('%:p'))

    if (!s:isFile)
        call s:makeTempMarkdown()

        if (!s:isOpen)
            call s:openMarked(s:tmpMarkdown)
        endif
        echo "Markdown Preview"
    else
        " save and open md file
        write
        if (!s:isOpen)
            call s:openMarked(expand('%:p'))
        endif
    endif
endfunction


" close preview marked window
function! ChangeMarkedView()
    call s:quitMarked(s:tmpMarkdownFileName)
    call s:openMarked(expand('%:p'))
endfunction


" command
command! -nargs=0 -bang ViewMarked call <SID>previewMarkdown()
command! -nargs=0 -bang CloseMarked call <SID>closeMarkdown()

let &cpo = s:cpo_save
unlet s:cpo_save