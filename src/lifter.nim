import macros

macro genLift*(T: typedesc): untyped =
  result = quote do:
    proc fullRepr*(x: `T`): string =
      proc doRepr(x: auto): string =
        when x is object:
          let typeName = $type(x)
          var res = typeName & "("
          var first = true
          for name, value in fieldPairs(x):
            if not first: res.add(", ")
            first = false
            res.add(name & ": ")
            res.add(doRepr(value))
          res.add(")")
          return res
          
        elif x is string:
          return "\"" & x & "\""
          
        elif x is seq:
          var res = "@["
          for i, item in x:
            if i > 0: res.add(", ")
            res.add(doRepr(item))
          res.add("]")
          return res
          
        else:
          return $x
          
      return doRepr(x)

proc lift*[T](item: T): NimNode =
  return parseExpr(item.fullRepr)