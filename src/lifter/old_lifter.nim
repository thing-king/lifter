import macros
import strutils, typetraits

type
  # aString = range[0..255]
  anInt = int
  anotherString = string
  aString = seq[anotherString]
  Kind = enum
    kA, kB
  # ACaseType = object
  #   case kind*: Kind
  #   of kA:
  #     a*: int
  #   of kB:
  #     b*: int
  # ANormalobject = object
  #   a*: int
  #   b*: int

proc liftNimNode(node: NimNode): NimNode =
  # echo "Lifting"
  # echo node.treeRepr

  let kind = node.kind
  if node.len != 0:
    result = nnkCall.newTree(
      nnkDotExpr.newTree(
        ident($kind),
        ident("newTree"),
      ),
    )
    for child in node:
      result.add(liftNimNode(child))
  else:
    case kind:
    of nnkIdent:
      result = nnkCall.newTree(
        ident("ident"),
        newStrLitNode(node.strVal)
      )
    of nnkIntLit:
      result = nnkCall.newTree(
        ident("newIntLitNode"),
        newIntLitNode(node.intVal)
      )
    of nnkFloatLit:
      result = nnkCall.newTree(
        ident("newFloatLitNode"),
        newFloatLitNode(node.floatVal)
      )
    of nnkStrLit:
      result = nnkCall.newTree(
        ident("newStrLitNode"),
        newStrLitNode(node.strVal)
      )
    of nnkSym:
      result = nnkCall.newTree(
        ident("ident"),
        newStrLitNode(node.strVal)
      )
    else:
      result = kind.newNimNode()
  
  # echo "Lifted"
  # echo result.treeRepr

proc liftString*(str: string): NimNode =
  result = newStrLitNode(str)
proc liftInt*(i: int): NimNode =
  result = newIntLitNode(i)
proc liftFloat*(f: float): NimNode =
  result = newFloatLitNode(f)
proc liftBool*(b: bool): NimNode =
  result = ident($b)


