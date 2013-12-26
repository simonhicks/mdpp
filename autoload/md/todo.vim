function! md#todo#init()
  if !exists("g:mdpp_todo_loaded")
    " default states
    let g:mdpp_todo_states = [
          \"TODO",
          \"STARTED",
          \"DONE"
          \]

    " TODO default colors

    let g:mdpp_todo_loaded = 1
  endif
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
