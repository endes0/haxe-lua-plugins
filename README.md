# Lua Plugins

Library for use LUA VM natively in haxe, because of this, only works on _CPP, JAVA, JS(with node for load files), LUA, PHP, PYTHON and C#_ and every platform have is peculiarities.

## Usage
Every instance its called a plugin and have.

Loading a plugin:
```haxe
var pl = new Luaplugin("<The path of the lua script>", <An array of classes you want to pass to the script>, <the _ENV value, default is sandboxed>, {name: "<the name>", version: "<the version>", author: "<the author>", url: "<the homepage>"});
```
You need to call haxe classes with `:` instead of `.`, because it adds the self class as his first argument [Read More](http://www.lua.org/manual/5.1/manual.html#2.5.8).

Calling a function:
```haxe
pl.call("<The function name>", [<Array of args>], "<the type of the response>");
```
The type of the response can be null or must be _float,int,array or bool_.

Getting a global var:
```haxe
pl.get_var("<The var name>", "<the type of the response>");
```
The type of the response can be null or must be _float,int,array or bool_.


Executing code from a string:
```haxe
pl.eval("<code>");
```

Executing code from a script file:
```haxe
pl.load_file("<The path of the lua script>");
```

## Platforms

### CPP
Implemented using the library [linc_luajit](https://github.com/RudenkoArts/linc_luajit).
At this moment the library dont support bind functions to the LUA VM, so you only can add classes with fields thats arent functions to the plugin.
The tests results shows that there is an error getting globals vars or setting in to function call.

Test results:
```
Testpls.hx:13: from get var :
Testpls.hx:14: null
Testpls.hx:15: attempt to call a nil value
Testpls.hx:16: 4.08548550151014e-313
Convert.hx:96: return value not supported

Testpls.hx:17: null
Testpls.hx:19: Execution time: 0.000403881072998047ms
```

### JAVA
This implementation uses the native library [luaj](http://www.luaj.org/luaj.html).

Test results:
```
Testclass.hx:9: hi
Testpls.hx:13: from get var :
Testpls.hx:14: hi
Testpls.hx:15: 3
Testpls.hx:16: 3.14
Testpls.hx:17: true
Testpls.hx:19: Execution time: 0.17800021171569824ms
```
### JS
*NOT TESTED*
This implementation uses the native library [fengari-lua](https://github.com/fengari-lua/fengari). Its like the implementation in _CPP_, so posibily has is same fails.

if you test, please let me know(Use nodejs for test).

### LUA
This implementation is very strange, I dont know the method to create another LUA VM in LUA, so I used `dofile` and calling the functions and get vars directly, so posibily there isnt sandboxed(_the plugin can modify data(vars, functions, ...) of the program_).

Test results:
```
Testclass.hx:9: hi
Testpls.hx:13: from get var :
Testpls.hx:14: 3
Testpls.hx:15: 3.14
Testpls.hx:16: true
Testpls.hx:17: null
Testpls.hx:19: Execution time: 0.00018811225891113ms
```

### PHP
*NOT TESTED, because haxe dont transpile fot php 7.2, but my system uses it.*

### PYTHON
This implementation uses the native library [lupa](https://github.com/scoder/lupa), so the runtime need to have it. In this platform you cant pass a String to a Lua function.

Test results:
```
hi
from get var :
None
3
3.14
True
Execution time: 0.007448712000041269ms
```

### C#
*NOT TESTED, because this error on building:*
```
extern/Neo.Lua.dll @ neo.ironlua.Lua (Finalize):1: character 0 : Invalid override on field 'Finalize': class has no super class
extern/Neo.Lua.dll @ neo.ironlua.Lua:1: character 0 : Defined in this class
extern/Neo.Lua.dll @ neo.ironlua.LuaTable (<>9__200_0):1: character 0 : Type not found : T0
```

if you know he solution, please open a issue.

## TODO
- Fix C#
- Fix CPP getting vars
- Test all platforms
- Add neko platform
- Add hl platform
- Make better README

## THIRD PARTIES licenses
- *neolua* is under [Apache 2 license](https://github.com/neolithos/neolua/blob/master/LICENSE.md)
- *luaJ* is under [MIT license](http://web.archive.org/web/20140514153921/https://sourceforge.net/dbimage.php?id=196142)
- *fengari-lua* is under [MIT license](https://github.com/fengari-lua/fengari/blob/master/LICENSE)
- *lupa* is under [MIT license](https://github.com/scoder/lupa/blob/master/LICENSE.txt)
- *linc_lua* is under [MIT license](https://github.com/RudenkoArts/linc_luajit/blob/master/LICENSE.md)




---
by [NetaLabTek](https://netalab.tk/)
