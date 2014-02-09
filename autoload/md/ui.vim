if !exists("g:mdpp_sidebar_width")
  let g:mdpp_sidebar_width = 40
endif

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

" TODO add default text to top of screen (title, instructions, etc.)
function! md#ui#setBufferContent(content)
  setlocal modifiable
  setlocal noreadonly
  execute 'normal! ggdG'
  call append(1, split(a:content, "\n"))
  execute "normal! dd"
  setlocal readonly
  setlocal nomodifiable
endfunction

" TODO add option for colorscheme
function! md#ui#initBuffer(name)
  let name = s:safeName(a:name)
  execute "vsplit " . name
  execute "normal! H"
  execute "vertical resize " . g:mdpp_sidebar_width
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal nomodifiable
  setlocal readonly
  setlocal cursorline
  setlocal nowrap
  setlocal nonumber
  let b:mdpp_ui_buffer = 1
  return name
endfunction

if exists("g:mdpp_path")
  function! s:flattenIndexList(tree)
    let items = []
    for item in a:tree
      call add(items, item)
      if has_key(item, 'index') && len(item['index']) !=# 0
        for nested in s:flattenIndexList(item['index'])
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
      let item['index'] = md#file#fileIndex(p, item.indexType)
    elseif item.type ==# 'folder'
      let item['index'] = md#file#folderIndex(p, 0, item.indexType)
    endif
  endfunction

  function! md#ui#foldItem(tree, num)
    let item = s:nthItem(a:tree, a:num)
    if has_key(item, 'index')
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

  function! s:currentItem()
    let num = line('.') - 1
    return s:nthItem(b:index, num)
  endfunction

  function! md#ui#toggleFold()
    let pos = getpos('.')
    let num = line('.') - 1
    let item = s:currentItem()
    if has_key(item, 'index')
      call md#ui#foldItem(b:index, num)
    else
      call md#ui#unfoldItem(b:index, num)
    endif
    call md#ui#setBufferContent(md#ui#stringify(b:index))
    call setpos('.', pos)
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
    if g:with_todo_features && has_key(a:item, 'state') && len(a:item['state']) > 0
      let content = content . ' [' . a:item['state'] . ']'
    endif
    if has_key(a:item, 'index') && len(a:item['index']) > 0
      return '- ' . content
    elseif has_key(a:item, 'folded') && len(a:item['folded']) > 0
      return '+ ' . content
    else
      return '- ' . content
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

  function! s:goTo(type, file, ident)
    if len(a:file)
      call md#move#toWin(g:mdpp_last_window)
      execute a:type . "Notes " . a:file
    endif
    " TODO go to appropriate ident
  endfunction

  function! md#ui#open(...)
    let type = a:0 ? a:1 : ''
    let item = s:currentItem()
    let targetFile = ''
    let targetIdent = ''
    if item.type ==# 'heading'
      let targetFile = item.location
      " let targetIdent = ... TODO
    elseif item.type ==# 'file'
      let targetFile = md#lookup#reverse(item.path)
    endif
    call s:goTo(type, targetFile, targetIdent)
  endfunction

  function! md#ui#openAndQuit(...)
    let bnum = bufnr("%")
    call md#ui#open(a:0 ? a:1 : '')
    execute "bw " . bnum
  endfunction

  function! md#ui#refreshIndexBuffer(...)
    let filter = a:0 ? a:1 : b:mdpp_ui_filter
    let indexType = a:0 ? a:2 : b:mdpp_index_buffer_type
    let b:index = md#file#index(filter, 0, indexType)
    call md#ui#setBufferContent(md#ui#stringify(b:index))
  endfunction

  function! md#ui#updateUiFilter(onUpdate, resetDefault)
    let b:mdpp_ui_filter = input("New Filter: ", b:mdpp_ui_filter, "customlist,md#lookup#autocomplete")
    execute "call " . a:onUpdate . "()"
    if resetDefault
      let g:mdpp_default_ui_filter = filter
    endif
  endfunction

  function! s:indexView(filter, indexType)
    let bname = md#ui#initBuffer(a:indexType)
    let bnum = bufnr(bname)
    call md#ui#refreshIndexBuffer(a:filter, a:indexType)
    let b:mdpp_ui_filter = a:filter
    let b:mdpp_index_buffer_type = a:indexType
    nnoremap <buffer> <CR> :call md#ui#toggleFold()<CR>
    nnoremap <buffer> o :call md#ui#open()<CR>
    nnoremap <buffer> v :call md#ui#open('V')<CR>
    nnoremap <buffer> t :call md#ui#open('T')<CR>
    nnoremap <buffer> s :call md#ui#open('H')<CR>
    nnoremap <buffer> r :call md#ui#refreshIndexBuffer()<CR>
    nnoremap <buffer> c :call md#ui#updateUiFilter("md#ui#refreshIndexBuffer", 0)<CR>
    nnoremap <buffer> C :call md#ui#updateUiFilter("md#ui#refreshIndexBuffer", 1)<CR>
    " TODO useful movement mappings (like (, ), [[, ]], etc.)
    " TODO ? mapping to show help
  endfunction

  function! s:stringifyTodo(item)
    return "[".a:item.state."]: ".a:item.content." (".a:item.location.")"
  endfunction

  function! s:stringifyList(list)
    let str = ''
    for item in a:list
      let str = str . s:stringifyTodo(item) . "\n"
    endfor
    return str
  endfunction

  function! md#ui#refreshTodoListBuffer(...)
    let filter = a:0 ? a:1 : b:mdpp_ui_filter
    let tree = md#file#index(filter, 1, 'todos')
    let list = s:flattenIndexList(tree)
    let b:index = filter(list, 'v:val.type ==# "heading"')
    call md#ui#setBufferContent(s:stringifyList(b:index))
  endfunction

  function! s:todoListView(filter)
    let bname = md#ui#initBuffer('todo-list')
    let bnum = bufnr(bname)
    call md#ui#refreshTodoListBuffer(a:filter)
    let b:mdpp_ui_filter = a:filter
    nnoremap <buffer> <CR> :call md#ui#openAndQuit()<CR>
    nnoremap <buffer> o :call md#ui#open()<CR>
    nnoremap <buffer> v :call md#ui#open('V')<CR>
    nnoremap <buffer> t :call md#ui#open('T')<CR>
    nnoremap <buffer> s :call md#ui#open('H')<CR>
    nnoremap <buffer> r :call md#ui#refreshTodoListBuffer()<CR>
    nnoremap <buffer> c :call md#ui#updateUiFilter("md#ui#refreshTodoListBuffer", 0)<CR>
    nnoremap <buffer> C :call md#ui#updateUiFilter("md#ui#refreshTodoListBuffer", 1)<CR>
    " TODO ? mapping to show help
  endfunction

  function! md#ui#updateLastWindow()
    if !exists("b:mdpp_ui_buffer")
      let g:mdpp_last_window = winnr()
    endif
  endfunction

  " @arg reset:     should I set this filter to be the default
  " @arg indexType: all headings or just todos?
  " @arg filter:    either <dirname>/<filename> or <dirname>
  function! md#ui#indexCommand(reset, indexType, ...)
    let str = a:0 ? a:1 : ''
    let filter = ''
    if len(str)
      let filter = str
    elseif exists("g:mdpp_default_ui_filter")
      let filter = g:mdpp_default_ui_filter
    else
      throw "Default filter not set. Define g:mdpp_default_ui_filter and try again."
    endif
    call s:indexView(filter, a:indexType)
    if len(filter) && (len(a:reset) || !exists("g:mdpp_default_ui_filter"))
      let g:mdpp_default_ui_filter = filter
    endif
  endfunction

  " @arg reset:     should I set this filter to be the default
  " @arg filter:    either <dirname>/<filename> or <dirname>
  function! md#ui#todoCommand(reset, ...)
    let str = a:0 ? a:1 : ''
    let filter = ''
    if len(str)
      let filter = str
    elseif exists("g:mdpp_default_ui_filter")
      let filter = g:mdpp_default_ui_filter
    else
      throw "Default filter not set. Define g:mdpp_default_ui_filter and try again."
    endif
    call s:todoListView(filter)
    if len(filter) && (len(a:reset) || !exists("g:mdpp_default_ui_filter"))
      let g:mdpp_default_ui_filter = filter
    endif
  endfunction

  " keep track of the last window we were in, so we know where to open files
  " from the ui windows
  au! WinLeave * call md#ui#updateLastWindow()
endif
