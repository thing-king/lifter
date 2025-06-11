# lifter
Converts compile-time objects to AST constructor syntax for macro code generation.

## Example

```nim
type Person = object
  name: string
  age: int

import pkg/lifter
genLift(Person)  # enables lifting for Person type

macro buildPerson(): untyped =
  let someone = Person(name: "Alice", age: 30)
  result = someone.lift()  # becomes: Person(name: "Alice", age: 30)

let alice = buildPerson()
echo alice  # Person(name: "Alice", age: 30)
```

## Usage

```nim
genLift(MyType)        # exported fullRepr (for libraries)
genPrivateLift(MyType) # private fullRepr (for internal use)
```

## Roadmap

- Reverse lifting (AST → object instances)