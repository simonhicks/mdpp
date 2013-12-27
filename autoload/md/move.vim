function! md#move#upUntilLevel(target)
  let curr = md#line#num('.')
  while curr > 1 && md#line#isAtLeastLevel(curr - 1, a:target + 1)
    normal! k
    let curr = md#line#num('.')
  endwhile
endfunction

function! md#move#downUntilLevel(target)
  let curr = md#line#num('.')
  let last = md#line#num('$')
  while (curr != last) && md#line#isAtLeastLevel(curr + 1, a:target + 1)
    normal! j
    let curr = md#line#num('.')
  endwhile
endfunction

function! md#move#upToLevel(target)
  let start = getpos('.')
  try
    call md#move#upUntilLevel(a:target)
    normal! k
    if md#line#isHeading('.')
      normal! 0
      return md#line#num('.')
    else
      call setpos('.', start)
      return -1
    endif
  catch
    call setpos('.', start)
  endtry
endfunction

function! md#move#downToLevel(target)
  let start = getpos('.')
  try
    call md#move#downUntilLevel(a:target)
    normal! j
    if md#line#isHeading('.')
      normal! 0
      return md#line#num('.')
    else
      call setpos('.', start)
      return -1
    endif
  catch
    call setpos('.', start)
  endtry
endfunction

function! md#move#toNextHeading()
  return md#move#downToLevel(10000)
endfunction

function! md#move#toPreviousHeading()
  return md#move#upToLevel(10000)
endfunction

function! md#move#toPreviousSibling()
  return md#move#upToLevel(md#line#sectionLevel('.'))
endfunction

function! md#move#toNextSibling()
  return md#move#downToLevel(md#line#sectionLevel('.'))
endfunction

function! md#move#toParentHeading()
  if !md#line#sectionLevel('.')
    return
  elseif md#line#isHeading('.') && col('.') != 1
    normal! 0
    return md#line#num('.')
  elseif md#line#isHeading('.')
    return md#move#upToLevel(md#line#headingLevel('.') - 1)
  else
    return md#move#toPreviousHeading()
  endif
endfunction

function! md#move#ensureHeading()
  if !md#line#isHeading('.')
    call md#move#toParentHeading()
  endif
endfunction

function! md#move#toRootHeading()
  if !md#line#sectionLevel('.')
    return
  else
    return md#move#upToLevel(1)
  endif
endfunction

function! md#move#toFirstChildHeading()
  return md#move#downToLevel(md#line#sectionLevel('.') + 1)
endfunction
