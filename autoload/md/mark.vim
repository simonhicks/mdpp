let s:string_type = type('')
let s:list_type = type([])

function! s:charToMark(char)
  if len(a:char) ==# 1
    return (a:char ==# '.') ? '.' : ("'" . a:char)
  else
    return a:char
  endif
endfunction

function! md#mark#get(char)
  return getpos(s:charToMark(a:char))
endfunction

function! md#mark#set(char, ...)
  let mark = s:charToMark(a:char)
  let posarg = len(a:000) ? a:1 : getpos('.')
  let pos = []
  if type(posarg) ==# s:string_type
    let pos = md#mark#get(posarg)
  else
    let pos = posarg
  endif
  call setpos(mark, pos)
endfunction
