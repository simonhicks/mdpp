if !exists("g:with_todo_features")
  let g:with_todo_features = 1
endif

if exists("g:mdpp_path") && len(g:mdpp_path)
  if !exists("g:mdpp_create_if_not_found")
    let g:mdpp_create_if_not_found = 1
  endif
  if !exists("g:mdpp_default_create_dir")
    let g:mdpp_default_create_dir = g:mdpp_path[0]
  endif

  function! s:resolveFile(name)
    for directory in g:mdpp_path
      let directory = fnamemodify(directory, ":p")
      if isdirectory(directory)
        let path = fnamemodify(directory . a:name . ".md", ":p")
        if filereadable(path)
          return path
        endif
      endif
    endfor
    if g:mdpp_create_if_not_found
      return fnamemodify(g:mdpp_default_create_dir . "/" . a:name . ".md", ":p")
    else
      return ""
    endif
  endfunction

  function! s:openFile(splitType, path)
    let splitType = a:splitType

    " open in a split if buffer is modified and hidden buffers aren't allowed
    if !splitType && !&hidden && &modified
      echom "setting splitType to 'split'"
      let splitType = 'split'
    endif

    let notesBufferNum = bufnr(a:path)
    if notesBufferNum ==# -1
      " open a new buffer if it doesn't already exist
      if (splitType == 'split')
        let command = "new " . a:path
      elseif (splitType == 'vert')
        let command = "vert new " . a:path
      elseif (splitType == 'tab')
        let command = "tabnew " . a:path
      else
        let command = "edit " . a:path
      endif
    else
      " scratch notes buffer already exists... open it
      if (splitType == 'split')
        let command = "split +buffer" . notesBufferNum
      elseif (splitType == 'vert')
        let command = "vert split +buffer" . notesBufferNum
      elseif (splitType == 'tab')
        let command = "tab sb " . notesBufferNum
      else
        let command = "buffer " . notesBufferNum
      endif
    endif 

    execute command
  endfunction

  " @arg splitType: where to open the file
  " @arg reset:     should I set this file to be the default
  " @arg name:      what's the name of the file
  function! s:notesCommand(reset, splitType, ...)
    let name = a:0 ? a:1 : ''
    if len(name)
      let path = s:resolveFile(name)
      if len(path)
        call s:openFile(a:splitType, path)
      else
        throw "Couldn't find notes file matching '" . name . "'"
      endif
    elseif exists("g:mdpp_default_file")
      call s:openFile(a:splitType, fnamemodify(g:mdpp_default_file, ":p"))
    else
      throw "Default file name not set. Define g:mdpp_default_file and try again."
    endif
    if len(a:reset) || !exists("g:mdpp_default_file")
      let g:mdpp_default_file = path
    endif
  endfunction

  " function! AutocompleteOptions
  " endfunction

  command! -nargs=* -bang Motes call s:notesCommand(<q-bang>, '', <f-args>)
  command! -nargs=* -bang HMotes call s:notesCommand(<q-bang>, 'split', <f-args>)
  command! -nargs=* -bang VMotes call s:notesCommand(<q-bang>, 'vert', <f-args>)
  command! -nargs=* -bang TMotes call s:notesCommand(<q-bang>, 'tab', <f-args>)
endif
