"" stuff for handling the opening and creation of md files within g:mdpp_path

function! s:resolveFileInDir(dir, name)
  let path = fnamemodify(a:dir . a:name . ".md", ":p")
  if filereadable(path)
    return path
  else
    return ""
  endif
endfunction

function! s:resolveFile(name)
  for directory in g:mdpp_path
    let dir = fnamemodify(directory, ":p")
    let path = s:resolveFileInDir(dir, a:name)
    if len(path)
      return path
    endif
  endfor
  return ""
endfunction

function! s:resolveDir(dir)
  for directory in g:mdpp_path
    if a:dir ==# fnamemodify(directory, ":t")
      return fnamemodify(directory, ":p")
    endif
  endfor
  return ''
endfunction

function! s:resolve(dir, name)
  if len(a:dir)
    let dir = s:resolveDir(a:dir)
    if isdirectory(dir)
      let path = s:resolveFileInDir(dir, a:name)
    else
      throw "Directory '" . a:dir . "' not found."
    endif
  else
    let path = s:resolveFile(a:name)
  endif
  return path
endfunction

function! s:newFilePath(dir, name)
  let path = ""
  if g:mdpp_create_if_not_found
    let dir = len(a:dir) ? a:dir : g:mdpp_default_create_dir
    let path = fnamemodify(dir . "/" . a:name . ".md", ":p")
  endif
  return path
endfunction

function! s:parseString(str)
  let parts = []
  if match(a:str, "/") != -1
    let parts = split(a:str, "/")
  else
    let parts = ['', a:str]
  endif
  return parts
endfunction

function! s:expandString(str)
  let parts = s:parseString(a:str)
  if len(parts) ==# 2
    let path = s:resolve(parts[0], parts[1])
    if len(path)
      return path
    else
      return s:newFilePath(parts[0], parts[1])
    endif
  else
    throw "Invalid file reference '" . a:str . "'"
  endif
endfunction

function! s:newBufferCommand(splitType, path)
  if (a:splitType == 'split')
    return "new " . a:path
  elseif (a:splitType == 'vert')
    return "vert new " . a:path
  elseif (a:splitType == 'tab')
    return "tabnew " . a:path
  else
    return "edit " . a:path
  endif
endfunction

function! s:existingBufferCommand(splitType, notesBufferNum)
  if (a:splitType == 'split')
    return "split +buffer" . a:notesBufferNum
  elseif (a:splitType == 'vert')
    return "vert split +buffer" . a:notesBufferNum
  elseif (a:splitType == 'tab')
    return "tab sb " . a:notesBufferNum
  else
    return "buffer " . a:notesBufferNum
  endif
endfunction

function! s:openFile(splitType, path)
  let splitType = a:splitType

  if !splitType && !&hidden && &modified
    echom "setting splitType to 'split'"
    let splitType = 'split'
  endif

  let notesBufferNum = bufnr(a:path)
  if notesBufferNum ==# -1
    let command = s:newBufferCommand(splitType, a:path)
  else
    let command = s:existingBufferCommand(splitType, notesBufferNum)
  endif 

  execute command
endfunction

function! s:findAndOpen(splitType, str)
  let path = s:expandString(a:str)
  if len(path)
    call s:openFile(a:splitType, path)
  else
    throw "Couldn't find notes file matching '" . str . "'"
  endif
endfunction

" @arg splitType: where to open the file
" @arg reset:     should I set this file to be the default
" @arg str:       either <dirname>/<filename> or <filename>
function! md#lookup#notesCommand(reset, splitType, ...)
  let str = a:0 ? a:1 : ''
  if len(str)
    call s:findAndOpen(a:splitType, a:str)
  elseif exists("g:mdpp_default_file")
    call s:openFile(a:splitType, fnamemodify(g:mdpp_default_file, ":p"))
  else
    throw "Default file name not set. Define g:mdpp_default_file and try again."
  endif
  if len(a:reset) || !exists("g:mdpp_default_file")
    let g:mdpp_default_file = path
  endif
endfunction

" tab complete for Notes commands

function! s:directoryOptions(str)
  let opts = []
  for directory in g:mdpp_path
    let dir = fnamemodify(directory, ":t")
    if match(dir, "^" . a:str) != -1
      call add(opts, fnamemodify(directory, ":p"))
    endif
  endfor
  return opts
endfunction

function! s:autocompleteFileInPath(file, path)
  let opts = []
  for directory in a:path
    let directory = fnamemodify(directory, ":p")
    for fname in split(system("ls " . shellescape(directory)), "\n")
      echom fname
      if match(fname, "^" . a:file) != -1 && match(fname, "\.md$") != -1
        call add(opts, fnamemodify(directory . fname, ":p"))
      end
    endfor
  endfor
  return opts
endfunction

function! s:autocompletePair(dir, file)
  let dirs = s:directoryOptions(a:dir)
  if len(a:file)
    return s:autocompleteFileInPath(a:file, dirs)
  else
    return dirs
  endif
endfunction

function! s:autocompleteSingle(str)
  let opts = s:directoryOptions(a:str)
  for fname in s:autocompleteFileInPath(a:str, g:mdpp_path)
    call add(opts, fname)
  endfor
  return opts
endfunction

function! s:autocompleteOptions(str)
  if match(a:str, "/") != -1
    let parts = s:parseString(a:str)
    let dir = parts[0]
    let file = ''
    if len(parts) == 2
      let file = parts[1]
    endif
    return s:autocompletePair(dir, file)
  elseif len(a:str)
    return s:autocompleteSingle(a:str)
  else
    let opts = []
    for dir in g:mdpp_path
      call add(opts, fnamemodify(dir, ":p"))
    endfor
    return opts
  endif
endfunction

function! md#lookup#autocomplete(argLead, cmdLine, cursorPos)
  let fullPaths = s:autocompleteOptions(a:argLead)
  let opts = []
  for path in fullPaths
    let fname = substitute(fnamemodify(path, ":t"), "\.md$", "", "")
    let dir = fnamemodify(path, ":h")
    let dirname = fnamemodify(dir, ":t")
    call add(opts, dirname . "/" . fname)
  endfor
  return opts
endfunction
