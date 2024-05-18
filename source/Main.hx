package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.util.logging.CrashHandler;
import funkin.ui.debug.MemoryCounter;
import funkin.save.Save;
import haxe.ui.Toolkit;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.ui.FuckState;

/**
 * The main class which initializes HaxeFlixel and starts the game in its initial state.
 */
class Main extends Sprite
{
  var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var initialState:Class<FlxState> = funkin.InitState; // The FlxState the game starts with.
  public static var instance:Main;
  public static var game:FlxGameEnhanced;
  var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
  #if web
  var framerate:Int = 60; // How many frames per second the game should run at.
  #else
  // TODO: This should probably be in the options menu?
  var framerate:Int = 144; // How many frames per second the game should run at.
  #end
  var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
  var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

  // You can pretty much ignore everything from here on - your code should go in your states.

  public static function main():Void
  {
    // We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.
    // CrashHandler.initialize();
    FuckState.hook();
    CrashHandler.queryStatus();

    Lib.current.addChild(new Main());
  }

  public function new()
  {
    super();

    // Initialize custom logging.
    // haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;
    // funkin.util.logging.AnsiTrace.traceBF();

    // Load mods to override assets.
    // TODO: Replace with loadEnabledMods() once the user can configure the mod list.
    funkin.modding.PolymodHandler.loadAllMods();

    if (stage != null)
    {
      init();
    }
    else
    {
      addEventListener(Event.ADDED_TO_STAGE, init);
    }
  }

  function init(?event:Event):Void
  {
  	instance=this;
    if (hasEventListener(Event.ADDED_TO_STAGE))
    {
      removeEventListener(Event.ADDED_TO_STAGE, init);
    }

    setupGame();
  }

  var video:Video;
  var netStream:NetStream;
  var overlay:Sprite;

  /**
   * A frame counter displayed at the top left.
   */
  public static var fpsCounter:FPS;

  /**
   * A RAM counter displayed at the top left.
   */
  public static var memoryCounter:MemoryCounter;

  function setupGame():Void
  {
    initHaxeUI();

    // addChild gets called by the user settings code.
    fpsCounter = new FPS(10, 3, 0xFFFFFF);

    #if !html5
    // addChild gets called by the user settings code.
    // TODO: disabled on HTML5 (todo: find another method that works?)
    memoryCounter = new MemoryCounter(10, 13, 0xFFFFFF);
    #end

    // George recommends binding the save before FlxGame is created.
    Save.load();
    game = new FlxGameEnhanced(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);

    // FlxG.game._customSoundTray wants just the class, it calls new from
    // create() in there, which gets called when it's added to stage
    // which is why it needs to be added before addChild(game) here
    @:privateAccess
    game._customSoundTray = funkin.ui.options.FunkinSoundTray;

    addChild(game);

    #if debug
    game.debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil());
    #end

    addChild(fpsCounter);

    #if hxcpp_debug_server
    trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
    #else
    trace('hxcpp_debug_server is disabled! This build does not support debugging.');
    #end
  }
	override function __enterFrame(_){
		try{
			if(game != null){
				if(FlxG.keys.justPressed.F1) throw('Manual error');
				super.__enterFrame(_);
			}else{
				super.__enterFrame(_);
				// trace('h');
			}
		}catch(e){
			FuckState.FUCK(e,"Main.onEnterFrame");
		}
	}
  function initHaxeUI():Void
  {
    // Calling this before any HaxeUI components get used is important:
    // - It initializes the theme styles.
    // - It scans the class path and registers any HaxeUI components.
    Toolkit.init();
    Toolkit.theme = 'dark'; // don't be cringe
    // Toolkit.theme = 'light'; // embrace cringe
    Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.registerHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }
}

// Made specifically for Super Engine. Adds some extensions to FlxGame to allow it to handle errors
// If you use this at all, Please credit me
class FlxGameEnhanced extends FlxGame{
	static var blankState:FlxState = new FlxState();
	public function forceStateSwitch(state:FlxState){ // Might be a bad idea but allows an error to force a state change to Mainmenu instead of softlocking
		_requestedState = state;
		switchState();
	}
	public function setState(state:FlxState){ // Might be a bad idea but allows an error to force a state change to Mainmenu instead of softlocking
		this._state=state;
	}
	public var blockUpdate:Bool = false;
	public var blockDraw:Bool = false;
	public var blockEnterFrame:Bool = false;

