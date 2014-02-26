" code folding

function! md#core#fold(lnum)
  if md#line#isBlank(a:lnum)
    return '-1'
  endif
  let l = md#line#sectionLevel(a:lnum)
  if md#line#isHeading(a:lnum)
    return '>' . l
  else
    return '' . l
  endif
endfunction

" text objects

function! md#core#insideSection()
  call md#move#toParentHeading()
  let target = md#line#headingLevel('.')
  normal! j
  if md#line#isUnderline('.')
    normal! j
  endif
  normal! V
  call md#move#downUntilLevel(target)
  if md#line#isBlankBeforeHeading('.')
    normal! k
  endif
endfunction

function! md#core#aroundSection(op)
  if a:op
    normal! l
  endif
  " if cursor is on the first character of a heading line, and there's no
  " existing visual selection, then select that section... otherwise select
  " the section surrounding the cursor
  if !((getpos("'<") == getpos("'>")) && (col('.') == 1) && md#line#isHeading('.'))
    call md#move#toParentHeading()
  endif
  let target = md#line#headingLevel('.')
  normal! V
  call md#move#downUntilLevel(target)
endfunction

function! md#core#insideTree()
  call md#move#toRootHeading()
  normal! j
  if md#line#isUnderline('.')
    normal! j
  endif
  normal! V
  call md#move#downUntilLevel(1)
  if md#line#isBlankBeforeHeading('.')
    normal! k
  endif
endfunction

function! md#core#aroundTree()
  call md#move#toRootHeading()
  normal! V
  call md#move#downUntilLevel(1)
endfunction

function! md#core#insideHeading()
  call md#move#ensureHeading()
  if match(getline('.'), '^#') != -1
    execute "normal! f lvg_o"
  else
    normal! vg_o
  endif
endfunction

function! md#core#aroundHeading()
  call md#move#ensureHeading()
  if match(getline('.'), '^#') != -1
    normal! vg_o
  else
    normal! Vjo
  endif
endfunction

function! md#core#insideMetadata()
  let start = getpos('.')
  call md#move#ensureHeading()
  if md#line#hasMetadata('.')
    normal! 0f{vi{
  else
    call setpos('.', start)
  endif
endfunction

function! md#core#aroundMetadata()
  let start = getpos('.')
  call md#move#ensureHeading()
  if md#line#hasMetadata('.')
    normal! 0f{va{
  else
    call setpos('.', start)
  endif
endfunction

" tree manipulation

" call a:fn with pos '.' at each child heading in succession
function! s:eachChildHeading(fn, args)
  let pos = getpos('.')
  try
    let moved = md#move#toFirstChildHeading()
    let lines = []
    while moved !=# -1
      call add(lines, moved)
      let moved = md#move#toNextSibling()
    endwhile
    for line in lines
      call setpos('.', [0, line, 0, 0])
      call call(a:fn, a:args)
    endfor
  finally
    call setpos('.', pos)
  endtry
endfunction

function! md#core#incHeading(cascade)
  let pos = getpos('.')
  try
    if a:cascade
      call s:eachChildHeading("md#core#incHeading", [1])
    endif
    normal! l
    call md#move#toParentHeading()
    let underline = md#line#underlinedHeadingLevel('.')
    if underline == 1
      normal! jviwr-k
    elseif underline == 2
      execute "normal! I### "
      normal! jddk
    else
      normal! I#
    endif
  finally
    call setpos('.', pos)
  endtry
endfunction

function! md#core#decHeading(cascade)
  let pos = getpos('.')
  try
    if a:cascade
      call s:eachChildHeading("md#core#decHeading", [1])
    endif
    normal! l
    call md#move#toParentHeading()
    let underline = md#line#underlinedHeadingLevel('.')
    if underline == 1
      return -1
    elseif underline == 2
      normal! jviwr=k
    else
      normal! x
    endif
  finally
    call setpos('.', pos)
  endtry
endfunction

function! s:moveSection(...)
  let movefuncs = a:000
  let storedRegister = @a
  let storedMarkA = md#mark#get('a')
  let storedMarkB = md#mark#get('b')
  try
    call md#move#ensureHeading()
    call md#mark#set('a')
    for movefunc in movefuncs
      call call(movefunc, [])
    endfor
    call md#mark#set('b')
    if md#mark#get('a') !=# md#mark#get('b')
      call md#mark#set('.', 'a')
      exec 'normal! "ad:call md#core#aroundSection(1)'
      call md#mark#set('.', 'b')
      normal! "aP
    endif
  finally
    let @a = storedRegister
    call md#mark#set("a", storedMarkA)
    call md#mark#set("b", storedMarkB)
  endtry
endfunction

function! md#core#moveSectionBack()
  call s:moveSection("md#move#toPreviousSibling")
endfunction

function! md#core#moveSectionForward()
  let before = md#mark#get('.')
  call md#move#toNextSibling()
  if md#mark#get('.') !=# before
    call md#core#moveSectionBack()
    call md#move#toNextSibling()
  endif
endfunction

function! md#core#raiseSectionBack()
  call s:moveSection("md#move#toParentHeading")
  call md#core#decHeading(1)
endfunction

function! md#core#raiseSectionForward()
  let before = md#mark#get('.')
  call md#core#raiseSectionBack()
  if md#mark#get('.') !=# before
    call md#core#moveSectionForward()
  endif
endfunction

function! md#core#nestSection()
  let storedRegister = @a
  try
    call md#move#ensureHeading()
    normal! yyPj
    call md#core#incHeading(1)
    exec 'normal! k"ad:call md#core#insideHeading()'
  finally
    let @a = storedRegister
  endtry
endfunction

" todo state cycling
if g:with_todo_features
  call md#todo#init()

  function! md#core#incTodo()
    let pos = getpos('.')
    try
      call md#move#ensureHeading()
      call md#todo#incTodoState('.')
    finally
      call setpos('.', pos)
    endtry
  endfunction

  function! md#core#decTodo()
    let pos = getpos('.')
    try
      call md#move#ensureHeading()
      call md#todo#decTodoState('.')
    finally
      call setpos('.', pos)
    endtry
  endfunction
endif