macro genLifter*(T: typedesc): untyped =
  ## Generates a custom lifter procedure for a specific type
  let typeName = T.getTypeImpl[1].repr
  let procName = newIdentNode("lift" & typeName)
  echo "HERE:::::"
  echo T.getTypeImpl[1].getTypeImpl.treeRepr
  let typeNode = T.getTypeImpl[1].getTypeImpl

  let resultNode = ident("result")
  let x          = ident("x")
  let body       = nnkStmtList.newNimNode()

  echo "Node"
  echo typeNode.treeRepr

  if typeNode.kind == nnkEnumTy:
    body.add quote do:
      `resultNode` = nnkCall.newTree(
        ident(`typeName`)
      )
    let enumNodes = typeNode[1..^1]
    for enumNode in enumNodes:
      let enumName = enumNode.strVal
      body.add quote do:
        if `x` == `enumNode`:
          `resultNode`.add ident(`enumName`)
  else:
    let kind = typeNode

    # echo "KIND : " & kind.repr
    var kindStr = kind.repr.replace("[", "").replace("]", "")
    kindStr = kindStr[0].toUpperAscii & kindStr[1..^1]
    echo "KIND: " & kindStr

    var lifted = liftNimNode(
      nnkCall.newTree(
        kind,
        # liftNimNode(x)
        # nnkCall.newTree(
        #   ident("newStrLitNode"),
        #   x
        # )
        # nnkCall.newTree(
        #   ident("newIntLitNode"),
        #   x
        # )
      )
    )
    
    # echo "HERE!:!:!:!"
    # echo x.getTypeImpl().treeRepr

    

    lifted.add nnkCall.newTree(ident("lift" & kindStr), x)
    
    
    # lifted.add nnkCall.newTree(ident("lift" & kindStr), x)

    # lifted.add nnkCall.newTree(
    #   ident("newStrLitNode"),
    #   x
    # )
    # lifted.add quote do:
      # newStrLitNode(`x`)

    # lifted.add liftNimNode(x)
    # echo "LIFTED::"
    # echo lifted.treeRepr
    # lifted[2][2] = x



    # echo "LIFTED"
    # echo lifted.liftNimNode().repr

    # echo "HERE!"

    body.add quote do:
      `resultNode` = nnkCall.newTree(
        ident(`typeName`),
        # `lifted`
      )
    body.add nnkCall.newTree(
      nnkDotExpr.newTree(
        resultNode,
        ident("add")
      ),
      lifted
    )
  echo "DONE"
  echo body.repr

  result = quote do:
    proc `procName`(`x`: `T`): NimNode =
      # `resultNode` = nnkObjConstr.newTree(
      #   ident(`typeName`)
      # )
      # let xx = `x`


      # result = newIntLitNode(`x`)
      `body`

      # result = nnkCall.newTree(ident("aString"))
      # result.add(nnkCall.newTree(nnkBracketExpr.newTree(ident("seq"),
      #     ident("anotherString")),
          
      #     ))

      # result = nnkCall.newTree(ident("anotherString"))
      # result.add(nnkCall.newTree(ident("string"), liftString(`x`)))

      # result.add(nnkCall.newTree(ident("string"),
      #   nnkCall.newTree(
      #     ident("newStrLitNode"),
      #     newStrLitNode(`x`)
      #   )
      # ))
      # `resultNode` = nnkCall.newTree(ident("anotherString"))
      # `resultNode`.add(ident("string")(x))

      # `resultNode` = nnkCall.newTree(ident("aString"))
      # `resultNode`.add(nnkBracketExpr.newTree(ident("seq"), ident("anotherString"))(x))

      echo "Constructed"
      echo `resultNode`.treeRepr
      
      # # Add all fields using runtime introspection
      # for name, value in fieldPairs(x):
      #   echo name, value
      #   # let valueImpl = value.getTypeImpl
      #   # echo value.getType

      #   when name == "kind" and compiles(ord(value)):
      #     # Handle enum kind field specially
      #     let kindVal = ord(value)
      #     result.add(
      #       nnkExprColonExpr.newTree(
      #         newIdentNode(name),
      #         newLit(kindVal)
      #       )
      #     )
      #   else:
      #     # Handle regular fields
      #     when compiles(newLit(value)):
      #       result.add(
      #         nnkExprColonExpr.newTree(
      #           newIdentNode(name),
      #           newLit(value)
      #         )
      #       )
      
# Usage example:
# genLifter(aString)
genLifter(seq[anotherString])
# genLifter(anotherString)
# genLifter(anInt)
# genLifter(Kind)





macro test(): untyped =
  # let a = ACaseType(kind: kA, a: 1)
  # result = liftACaseType(a)
  # let k = Kind(kB)
  # result = liftKind(k)

  # let s = aString(@["testing!"])
  # let outs = liftaString(s)
  # let s = anotherString("testing!")
  # let outs = liftanotherString("testing")

  result = liftaString(aString(@["testing!"]))

  # echo outs.treeRepr
  # result = liftaString(s)


let te = test()
echo te


# macro test(): untyped =
#   echo liftNimNode(
#     nnkBracketExpr.newTree(
#       ident("range"),
#       nnkInfix.newTree(
#         ident(".."),
#         newIntLitNode(0),
#         newIntLitNode(255)
#       )
#     )
#     # nnkInfix.newTree(
#     #   ident(".."),
#     #   newIntLitNode(0),
#     #   newIntLitNode(255)
#     # )
#   ).repr
# test

# dumpTree:
  # nnkInfix.newTree("..", newIntLitNode(0), newIntLitNode(255))




# macro liftTest(body: untyped): untyped =

#   # let node = nnkCall.newTree(
#   #   nnkBracketExpr.newTree(
#   #     ident("range"),
#   #     nnkInfix.newTree(
#   #       ident(".."),
#   #       newIntLitNode(0),
#   #       newIntLitNode(255)
#   #     )
#   #   ),
#   #   newIntLitNode(5)
#   # )

#   result = liftNimNode(body)
#   # result = liftedNode


# let val = liftTest(25)