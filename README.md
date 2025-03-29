# lifter
Lifts a compile-time object instance to AST

## Example
```nim
type
  SomeType = object
    name: string
    value: string

import pkg/lifter
genLift(Type)  # allows lifting


macro someMacro(): untyped =
  let compileTimeType = SomeType(name: "Hello", value: "World")

  result = compileTimeType.lift()  # lifts here


let someType = someMacro()
echo someType
```

### Future
 - Reverse lifting
