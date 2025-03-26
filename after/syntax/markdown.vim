syn case match
if exists("g:with_todo_features") && g:with_todo_features
  call md#todo#setupColors()
endif

syn region markdownHeadingMetadata start="{" end="}" containedin=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6 oneline contained

hi def link markdownHeadingMetadata Comment
