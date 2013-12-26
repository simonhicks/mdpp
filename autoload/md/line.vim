"""""""""""""""""""""""""""""""""""""""""
" convert lnum to a number representation
"""""""""""""""""""""""""""""""""""""""""
function! md#line#num(lnum)
  if type(a:lnum) ==# 0
    return a:lnum
  else
    return line(a:lnum)
  endif
endfunction

function! md#line#isBlank(lnum)
  return md#str#isBlank(getline(md#line#num(a:lnum)))
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns true, if lnum is a non heading line, or a heading of level `minimum`
" or greater
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! md#line#isAtLeastLevel(lnum, minimum)
  let level = md#line#headingLevel(a:lnum)
  return level ==# 0 || level >= a:minimum
endfunction

""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a heading line
""""""""""""""""""""""""""""""""""""""""
function! md#line#isHeading(lnum)
  let lnum = md#line#num(a:lnum)
  return md#line#headingLevel(lnum) > 0
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a blank line immediately before a heading line
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! md#line#isBlankBeforeHeading(lnum)
  let lnum = md#line#num(a:lnum)
  return md#line#isBlank(lnum) && md#line#isHeading(lnum + 1)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a heading underline
""""""""""""""""""""""""""""""""""""""""""""""
function! md#line#isUnderline(lnum)
  let lnum = md#line#num(a:lnum)
  return md#line#isHeading(lnum - 1) && match(getline(lnum), '^[=-][=-]*$') != -1
endfunction

function! md#line#isListItem(lnum)
  return match(getline(a:lnum), "^[[:space:]]*- ") != -1
endfunction

function! md#line#underlinedHeadingLevel(lnum)
  let nextLine = md#str#trim(getline(md#line#num(a:lnum) + 1))
  if match(nextLine, '^==*$') != -1
    return 1
  elseif match(nextLine, '^--*$') != -1
    return 2
  else
    return 0
  endif
endfunction

function! md#line#hashHeadingLevel(lnum)
  return len(matchstr(getline(a:lnum), "^#*"))
endfunction

function! md#line#headingLevel(lnum)
  let l1 = md#line#underlinedHeadingLevel(a:lnum)
  if l1 > 0
    return l1
  else
    return md#line#hashHeadingLevel(a:lnum)
  endif
endfunction

function! md#line#sectionLevel(lnum)
  let curr = md#line#num(a:lnum)
  let found = 0
  while ((found == 0) && (curr >= 1))
    if md#line#isHeading(curr)
      let found = curr
    endif
    let curr = curr - 1
  endwhile
  return (found > 0) ? md#line#headingLevel(found) : -1
endfunction

if g:with_todo_features
  call md#todo#init()

  function! md#line#getTodoState(lnum)
    if md#line#isHeading(a:lnum)
      return md#str#getTodoState(getline(a:lnum))
    else
      let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
                \ . " Can't get todo state for non heading line"
      throw message
    endif
  endfunction

  function! md#line#setTodoState(lnum, state)
    if md#line#isHeading(a:lnum)
      let string = md#str#setTodoState(getline(a:lnum), a:state)
      call setline(a:lnum, string)
    else
      let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
                \ . "Can't modify todo state for non heading line"
      throw message
    endif
  endfunction

  function! md#line#incTodoState(lnum)
    if md#line#isHeading(a:lnum)
      let state = md#todo#next(md#line#getTodoState(a:lnum))
      return md#line#setTodoState(a:lnum, state)
    else
      let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
                \ . "Can't modify todo state for non heading line"
      throw message
    endif
  endfunction

  function! md#line#decTodoState(lnum)
    if md#line#isHeading(a:lnum)
      let state = md#todo#prev(md#line#getTodoState(a:lnum))
      return md#line#setTodoState(a:lnum, state)
    else
      let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
                \ . "Can't modify todo state for non heading line"
      throw message
    endif
  endfunction
endif
