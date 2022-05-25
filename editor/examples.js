const HELLO_WORLD = `reuse [L42.is/AdamsTowel]

Main=(
  _=Log"".#$reader()

  Debug(S"Hello world from 42")
  )`;

function makeBasicSettings(mainPermission) {
  return `/*
  *** 42 settings ***
  You can change the stack and memory limitations and add security mappings
*/
maxStackSize = 1G
initialMemorySize = 256M
maxMemorySize = 2G

Main = [${mainPermission}]
`;
}

const LOGGER_SETTINGS = makeBasicSettings("L42.is/AdamsTowel/Log");

const POINT_SUM_METHOD = {
  "This.L42": {
    template: `reuse [L42.is/AdamsTowel]
Point = Data:{
  Num x
  Num y
  ???
}

Main=(
  _=Log"".#$reader()

  Debug(S"Hello world from 42!")

  imm Point p = (Point(x=5\\, y=2\\).sum(Point(x=3\\, y=1\\)))
  Debug(S"p = %p")
  )`,
    value: `// write a sum() method that returns the sum of two points
`,
  },
}

const PRINT_HELLO_WORLD_CHALLENGE = {
    "This.L42": {
  template: `reuse [L42.is/AdamsTowel]

Code = {
???
}

Main=(
  _=Log"".#$reader()

  Debug(Code.hello())
  )`,
  value: `class method S hello() = {
  return S"Hello world from 42"
}
`},
};

const POINT = {
    "This.L42": `reuse [L42.is/AdamsTowel]
Point = Data:{...}

Main=(
  _=Log"".#$reader()

  Debug(S"Hello world from 42!")

  imm Point p = (Point(x=5\\, y=2\\).sum(Point(x=3\\, y=1\\)))
  Debug(S"p = %p")
  )\n`,
  "Point.L42": `Num x
Num y
method
Point add(Num x) = //long version
  Point(x=x+this.x(), y=this.y())
method
Point add(Num y) = //shorter
  this.with(y=y+this.y())
method
Point sum(Point that) =
  Point(x=this.x()+that.x(), y=this.y()+that.y())\n`
};

const SIMPLE_INVARIANT = `reuse [L42.is/AdamsTowel]
Point = Data:{
  Double x
  Double y
  @Cache.Now class method Double distanceFromOrigin(Double x, Double y) = 
    ((x*x)+(y*y)).pow(exp=\\"0.5")
  // x and y must always be positive
  @Cache.Now class method Void invariant(Double x, Double y) = 
    if !(x>=0Double && y>=0Double) error X"""%
      | Invalid state:
      | x = %x
      | y = %y
      """
  }

Main=(
  _=Log"".#$reader()

  Point p = Point(x=Double"5", y=Double"3")
  // This would result in an error:
  //Point p2 = Point(x=Double"5", y=Double"-3")
  Debug(S"p = %p")
  )
`;

const MUTATION = {
  "This.L42": { template: `reuse [L42.is/AdamsTowel]

Point=Data:{var Num x, var Num y}
Square=Data:{var mut Point p}

Code = {

???

}

Main=(
  mut Any stuff=Code.make()
  Square p1 = Code.do1(stuff)
  S s1 = p1.toS()
  Code.do2(p1, stuff=stuff)
  S s2 = p1.toS()
  X[s1 != s2]
  Debug(S"--secret--")
  )`, value: `class method mut Any make() = S.List()
class method Square do1(mut Any that) = Square(p=Point(x=1Num, y=2Num))
class method Void do2(Square that, mut Any stuff) = void` },
};

const INVARIANT = {
  "This.L42": { template: `reuse [L42.is/AdamsTowel]

IsOK = {interface read method Bool isOk()}

A = Data:{
  capsule IsOK inner

  @Cache.Now class method Void invariant(read IsOK inner) =
    X[inner.isOk()]

  @Cache.Clear class method
  Void operation(mut IsOK inner) = Code.operation(inner)
  }

Code = {

???

}

Main=(
  _=Log"".#$reader()

  capsule IsOK inner=Code.makeInner()
  a = A(inner=inner)
  a.operation()

  // we believe it is always going to be X[a.inner().isOk()],
  // for any MakeInner and Operation
  X[!a.inner().isOk()]
  Debug(S"--secret--")
  )`, value: `AlwaysOk = Data:{[IsOK]
  var S name = S""
  read method Bool isOk() = Bool.true()
}

class method capsule AlwaysOk makeInner() = AlwaysOk()
class method Void operation(mut IsOK that) = void` },
}

const FILE_SYSTEM_EXAMPLE = {
  "This.L42": `reuse [L42.is/AdamsTowel]
Fs = Load:{reuse [L42.is/FileSystem]}

Main=(
  mut Fs f = Fs.Real.#$of()
  S s=f.read(Url"data.txt")

  Debug(s)
  )`,
  "Setti.ngs": makeBasicSettings('L42.is/FileSystem'),
}

const EXAMPLES = [
    {
      name: "Hello World",
      default: true,
      files: { "This.L42": HELLO_WORLD }
    },
    { name: "Hello World (template)", files: PRINT_HELLO_WORLD_CHALLENGE },
    { name: "Point", files: POINT },
    { name: "Point Sum Method challenge", files: POINT_SUM_METHOD },
    { name: "Simple Invariant", files: SIMPLE_INVARIANT },
    { name: "Filesystem Access", files: FILE_SYSTEM_EXAMPLE },
    { name: "Mutation", files: MUTATION },
    { name: "Invariant", files: INVARIANT },
];
