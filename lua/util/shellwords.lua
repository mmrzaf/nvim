local M = {}

local double_quote_escapes = {
  ['"'] = true,
  ["\\"] = true,
  ["$"] = true,
  ["`"] = true,
}

function M.parse(input)
  local words = {}
  local current = {}
  local quote = nil
  local word_started = false
  local index = 1

  local function push_word()
    if word_started then
      words[#words + 1] = table.concat(current)
      current = {}
      word_started = false
    end
  end

  while index <= #input do
    local char = input:sub(index, index)

    if quote == "'" then
      if char == "'" then
        quote = nil
      else
        current[#current + 1] = char
      end
      word_started = true
    elseif quote == '"' then
      if char == '"' then
        quote = nil
      elseif char == "\\" then
        local next_char = input:sub(index + 1, index + 1)
        if next_char ~= "" and double_quote_escapes[next_char] then
          current[#current + 1] = next_char
          index = index + 1
        else
          current[#current + 1] = "\\"
        end
      else
        current[#current + 1] = char
      end
      word_started = true
    elseif char == "'" or char == '"' then
      quote = char
      word_started = true
    elseif char == "\\" then
      local next_char = input:sub(index + 1, index + 1)
      if next_char == "" then
        current[#current + 1] = "\\"
      else
        current[#current + 1] = next_char
        index = index + 1
      end
      word_started = true
    elseif char:match("%s") then
      push_word()
    else
      current[#current + 1] = char
      word_started = true
    end

    index = index + 1
  end

  if quote then
    return nil, "Unclosed quote"
  end

  push_word()
  return words
end

return M
