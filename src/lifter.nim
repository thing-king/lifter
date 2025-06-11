import macros
import strutils


macro genLiftImpl*(T: typedesc, exported: static bool): untyped =
  let procName = if exported: nnkPostfix.newTree(ident("*"), ident("fullRepr")) else: ident("fullRepr")

  result = quote do:
    proc `procName`[T](x: T): string =
      raise newException(ValueError, "Missing `genLift(" & $T & ")` macro call.")
    
    proc `procName`(x: `T`): string =
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

macro genLift*(T: typedesc): untyped =
  # Call the implementation macro with the correct NimNode construction
  result = newCall(ident("genLiftImpl"), T, newLit(true))

macro genPrivateLift*(T: typedesc): untyped =
  # Call the implementation macro with the correct NimNode construction  
  result = newCall(ident("genLiftImpl"), T, newLit(false))

proc lift*[T](item: T): NimNode =
  return parseExpr(item.fullRepr)



# proc helloWorld*(): string =
#   "hello world 4"

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