function! md#todo#highlight(state, obj)
  let desc = ""
  for key in keys(a:obj)
    let desc = desc . " " . key . "=" . a:obj[key]
  endfor
  execute "highlight markdownState" . a:state . desc

  execute "syn keyword markdownState" . a:state . " " . a:state
        \." containedin=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6 contained"
endfunction

function! md#todo#init()
  if !exists("g:mdpp_todo_loaded")

    if !exists("g:mdpp_todo_states")
      " default states
      let g:mdpp_todo_states = [
            \"TODO",
            \"INPROGRESS",
            \"DONE"
            \]
    endif

    if !exists("g:mdpp_todo_colors")
      " default colors
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

function! md#todo#setupColors()
  for state in g:mdpp_todo_states
    call md#todo#highlight(state, md#todo#getColors(state))
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
