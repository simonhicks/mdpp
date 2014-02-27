function! md#str#isBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunction

function! md#str#trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunction

function! md#str#headingContent(heading)
  return substitute(a:heading, "^#* *", "", "")
endfunction

function! md#str#headingPrefix(heading)
  return matchstr(a:heading, "^#* *")
endfunction

" assumes a:str is only one line
function! md#str#indent(str, n)
  let counter = a:n
  let str = a:str
  while counter
    let str = ' ' . str
    let counter = counter - 1
  endwhile
  return str
endfunction

if g:with_todo_features
  call md#todo#init()

  function! md#str#getTodoState(str)
    let str = md#str#headingContent(a:str)
    let word = matchstr(str, "[^[:space:]]*")
    return index(g:mdpp_todo_states, word) != -1 ? word : ""
  endfunction

  function! md#str#setTodoState(str, state)
    let pattern = "^" . md#str#getTodoState(a:str) . " *"
    let replacement = md#str#isBlank(a:state) ? a:state : a:state . " "
    let content = md#str#headingContent(a:str)
    let content = substitute(content, pattern, replacement, "")
    return md#str#headingPrefix(a:str) . content
  endfunction
end

let s:not_escape = '\\\@<!'

function! s:removeWrapping(str, prefix, suffix)
  return substitute(a:str, s:not_escape . a:prefix . '\(.\{-\}\)' . s:not_escape . a:suffix, '\=submatch(1)', "g")
endfunction

function! s:removeStrong(str)
  return s:removeWrapping(s:removeWrapping(a:str, '\*\*', '\*\*'), '__', '__')
endfunction

function! s:removeEm(str)
  return s:removeWrapping(s:removeWrapping(a:str, '\*', '\*'), '_', '_')
endfunction

function! s:removeLinks(str)
  return s:removeWrapping(s:removeWrapping(a:str, '\[', '\]' . s:not_escape . '(.\{-\})'), '\[', '\]')
endfunction

function! s:removeStrikeout(str)
  return s:removeWrapping(a:str, '\~\~', '\~\~')
endfunction

function! s:removeSubscript(str)
  return s:removeWrapping(a:str, '\~', '\~')
endfunction

function! s:removeSuperscript(str)
  return s:removeWrapping(a:str, '\^', '\^')
endfunction

function! s:removeFormattingAndLinks(str)
  return s:removeSuperscript(s:removeSubscript(s:removeStrikeout(s:removeEm(s:removeStrong(s:removeLinks(a:str))))))
endfunction

function! md#str#identifier(header)
  " TODO remove all footnotes
  " remove all formatting and links
  " TODO remove all punctuation (except underscores, hyphens and periods)
  " TODO replace all spaces and newlines with hyphens
  " TODO downcase
  " TODO remove everything up to the first letter
  " TODO if nothing is left, use 'section'
endfunction

