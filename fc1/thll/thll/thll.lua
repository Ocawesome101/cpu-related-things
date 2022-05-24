-- CTL syntax definition

local syn = {
  whitespace = {
    {
      function(c)
        return c:match("[ \n\r\t]")
      end,
      function()
        return false
      end,
      function(c)
        return c:match("^[ \n\r\t]+")
      end
    }
  },
  word = {
    {
      function(c)
        return not not c:match("[a-zA-Z_]")
      end,
      function(_, c)
        return not not c:match("[a-zA-Z_0-9]")
      end
    }
  },
  keyword = {
    "fn", "var", "entrypoint",
  },
  types = {
    "void", "int",
  },
  separator = {
    ",", "(", ")", "{", "}", "[", "]", ";", ":", ".",
  },
  operator = {
    "+", "-", "/", "*", "==", ">>", "<<", ">", "<", "=", "&", "|", "^", "~",
    "!=",
  },
  comment = {
    {
      function(c)
        return c == "/"
      end,
      function(t,c)
        if t == "/" and c ~= "/" then return false end
        return c ~= "\n"
      end,
      function(t)
        return #t > 1
      end
    }
  },
  string = {
    {
      function(c)
        return c == '"' or c == "'"
      end,
      function(t)
        local first, last, penultimate = t:sub(1,1), t:sub(#t), t:sub(-2, -2)
        if #t == 1 then return true end
        if first == last and penultimate ~= "\\" then return false end
        return true
      end
    }
  },
  number = {
    {
      function(c)
        return not not tonumber(c)
      end,
      function(t, c)
        return not not tonumber(t .. c .. "0")
      end,
    }
  }
}

return syn
