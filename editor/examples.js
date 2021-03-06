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

// Can you change this program to print "Hello World"?

Code = {
???}

Main=(
  _=Log"".#$reader()

  Debug(Code.hello())
  )`,
  value: `class method S hello() = {
  return S""
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

const INVARIANT2 = {
  "This.L42": { template: `reuse [L42.is/AdamsTowel]

IsOK = {interface read method Bool isOk()}

A = Data:{
  var capsule IsOK inner

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
  S s=f.read(Url"This.L42")

  Debug(s)
  )`,
  "Setti.ngs": makeBasicSettings('L42.is/FileSystem'),
}

const JSON_EXAMPLE = `reuse [L42.is/AdamsTowel]
Json = Load:{reuse[L42.is/Json]}
Main=(
  _=Log"".#$reader()

  Json.Value v=Json"""
    |[{ "a":1, "b":true, "c":["Hello","World"]}]
    """
  Debug(v)
  )`;

const PROCESS_EXAMPLE = {
  "This.L42": `reuse [L42.is/AdamsTowel]
Process = Load:{reuse[L42.is/Process]}

Main=(
  //_=Log"".#$reader()

  mut Process pLinux=Process.Real.#$of(\\[S"ls";S"-l"])
  res=pLinux.start(input=S"")
  Debug(res.out())
  Debug(res.err())
  catch Process.Fail f Debug(S"oh no!")
  )`,
  "Setti.ngs": makeBasicSettings('L42.is/Process'),
};

const TIME_EXAMPLE = {
  "This.L42": `reuse [L42.is/AdamsTowel]
Time = Load:{reuse[L42.is/Time]}
Main=(
  t = Time.Real.#$of()
  current = t.currentTime()
  date = t.dateTime(zoneId=S"Pacific/Auckland",pattern=S"yyyy/MM/dd HH:mm:ss OOOO")
  Debug(current)
  Debug(date)
  )`,
  "Setti.ngs": makeBasicSettings('L42.is/Time'),
};

const JAVA_EXAMPLE = {
  "This.L42": `reuse [L42.is/AdamsTowel]

MyClass = {
  class method S #$hello() = native{
    slave{}{
      String result = "";
      for (int i = 0; i < 10; ++i) {
        result += i + " ";
      }
      return result;
    }} error void
}

Main = (
  Debug(MyClass.#$hello())
  )`,
  "Setti.ngs": makeBasicSettings('This'),
};

const POINT_LIST_EXAMPLE = {
  "This.L42": `reuse [L42.is/AdamsTowel]

Point = Data:{...}

Nums = Collection.list(Num)
Points = Collection.list(Point)

Main=(
  _=Log"".#$reader()
  
  xs = Nums[ 10\\; 20\\; 30\\ ]
  ys = Nums[ \\"-1"; \\"2/3"; 3\\ ]
  points = Points[]
  for x in xs, y in ys (
    points.add(\\(x=x, y=y)) // here \\ is Point
    )
  Debug(points)
  )`,
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

const EXAMPLES = [
    { section: "--- Sample Programs ---" },
    { name: "Hello World", default: true, files: { "This.L42": HELLO_WORLD } },
    { name: "Point", files: POINT },
    { name: "List of Points", files: POINT_LIST_EXAMPLE },
    { name: "Simple Invariant", files: SIMPLE_INVARIANT },
    { name: "Filesystem Access", files: FILE_SYSTEM_EXAMPLE },
    { name: "JSON", files: JSON_EXAMPLE },
    { name: "Processes", files: PROCESS_EXAMPLE },
    { name: "Time", files: TIME_EXAMPLE },
    { name: "Java", files: JAVA_EXAMPLE },
    { section: "--- Tutorial Challenges ---" },
    { name: "Hello World Challenge", files: PRINT_HELLO_WORLD_CHALLENGE },
    { name: "Point Sum Method", files: POINT_SUM_METHOD },
    { section: "--- Bug Bounty Challenges ---" },
    { name: "Mutation", files: MUTATION },
    { name: "Invariant", files: INVARIANT },
    { name: "Invariant 2", files: INVARIANT2 },
];
