import macros
import strutils

macro genLift*(T: typedesc): untyped =
  result = quote do:
    proc fullRepr*[T](x: T): string =
      raise newException(ValueError, "Missing `genLift(" & $T & ")` macro call.")
    
    proc fullRepr*(x: `T`): string =
      proc doRepr(x: auto): string =
        when x is NimNode:
          raise newException(ValueError, "Cannot lift NimNode, use `pkg/jsony_plus/serialized_node` to serialize.")

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
          return "\"" & x.replace("\\", "\\\\").replace("\n", "\\n").replace("\"", "\\\"") & "\""
          
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



# import pkg/jsony_plus/serialized_node

# type Obj = object
#   name: string
#   node: NimNode

# genLift(Obj)
# genLift(SerializedNode)

# macro test(): untyped =

#   let node = quote do:
#     var test = "testing!"

#   # echo node.toSerializedNode()

#   result = lift(Obj(name: "test", node: node))

# let testing = test()