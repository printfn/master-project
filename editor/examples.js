const HELLO_WORLD = `reuse [L42.is/AdamsTowel]
Main=(
  _=Log"".#$reader()

  Debug(S"Hello world from 42")
  )`;

const LOGGER_SETTINGS = `/*
  *** 42 settings ***
  You can change the stack and memory limitations and add security mappings
*/
maxStackSize = 1G
initialMemorySize = 256M
maxMemorySize = 2G

Main = [L42.is/AdamsTowel/Log]
`;

const POINT_CHALLENGE = {
  "This.L42": `reuse [L42.is/AdamsTowel]
Point = Data:{
  Num x
  Num y
  ???
}

Main=(
  Debug(S"Hello world from 42!")

  imm Point p = (Point(x=5\\, y=2\\).sum(Point(x=3\\, y=1\\)))
  Debug(S"p = %p")
  )`,
  template: true
}

const PRINT_HELLO_WORLD_CHALLENGE = {
    "This.L42": `reuse [L42.is/AdamsTowel]
Main=(
  Debug(S"???")
  )`,
    template: true,
};

const POINT = {
    "This.L42": `reuse [L42.is/AdamsTowel]
Point = Data:{...}

Main=(
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
  Point p = Point(x=Double"5", y=Double"3")
  // This would result in an error:
  //Point p2 = Point(x=Double"5", y=Double"-3")
  Debug(S"p = %p")
  )
`;

const EXAMPLES = [
    {
      name: "Hello World",
      default: true,
      files: {
        "This.L42": HELLO_WORLD,
        "Setti.ngs": LOGGER_SETTINGS
      }
    },
    { name: "Point Testing", files: POINT_CHALLENGE },
    { name: "Point", files: POINT },
    { name: "Simple Invariant", files: SIMPLE_INVARIANT },
    { name: "Hello World challenge", files: PRINT_HELLO_WORLD_CHALLENGE },
];
