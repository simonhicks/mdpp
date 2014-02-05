function! md#file#lines(file)
  let lines = []
  if filereadable(a:file)
    let lines = readfile(a:file)
  endif
  return lines
endfunction

function! s:addTodoState(heading)
  let content = a:heading.content
  let a:heading['state'] = md#str#getTodoState(content)
  let a:heading.content = substitute(content, "^" . a:heading.state . "\\s*", '', '')
endfunction

function! s:parseLevel(line, nextLine)
  let level = 0
  if len(md#str#headingPrefix(a:line))
    let level = len(md#str#trim(md#str#headingPrefix(a:line)))
  elseif match(a:nextLine, "^=\\+$") != -1
    let level = 1
  elseif match(a:nextLine, "^-\\+$") != -1
    let level = 2
  endif
  return level
endfunction

function! s:parseMetaItem(item)
  let data = []
  if match(a:item, '\..*') != -1
    let data = ['class', a:item[1:]]
  elseif match(a:item, '#.*') != -1
    let data = ['identifier', a:item[1:]]
  else
    let data = split(a:item, "=")
  endif
  return data
endfunction

function! s:addMeta(meta, type, data)
  if a:type ==# 'class'
    if has_key(a:meta, 'class')
      call add(a:meta.class, a:data)
    else
      let a:meta['class'] = [a:data]
    endif
  else
    let a:meta[a:type] = a:data
  endif
endfunction

function! s:parseMetaData(line)
  let metaString = matchstr(a:line, '{.*}\s*$')
  let meta = {}
  if len(metaString) > 0
    for metaItem in split(metaString[1:-2], '[[:space:]]\+')
      let parts = s:parseMetaItem(metaItem)
      call s:addMeta(meta, parts[0], parts[1])
    endfor
  endif
  return meta
endfunction

function! s:ensureIdentifier(heading)
  if !has_key(a:heading.meta, 'identifier')
    " TODO NON TRIVIAL LOGIC HERE!!!
    "      extract the auto-gen heading identifier... probably best to do it
    "      in str and call out to it from here (and line)
    " TODO add identifier to heading.meta['identifier']
  endif
endfunction

function! s:parseHeading(line, nextLine)
  let obj = {}
  let level = s:parseLevel(a:line, a:nextLine)
  if level > 0
    let content = md#str#headingContent(a:line)
    let meta = s:parseMetaData(a:line)
    let obj = {'type': 'heading', 'level': level, 'content': content, 'index': [], 'meta': meta}
    call s:ensureIdentifier(obj)
    if g:with_todo_features && len(obj) > 0
      call s:addTodoState(obj)
    endif
  endif
  return obj
endfunction

function! s:headings(file)
  let lines = md#file#lines(a:file)
  let headings = []
  let lnum = 0
  let max = len(lines) - 1
  while lnum <= max
    let nextLine = (lnum < max) && (len(lines) > 0) ? lines[lnum + 1] : ''
    let heading = s:parseHeading(lines[lnum], md#str#trim(nextLine))
    let heading['location'] = a:file
    if len(heading)
      call add(headings, heading)
    endif
    let lnum = lnum + 1
  endwhile
  return headings
endfunction

function! s:addBranch(structure, branch)
  if len(a:structure) > 0
    let lastNode = a:structure[-1]
    let currentLevel = lastNode.level
    if a:branch.level ==# currentLevel
      call add(a:structure, a:branch)
    else
      call s:addBranch(lastNode.index, a:branch)
    endif
  else
    call add(a:structure, a:branch)
  endif
endfunction

function! md#file#fileIndex(file)
  let fullIndex = !(a:0 && a:1)
  let structure = []
  for heading in s:headings(a:file)
    call s:addBranch(structure, heading)
  endfor
  return structure
endfunction

if exists("g:mdpp_path")
  function! s:fileList(folderPath)
    let files = globpath(a:folderPath, "*.md")
    return split(files, "\n")
  endfunction

  function! s:createFileItem(filePath, eager)
    let item = {'path': a:filePath, 'type': 'file'}
    if a:eager
      let item['index'] = md#file#fileIndex(a:filePath)
    endif
    return item
  endfunction

  function! md#file#folderIndex(folderPath, eager)
    let folderIndex = []
    for filePath in s:fileList(a:folderPath)
      call add(folderIndex, s:createFileItem(filePath, a:eager))
    endfor
    return folderIndex
  endfunction

  function! s:createFolderItem(folderPath, eager)
    let item = {'path': a:folderPath, 'type': 'folder'}
    if a:eager
      let item['index'] = md#file#folderIndex(a:folderPath, a:eager)
    endif
    return item
  endfunction

  function! md#file#fullIndex(eager)
    let fullIndex = []
    for folderPath in g:mdpp_path
      call add(fullIndex, s:createFolderItem(folderPath, a:eager))
    endfor
    return fullIndex
  endfunction
endif
