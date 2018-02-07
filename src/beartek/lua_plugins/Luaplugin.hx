//Under GNU GPL v3, see LICENCE
//Third-party code: Convert.hx, linc_luajit, by Andrei Rudenko, under MIT licence
package beartek.lua_plugins;

#if cs
import neo.ironlua.Lua;
#elseif java
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.JsePlatform;
import org.luaj.vm2.lib.jse.CoerceJavaToLua;
import java.NativeArray;
#elseif cpp
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

class Luaplugin {
  public var name(default, null) : String;
  public var version(default, null) : String;
  public var author(default, null) : String;
  public var url(default, null) : String;

  public var env(default, null) : String = '{ ipairs = ipairs, next = next, pairs = pairs, pcall = pcall, tonumber = tonumber, tostring = tostring, type = type, unpack = unpack, coroutine = { create = coroutine.create, resume = coroutine.resume, running = coroutine.running, status = coroutine.status, wrap = coroutine.wrap }, string = { byte = string.byte, char = string.char, find = string.find, format = string.format, gmatch = string.gmatch, gsub = string.gsub,  len = string.len, lower = string.lower, match = string.match,  rep = string.rep, reverse = string.reverse, sub = string.sub,  upper = string.upper }, table = { insert = table.insert, maxn = table.maxn, remove = table.remove, sort = table.sort }, math = { abs = math.abs, acos = math.acos, asin = math.asin,  atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos,  cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor,  fmod = math.fmod, frexp = math.frexp, huge = math.huge,  ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, min = math.min, modf = math.modf, pi = math.pi, pow = math.pow, rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh, sqrt = math.sqrt, tan = math.tan, tanh = math.tanh }, os = { clock = os.clock, difftime = os.difftime, time = os.time }, }';


  private var classes(default, null) : Array<Dynamic> = new Array();
  #if cpp
  private var plugin : State;
  #elseif cs
  private var plugin : Dynamic;
  private var lg : Lua;
  #else
  private var plugin : Dynamic;
  #end
  #if python
  private var lg : Dynamic;
  #end

