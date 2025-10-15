## Lifter - Runtime to Compile-Time Value Conversion
## =================================================
## 
## This module provides utilities to convert runtime values into their Nim literal
## representations as strings, which can then be lifted into NimNodes for metaprogramming.
##
## Basic usage:
## 
## .. code-block:: nim
##   type Person = object
##     name: string
##     age: int
##   
##   let p = Person(name: "Alice", age: 30)
##   echo p.toNimLiteral()  # Person(name: "Alice", age: 30)
##   
##   # Use in macros:
##   let node = lift(p)  # Creates a NimNode representing the Person object

import macros
import strutils

proc toNimLiteral*[T](x: T): string =
  ## Converts a value to its Nim literal representation as a string.
  ## 
  ## This proc generates a string that represents the Nim source code needed
  ## to recreate the value. The output can be parsed back into a NimNode.
  ##
  ## Supported types:
  ## - Primitives (int, float, bool, etc.) - converted using `$`
  ## - Strings - properly escaped with quotes
  ## - Objects, ref objects, ptr objects - recursively serialized with field names
  ## - Sequences - serialized as `@[...]`
  ##
  ## Raises:
  ## - ValueError: if attempting to serialize a NimNode
  ##
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   type Point = object
  ##     x, y: int
  ##   
  ##   let p = Point(x: 10, y: 20)
  ##   assert p.toNimLiteral() == "Point(x: 10, y: 20)"
  
  proc doRepr(x: auto): string =
    # Guard against attempting to serialize NimNodes, which would cause issues
    when x is NimNode:
      raise newException(ValueError, 
        "Cannot lift NimNode, use `pkg/jsony_plus/serialized_node_macros2` to serialize.")

    # Handle object types (object, ref object, ptr object)
    when x is object or x is ref object or x is ptr object:
      # Dereference ref/ptr types to access the underlying object
      when x is ref object:
        let xx = x[]
      elif x is ptr object:
        let xx = x[]
      else:
        let xx = x

      # Extract the type name (before any ':' in the type string)
      let typeName = ($type(xx)).split(":")[0]
      var res = typeName & "("
      var first = true
      
      # Iterate through all fields and recursively serialize each one
      for name, value in fieldPairs(xx):
        if not first: res.add(", ")
        first = false
        res.add(name & ": ")
        res.add(doRepr(value))
      res.add(")")
      return res
      
    # Handle strings with proper escaping
    elif x is string:
      return "\"" & x.replace("\\", "\\\\")
                     .replace("\n", "\\n")
                     .replace("\"", "\\\"") & "\""
      
    # Handle sequences recursively
    elif x is seq:
      var res = "@["
      for i, item in x:
        if i > 0: res.add(", ")
        res.add(doRepr(item))
      res.add("]")
      return res
      
    # Fallback for primitives and other types that implement `$`
    else:
      return $x
      
  return doRepr(x)

proc lift*[T](item: T): NimNode =
  ## Lifts a runtime value into a NimNode by converting it to Nim literal syntax
  ## and parsing it as an expression.
  ##
  ## This is useful in macros when you want to embed runtime-computed values as
  ## compile-time AST nodes.
  ##
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   macro embedValue(x: typed): untyped =
  ##     let runtimeVal = SomeObject(field: "value")
  ##     result = quote do:
  ##       let embedded = `lift(runtimeVal)`
  ##
  ## Returns:
  ##   A NimNode representing the literal expression of the value
  
  let nimLiteral = item.toNimLiteral
  return parseExpr(nimLiteral)


# when isMainModule:
#   import css

#   macro test(): untyped =
#     result = newStmtList()

#     let node = WrittenDocumentNode(
#       stack: "aStack",
#       selector: "aSelector",
#       kind: cssikPROPERTY,
#       property: WrittenProperty(
#         name: "aProperty",
#         body: WrittenPropertyBody(
#           kind: pkPURE,
#           value: "aValue"
#         )
#       )
#     )

#     echo node.toNimLiteral()
#     let astNode = lift(node)
#     echo astNode.repr

#   test