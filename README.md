# lifter

Converts compile-time type instances to their Nim literal constructor syntax for macro code generation.

## Example
```nim
type Person = object
  name: string
  age: int

import pkg/lifter

macro buildPerson(): untyped =
  # Create an instance at compile-time
  let someone = Person(name: "Alice", age: 30)
  # Convert it to AST syntax: Person(name: "Alice", age: 30)
  result = someone.lift()

let alice = buildPerson()
echo alice  # Person(name: "Alice", age: 30)
```

## What it does

Takes a type instance that exists at compile-time (in a macro) and generates the Nim source code needed to construct it. This is useful for:

- Embedding compile-time computed values into generated code
- Code generation from configuration objects
- Macro-based serialization/deserialization

## API
```nim
proc toNimLiteral*[T](x: T): string
  # Converts a value to its Nim literal string representation
  # Example: Point(x: 10, y: 20) -> "Point(x: 10, y: 20)"

proc lift*[T](item: T): NimNode
  # Converts a value directly to a NimNode
  # Equivalent to: parseExpr(item.toNimLiteral)
```

**No macro invocation needed!** Just call `lift()` or `toNimLiteral()` directly on any type.

## Supported Types

- ✅ Objects, ref objects, ptr objects
- ✅ Strings (with proper escaping)
- ✅ Sequences
- ✅ Primitives (int, float, bool, etc.)
- ❌ NimNode (raises ValueError)

## Roadmap

- [ ] Support for tables/sets
- [ ] Support for tuples
- [ ] Reverse lifting (AST → object instances)
- [ ] Custom serialization hooks