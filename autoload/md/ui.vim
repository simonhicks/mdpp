function! s:number(name)
  let patt =  '_\(\d\d*\)$'
  if match(a:name, patt) != -1
    return matchlist(a:name, patt)[1]
  else
    return 0
  endif
endfunction

function! s:safeName(name)
  let safe = a:name
  while bufnr(safe) != -1
    let fnum = s:number(safe)
    if fnum
      let safe = substitute(safe, "_" . fnum . "$", "_" . (fnum + 1), "")
    else
      let safe = safe . "_1"
    endif
  endwhile
  return safe
endfunction

function! md#ui#setBufferContent(content)
  setlocal modifiable
  setlocal noreadonly
  execute 'normal! ggdG'
  call append(1, split(a:content, "\n"))
  execute "normal! dd"
  setlocal readonly
  setlocal nomodifiable
endfunction

function! md#ui#initBuffer(name)
  let name = s:safeName(a:name)
  execute "silent vert leftabove split " . name
  setlocal buftype=nofile
  setlocal hidden
  setlocal nomodifiable
  setlocal readonly
  setlocal cursorline
  return name
endfunction

if exists("g:mdpp_path")
  function! s:flattenIndexList(tree)
    let items = []
    for item in a:tree
      call add(items, item)
      if has_key(item, 'index') && len(item['index']) !=# 0
        for nested in md#ui#flattenIndexList(item['index'])
          call add(items, nested)
        endfor
      endif
    endfor
    return items
  endfunction

  function! s:nthItem(tree, num)
    return s:flattenIndexList(a:tree)[a:num]
  endfunction

  function! md#ui#realize(tree, num)
    let item = s:nthItem(a:tree, a:num)
    let p = item.path
    if item.type ==# 'file'
      let item['index'] = md#file#fileIndex(p)
    elseif item.type ==# 'folder'
      let item['index'] = md#file#folderIndex(p, 0)
    endif
  endfunction

  function! md#ui#foldItem(tree, num)
    let item = s:nthItem(a:tree, a:num)
    if has_key(item, 'folded')
      let item['folded'] = item['index']
      call remove(item, 'index')
    endif
  endfunction

  function! md#ui#unfoldItem(tree, num)
    let item = s:nthItem(a:tree, a:num)
    if has_key(item, 'folded')
      let item['index'] = item['folded']
      call remove(item, 'folded')
    elseif !has_key(item, 'index')
      call md#ui#realize(a:tree, a:num)
    endif
  endfunction

  function! s:stringifyFolder(item)
    let content = fnamemodify(a:item.path, ":t") . "/"
    if has_key(a:item, 'index')
      return '- ' . content
    else
      return '+ ' . content
    endif
  endfunction

  function! s:stringifyFile(item)
    let content = substitute(fnamemodify(a:item.path, ":t"), '.md$', '', '')
    if has_key(a:item, 'index')
      return '- ' . content
    else
      return '+ ' . content
    endif
  endfunction

  function! s:stringifyHeading(item)
    let content = a:item['content']
    if g:with_todo_features && has_key(a:item, 'state')
      let content = a:item['state'] . ': ' . content
    endif
    if has_key(a:item, 'index')
      return '- ' . content
    elseif has_key(a:item, 'folded')
      return '+ ' . content
    else
      return '  ' . content
    endif
  endfunction

  function! s:stringifyItem(item, indent)
    let type = a:item.type
    let str = md#str#indent('', a:indent)
    if type ==# 'heading'
      let str = str . s:stringifyHeading(a:item)
    elseif type ==# 'file'
      let str = str . s:stringifyFile(a:item)
    elseif type ==# 'folder'
      let str = str . s:stringifyFolder(a:item)
    endif
    if has_key(a:item, 'index')
      for nested in a:item['index']
        let str = str . "\n" . s:stringifyItem(nested, a:indent + 2)
      endfor
    endif
    return str
  endfunction

  function! md#ui#stringify(list)
    let str = ''
    for item in a:list
      let str = str . s:stringifyItem(item, 0) . "\n"
    endfor
    return str
  endfunction

  function! TestCode()
    let ind = md#file#fullIndex(0)
    call md#ui#unfoldItem(ind, 0)
    "" FIXME This should unfold the first file, but it only adds a bunch of
    ""       empty lines
    " call md#ui#unfoldItem(ind, 1)
    echo md#ui#stringify(ind)
  endfunction

  " function! md#ui#todoTree()
  " endfunction
endif