	var requestAdd = false;
	override function create(_){
		try{
			super.create(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.Create");
		}
	}
	override function onEnterFrame(_){
		try{
			if(requestAdd){
				requestAdd = false;
				// Main.funniSprite.addChildAt(this,0);
				blockUpdate = blockEnterFrame = blockDraw = false;
				FlxG.autoPause = _oldAutoPause;
				_oldAutoPause = false;

				if(_lostFocusWhileLoading != null){
					onFocusLost(_lostFocusWhileLoading);_lostFocusWhileLoading = null;
				}

			}

			// if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F1){
			// 	MainMenuState.handleError("Manually triggered force exit");
			// }
			if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F4){
				throw('Manually triggered crash');
			}
			if(blockEnterFrame) {
				_elapsedMS = (_total = ticks = getTicks()) - _total;
			}else{
				super.onEnterFrame(_);
			}

		}catch(e){
			FuckState.FUCK(e,"FlxGame.onEnterFrame");
		}
	}
	public var funniLoad:Bool = false;
	function _update(){
		if (!_state.active || !_state.exists)
			return;


		#if FLX_DEBUG
		if (FlxG.debugger.visible)
			ticks = getTicks();
		#end

		updateElapsed();

		FlxG.signals.preUpdate.dispatch();

		#if FLX_POST_PROCESS
		if (postProcesses[0] != null)
			postProcesses[0].update(FlxG.elapsed);
		#end

		#if FLX_SOUND_SYSTEM
		FlxG.sound.update(FlxG.elapsed);
		#end
		FlxG.plugins.update(FlxG.elapsed);

		FlxG.signals.postUpdate.dispatch();

		#if FLX_DEBUG
		debugger.stats.flixelUpdate(getTicks() - ticks);
		#end

		filters = filtersEnabled ? _filters : null;
	}
	var _oldAutoPause:Bool = false;
	var hasUpdated = false;
	#if(flixel > "5.3.2")
	public var _requestedState(get,set):flixel.util.typeLimit.NextState;
	public function set__requestedState(e:flixel.util.typeLimit.NextState) return _nextState=e;
	public function get__requestedState() return _nextState;
	#end
	override function update(){
		
		try{

			if(blockUpdate) _update(); else {
				hasUpdated = true;
				super.update();

				if (FlxG.keys.justPressed.F11) FlxG.save.data.fullscreen = (FlxG.fullscreen = !FlxG.fullscreen);
			}
		}catch(e){
			FuckState.FUCK(e,"FlxGame.Update");
		}
	}
	override function draw(){
			try{
				if (blockDraw || _state == null || !_state.visible || !_state.exists || !hasUpdated) return;
				#if FLX_DEBUG
				if (FlxG.debugger.visible) ticks = getTicks();
				#end
				try{
					FlxG.signals.preDraw.dispatch();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:preDraw"); return;
				}
				if (FlxG.renderTile)
					flixel.graphics.tile.FlxDrawBaseItem.drawCalls = 0;


				#if FLX_POST_PROCESS
				try{
				if (postProcesses[0] != null)
					postProcesses[0].capture();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:postProcess"); return;
				}
				#end
				try{

					FlxG.cameras.lock();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:camerasLock"); return;
				}
				try{
					FlxG.plugins.draw();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:pluginDraw"); return;
				}
				try{
					_state.draw();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:stateDraw"); return;
				}
				if (FlxG.renderTile)
				{
					try{
						FlxG.cameras.render();
					}catch(e){
						FuckState.FUCK(e,"FlxGame.Draw:cameraRender"); return;
					}
					#if FLX_DEBUG
					debugger.stats.drawCalls(FlxDrawBaseItem.drawCalls);
					#end
				}
				try{
					FlxG.cameras.unlock();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:cameraUnlock"); return;
				}
				try{
					FlxG.signals.postDraw.dispatch();
				}catch(e){
					FuckState.FUCK(e,"FlxGame.Draw:postDraw"); return;
				}
				#if FLX_DEBUG
				debugger.stats.flixelDraw(getTicks() - ticks);
				#end
			}catch(e){
				FuckState.FUCK(e,"FlxGame.Draw:function"); return;
			}
	}
	var _lostFocusWhileLoading:flash.events.Event = null;
	override function onFocus(_){
		try{
			if(blockEnterFrame)
				_lostFocusWhileLoading = null;
			else
				super.onFocus(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.onFocus");
		}
	}
	override function onFocusLost(_){
		try{
			if(blockEnterFrame && _oldAutoPause) 
				_lostFocusWhileLoading = _; 
			else if(!blockEnterFrame) 
				super.onFocusLost(_);
		}catch(e){
			FuckState.FUCK(e,"FlxGame.onFocusLost");
		}
	}
}