  public function new(filepath : String, classes : Array<Dynamic>, ?env: String, ?info : {name : String, version : String, author : String, url : String}) {
    #if python
    python.Syntax.importAs('lupa', 'lupa');
    python.Syntax.importFromAs('lupa', 'LuaRuntime', 'LuaRuntime');
    #end

    if(env != null) this.env = env;
    this.name = if(info.name != null) info.name else 'no_named_pl';
    this.version = info.version;
    this.author = info.author;
    this.url = info.url;
    this.classes = classes;

    #if php
      this.plugin = untyped __php__('new Lua()');
      this.plugin.eval("_ENV = " + this.env);

      this.plugin.eval('function get_var(var)
      return _G[var]
      end');
    #elseif python
      this.plugin = untyped LuaRuntime();
      this.plugin.execute("_ENV = " + this.env);
      this.lg = this.plugin.globals();

      var apiadd = this.plugin.eval('function(name, obj) _G[name] = obj end');
    #elseif cs
    this.lg = new Lua();
    this.plugin = this.lg.CreateEnvironment();
    #elseif java
      this.plugin = JsePlatform.standardGlobals();
      this.plugin.set('_ENV', this.env);
    #elseif js
      this.plugin = untyped fengari.lauxlib.luaL_newstate();
      untyped fengari.lualib.luaL_openlibs(this.plugin);
      untyped fengari.lualib.luaL_loadstring(this.plugin, "_ENV = " + this.env);
    #elseif cpp
      this.plugin = LuaL.newstate();
      LuaL.openlibs(this.plugin);
      LuaL.loadstring(this.plugin, "_ENV = " + this.env);
    #end

    for( api in classes ) {
      var api_name : String = Type.getClassName(Type.getClass(api)).split('.').join('_');

      #if php
        this.plugin.eval(api_name + " = {}");

        for( field in Type.getInstanceFields(Type.getClass(api)) ) {
          if( Type.typeof(Reflect.field(api, field)) == TFunction ) {
            this.plugin.registerCallback('_' + api_name + '_' + field, Reflect.field(api, field));
          } else {
            this.plugin.assign('_' + api_name + '_' + field, Reflect.getProperty(api, field));
          }
          this.plugin.eval(api_name + '.' + field + ' = ' + '_' + api_name + '_' + field);
        }
      #elseif python
        var name : String = api_name;
        apiadd(name, api);
      #elseif lua
        untyped __lua__('table.insert(_G, {0})', api_name);
        untyped __lua__('_G[{0}] = {1}', api_name, api);
      #elseif cs
        this.plugin.RegisterPackage(api_name, c.Lib.toNativeType(Type.getClass(api)));
      #elseif java
        var lua_api : LuaValue = CoerceJavaToLua.coerce(api);
        this.plugin.set(api_name, lua_api);
      #elseif js
        this.jstoLua(this.plugin, api); //posibily it doesnt work
        untyped fengari.lua.setglobal(this.plugin, api_name);
      #elseif cpp
        Convert.toLua(this.plugin, api); //curently the linc_lua dont pass functions
        Lua.setglobal(this.plugin, api_name);
      #end
    }

    this.load_file(filepath);
  }

  public function load_file( filepath : String ) : Void {
    #if php
      this.plugin.include(filepath);
    #elseif python
      this.plugin.execute(sys.io.File.getContent(filepath));
    #elseif lua
      untyped __lua__('dofile(filepath, nil, {0})', this.env);
    #elseif cs
      this.plugin.dochunk(sys.io.File.getContent(filepath), this.name);
    #elseif java
      this.plugin.loadfile(filepath).call();
    #elseif nodejs
      js.node.Fs.readFile(filepath, function( err, data ) {
        if( err != null ) {
          throw err;
        }

        untyped this.plugin.exec(data);
      });
    #elseif cpp
      LuaL.loadfile(this.plugin, filepath);
    #end
  }

  public function eval( code : String ) : Void {
    #if php
      this.plugin.eval(code);
    #elseif python
      this.plugin.execute(code);
    #elseif lua
      untyped __lua__('loadstring({});', code);
    #elseif cs
    this.plugin.dochunk(code, this.name);
    #elseif java
      this.plugin.set(code);
    #elseif js
      untyped this.plugin.exec(code);
    #elseif cpp
      LuaL.loadstring(this.plugin, code);
    #end

  }

  public function get_var(var_name : String, ?type : String) : Dynamic {
    var result : Any = null;

    #if php
      result = this.plugin.call('get_var', php.Lib.toPhpArray([var_name]));
    #elseif python
      result = Reflect.getProperty(lg, var_name);
    #elseif lua
      result = untyped __lua__('_G[{0}]', var_name);
    #elseif cs
      result = Reflect.field(this.plugin,var_name);
    #elseif java
      result = this.plugin.get(var_name).toString();
    #elseif js
      untyped fengari.lua.getglobal(this.plugin, var_name);
		  switch(untyped fengari.lua.type(this.plugin, 0)) {
			     case 0:
				         result = null;
			     case 1:
				         result = untyped fengari.lua.toboolean(this.plugin, 0);
			     case 3:
				         result = untyped fengari.lua.tonumber(this.plugin, 0);
			     case 4:
				         result = untyped fengari.lua.tostring(this.plugin, 0);
			     //case 5:
				         //result = fromLuaTable(l);
			     default:
				         result = null;
				         trace("return value not supported\n");
      }
    #elseif cpp
      Lua.getglobal(this.plugin, var_name);
      result = Convert.fromLua(this.plugin, 0);
    #end

    if( result == null ) {
      return null;
    } else {
      return this.convert(result, type);
    }
  }

  public function call(func_name : String, args : Array<Dynamic>, ?type : String) : Dynamic {
    var result : Any = null;

    #if php
      result = this.plugin.call(func_name, php.Lib.toPhpArray(args));
    #elseif python
      if( args == null ) {
        result = this.plugin.eval(func_name + "()");
      } else {
        result = this.plugin.eval(func_name + "(" + this.final_args(args) + ")");
      }
    #elseif lua
      if( args == null ) {
        result = untyped __lua__("_G[{0}]()", func_name);
      } else {
        result = untyped __lua__("_G[{0}](unpack({1}))", func_name, args);
      }
    #elseif cs
      Reflect.callMethod(this.plugin,Reflect.field(this.plugin,func_name), args);
    #elseif java
      var f_args : NativeArray<LuaValue> = new NativeArray(args.length);
      for( i in 0...args.length ) {
        if( Std.is(args[i], Int) ) {
          var f_arg : Int = args[i];
          f_args[i] = LuaValue.valueOf(f_arg);
        } else if( Std.is(args[i], Float) ) {
          var f_arg : Float = args[i];
          f_args[i] = LuaValue.valueOf(f_arg);
        } else if( Std.is(args[i], Bool) ) {
          var f_arg : Bool = args[i];
          f_args[i] = LuaValue.valueOf(f_arg);
        } else if( Std.is(args[i], String) ) {
          var f_arg : String = args[i];
          f_args[i] = LuaValue.valueOf(f_arg);
        }
      }

      var p_result : LuaValue = this.plugin.get(func_name).invoke(LuaValue.varargsOf(f_args)); //arreglar
      result = p_result.tojstring();
    #elseif js
      untyped fengari.lua.getglobal(this.plugin, func_name);

      for( arg in args ) {
        this.jstoLua(this.plugin, arg);
      }

      result = untyped fengari.lua.pcall(this.plugin, args.length, 1, 1);
    #elseif cpp
      Lua.getglobal(this.plugin, func_name);

      for( arg in args ) {
        Convert.toLua(this.plugin, arg);
      }

      result = Lua.pcall(this.plugin, args.length, 1, 1);
    #end

    if( result == null) {
      return null;
    } else {
      return this.convert(result, type);
    }
  }

  private function convert(v : Any, type : String) : Dynamic {
    if( Std.is(v, String) && type != null ) {
      var v : String = v;
      if( type.substr(0, 4) == 'array' ) {
        if( type.substr(4) == 'float' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Float> = new Array();

          for( vars in array ) {
            array2.push(Std.parseFloat(vars));
          }

          return array2;
        } else if( type.substr(4) == 'int' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Int> = new Array();

          for( vars in array ) {
            array2.push(Std.parseInt(vars));
          }

          return array2;
        } else {
          var array : Array<String> = v.split(',');
          return array;
        }
      } else if( type == 'float' ) {
        return Std.parseFloat(v);
      } else if( type == 'int' ) {
        return Std.parseInt(v);
      } else if( type == 'bool' ) {
        if( v == 'true' ) {
          return true;
        } else {
          return false;
        }
      } else {
        return v;
      }
    } else {
      return v;
    }
  }

  #if js
  private function jstoLua(l:Dynamic, val:Any):Bool {

		switch (Type.typeof(val)) {
			case Type.ValueType.TNull:
				untyped fengari.lua.pushnil(l);
			case Type.ValueType.TBool:
				untyped fengari.lua.pushboolean(l, val);
			case Type.ValueType.TInt:
				untyped fengari.lua.pushinteger(l, cast(val, Int));
			case Type.ValueType.TFloat:
				untyped fengari.lua.pushnumber(l, val);
			case Type.ValueType.TClass(String):
				untyped fengari.lua.pushstring(l, cast(val, String));
			case Type.ValueType.TClass(Array):
        var val : Array<Any> = val;
        var size:Int = val.length;
        untyped fengari.lua.createtable(l, size, 0);

        for (i in 0...size) {
          untyped fengari.lua.pushnumber(l, i + 1);
          this.jstoLua(l, val[i]);
          untyped fengari.lua.settable(l, -3);
        }
      case Type.ValueType.TClass(Any):
        untyped fengari.lua.createtable(l, Type.getInstanceFields(Type.getClass(val)).length, 0);
		      for (n in Type.getInstanceFields(Type.getClass(val))){
			         untyped fengari.lua.pushstring(l, n);
			         this.jstoLua(l, Reflect.field(val, n));
			         untyped fengari.lua.settable(l, -3);
          }
			case Type.ValueType.TObject:
		    untyped fengari.lua.createtable(l, Reflect.fields(val).length, 0);
		      for (n in Reflect.fields(val)){
			         untyped fengari.lua.pushstring(l, n);
			         this.jstoLua(l, Reflect.field(val, n));
			         untyped fengari.lua.settable(l, -3);
          }
		  //case Type.ValueType.TFunction:
			  //untyped fengari.lua.pushjsfunction(l, val);
			default:
				trace("haxe value not supported\n");
				return false;
		}

		return true;
	}
  #end


  private function final_args(args : Array<Dynamic>) : String {
    var final_args : String = '';
    for( arg in args ) {
      if( arg == args[args.length - 1] ) {
        final_args += arg;
      } else {
        final_args += arg + ', ';
      }
    }
    return final_args;
  }

}
