local M = {}

function M.parse(input)
  local words = {}
  local current = {}
  local quote = nil
  local escaped = false
  local word_started = false

  local function push_word()
    if word_started then
      words[#words + 1] = table.concat(current)
      current = {}
      word_started = false
    end
  end

  for i = 1, #input do
    local char = input:sub(i, i)

    if escaped then
      current[#current + 1] = char
      escaped = false
      word_started = true
    elseif char == "\\" and quote ~= "'" then
      escaped = true
      word_started = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        current[#current + 1] = char
      end
      word_started = true
    elseif char == "'" or char == '"' then
      quote = char
      word_started = true
    elseif char:match("%s") then
      push_word()
    else
      current[#current + 1] = char
      word_started = true
    end
  end

  if escaped then
    current[#current + 1] = "\\"
  end
  if quote then
    return nil, "Unclosed quote"
  end

  push_word()
  return words
end

return M
