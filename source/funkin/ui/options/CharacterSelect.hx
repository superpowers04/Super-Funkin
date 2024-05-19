package funkin.ui.options;



import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.graphics.FunkinCamera;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.play.character.CharacterData.CharacterDataParser;
import flixel.util.FlxAxes;
class CharacterSelect extends Page
{
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<IFuckingHateThisCheckBox>;
  var characters:Array<String> = ['BF'];
  public static var BF:String = "";

  var menuCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
	super();

	menuCamera = new FunkinCamera('prefMenu');
	FlxG.cameras.add(menuCamera, false);
	menuCamera.bgColor = 0x0;
	camera = menuCamera;

	add(items = new TextMenuList());
	add(preferenceItems = new FlxTypedSpriteGroup<IFuckingHateThisCheckBox>());

	createPrefItems();

	camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
	if (items != null) camFollow.y = items.selectedItem.y;

	menuCamera.follow(camFollow, null, 0.06);
	var margin = 160;
	menuCamera.deadzone.set(0, margin, menuCamera.width, 40);
	menuCamera.minScrollY = 0;

	items.onChange.add(function(selected) {
	  camFollow.y = selected.y;
	});
  }

  /**
   * Create the menu items for each of the preferences.
   */
  function select(id:Int=0,value:Bool = true):Void {
	if(value){
		BF = characters[id];
	}else{
		BF="";
	}
	for (id => name in characters){
		preferenceItems.members[id].currentValue = (name == BF);
	}
  }
  function createPrefItems():Void
  {
	characters = CharacterDataParser.listCharacterIds();
	for (id => name in characters){
		createPrefItemCheckbox(name, 'Set BF to $name', select.bind(id,_), BF==name);
	}

  }

  function createPrefItemCheckbox(prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool):Void
  {
	var checkbox:IFuckingHateThisCheckBox = new IFuckingHateThisCheckBox(0, 120 * (items.length - 1 + 1), defaultValue);
	checkbox.value = prefName;
	items.createItem(120, (120 * items.length) + 30, prefName, AtlasFont.BOLD, function() {
	  var value = !checkbox.currentValue;
	  onChange(value);
	  checkbox.currentValue = value;
	});

	preferenceItems.add(checkbox);
  }

  override function update(elapsed:Float)
  {
	super.update(elapsed);

	// Indent the selected item.
	// TODO: Only do this on menu change?
	items.forEach(function(daItem:TextMenuItem) {
		daItem.screenCenter(FlxAxes.X);
		if (items.selectedItem == daItem) daItem.x -= 30;

	}); 
  }
}
class IFuckingHateThisCheckBox extends FlxSprite
{
  public var currentValue(default, set):Bool;
  public var value:String = "";

  public function new(x:Float, y:Float, defaultValue:Bool = false)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('checkboxThingie');
    animation.addByPrefix('static', 'Check Box unselected', 24, false);
    animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);

    setGraphicSize(Std.int(width * 0.7));
    updateHitbox();

    this.currentValue = defaultValue;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    switch (animation.curAnim.name)
    {
      case 'static':
        offset.set();
      case 'checked':
        offset.set(17, 70);
    }
  }

  function set_currentValue(value:Bool):Bool
  {
    if (value)
    {
      animation.play('checked', true);
    }
    else
    {
      animation.play('static');
    }

    return currentValue = value;
  }
}
