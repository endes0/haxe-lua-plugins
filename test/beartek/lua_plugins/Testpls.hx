package beartek.lua_plugins;
import beartek.lua_plugins.Luaplugin;

class Testpls {

  public function new() {
    var start_time : Float = haxe.Timer.stamp();
    var a : Array<Dynamic> = [new Testclass()];
    var expl = new Luaplugin("../pl/pl.lua", a, {name: "test pl", version: "0.0.0", author: "endes", url: "gg.gg"});

    var testargs : Array<Dynamic> = ['hi', 3, 3.14, true];
    expl.call('init', testargs);
    trace( 'from get var :' );
    trace( expl.get_var('hi') );
    trace( expl.get_var('number') );
    trace( expl.get_var('float') );
    trace( expl.get_var('bool') );

    trace( 'Execution time: ' + (haxe.Timer.stamp() - start_time) + 'ms' );
  }

  static function main() {
    new Testpls();
  }
}
