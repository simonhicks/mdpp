function! md#todo#init()
  if !exists("g:mdpp_todo_loaded")

    " apply default states
    if !exists("g:mdpp_todo_states")
      let g:mdpp_todo_states = [
            \"TODO",
            \"INPROGRESS",
            \"DONE"
            \]
    endif

    " apply default todo state coloring
    if !exists("g:mdpp_todo_colors")
      let g:mdpp_todo_colors = {
            \  "TODO": {
            \    "guifg": "#ff0000",
            \    "gui": "bold",
            \    "ctermfg": "red"
            \  },
            \  "DONE": {
            \    "guifg": "#00cf00",
            \    "gui": "bold",
            \    "ctermfg": "green"
            \  },
            \  "__default__": {
            \    "guifg": "#ffcf00",
            \    "gui": "bold",
            \    "ctermfg": "yellow"
            \  }
            \}
    endif

    let g:mdpp_todo_loaded = 1
  endif
endfunction

function! md#todo#getColors(state)
  if has_key(g:mdpp_todo_colors, a:state)
    return g:mdpp_todo_colors[a:state]
  else
    return g:mdpp_todo_colors["__default__"]
  endif
endfunction

function! s:highlight(state, obj)
  if index(s:colored_states, a:state) == -1
    let desc = ""
    for key in keys(a:obj)
      let desc = desc . " " . key . "=" . a:obj[key]
    endfor
    execute "highlight markdownState" . a:state . desc

    execute "syn keyword markdownState" . a:state . " " . a:state
          \." containedin=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6 contained"

    call add(s:colored_states, a:state)
  endif
endfunction

function! md#todo#setupColors()
  let s:colored_states = []
  for state in g:mdpp_todo_states
    call s:highlight(state, md#todo#getColors(state))
  endfor
  " handle other explicitly colored states
  for state in keys(g:mdpp_todo_colors)
    if state !=# "__default__"
      call s:highlight(state, md#todo#getColors(state))
    endif
  endfor
endfunction

call md#todo#init()

function! md#todo#next(state)
  let ind = index(g:mdpp_todo_states, a:state)
  let state = (ind + 1 == len(g:mdpp_todo_states) ? -1 : ind + 1)
  return state == -1 ? "" : g:mdpp_todo_states[state]
endfunction

function! md#todo#prev(state)
  let ind = index(g:mdpp_todo_states, a:state)
  let state = (ind == -1 ? len(g:mdpp_todo_states) - 1 : ind - 1)
  return state == -1 ? "" : g:mdpp_todo_states[state]
endfunction

function! md#todo#getTodoState(lnum)
  if md#line#isHeading(a:lnum)
    return md#str#getTodoState(getline(a:lnum))
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . " Can't get todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#setTodoState(lnum, state)
  if md#line#isHeading(a:lnum)
    let string = md#str#setTodoState(getline(a:lnum), a:state)
    call setline(a:lnum, string)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#incTodoState(lnum)
  if md#line#isHeading(a:lnum)
    let state = md#todo#next(md#todo#getTodoState(a:lnum))
    return md#todo#setTodoState(a:lnum, state)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#decTodoState(lnum)
  if md#line#isHeading(a:lnum)
    let state = md#todo#prev(md#todo#getTodoState(a:lnum))
    return md#todo#setTodoState(a:lnum, state)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction
