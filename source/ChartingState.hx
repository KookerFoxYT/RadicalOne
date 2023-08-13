package;

import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import Controls.KeyboardScheme;
import Discord.DiscordClient;
import flixel.util.FlxTimer;

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;

	var theCoolText:FlxText;

	var typingJunk:FlxInputText;
	var typingSopar:FlxInputText;
	var typingSussy:FlxInputText;
	var typingPLSBETHELASTONEEE:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Int = 0;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var char1:Character;
	var char2:Character;

	override function create()
	{
		DiscordClient.changePresence("Charting", null, 'sussy', 'racialdiversity');

		controls.setKeyboardScheme(KeyboardScheme.Solo, true);

		curSection = lastSection;

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		leftIcon = new HealthIcon('radical');
		rightIcon = new HealthIcon('interviewer');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				sections: 0,
				needsVoices: true,
				player1: 'radical',
				player2: 'interviewer',
				player3: 'namebe',
				player4: 'invisible',
				sectionLengths: [],
				speed: 1,
				validScore: false
			};
		}

		FlxG.mouse.load('assets/images/racialMouse.png');
		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		theCoolText = new FlxText(100, 300, 0, 'WARNING: INVALID CHARACTER', 16);
		theCoolText.scrollFactor.set();
		theCoolText.visible = false;
		add(theCoolText);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);

		reloadChars();

		super.create();
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var player1Label = new FlxText(10, 80, 70, 'Radical');

		var player1TextInput = new FlxUIInputText(10, 100, 70, _song.player1, 8);
		typingJunk = player1TextInput;

		var player2Label = new FlxText(130, 80, 70, 'Opponent');

		var player2TextInput = new FlxUIInputText(140, 100, 70, _song.player2, 8);
		typingSopar = player2TextInput;

		var player3Label = new FlxText(140, 190, 70, 'Gaming');

		var player3TextInput = new FlxUIInputText(140, 200, 70, _song.player3, 8);
		typingSussy = player3TextInput;

		var player4Label = new FlxText(10, 80, 70, 'G-Spot'); // maybe for destructed and several weekends idk

		var player4TextInput = new FlxUIInputText(280, 250, 70, _song.player4, 8);
		typingPLSBETHELASTONEEE = player4TextInput;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var check_record = new FlxUICheckBox(200, 600, null, null, "Record Key Presses",
			100); // wow this gives me an idea of making an engine based off on this mod lol (might do it soon maybe)
		check_record.checked = false;
		check_record.callback = function() recording = check_record.checked;

		var check_record_snap = new FlxUICheckBox(200, 625, null, null, "Snap Recorded Notes to Grid", 100);
		check_record_snap.checked = true;
		check_record_snap.callback = function() recSnap = check_record_snap.checked;

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var charVisi:FlxButton = new FlxButton(120, 340, 'Toggle Char Visibility', function() char1.visible = char2.visible = !char2.visible);

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			var daSong = _song.song;
			var isStoryLevel:Bool = false;
			for (juk in 0...StoryMenuState.weekData.length)
			{
				if (StoryMenuState.weekData[juk].contains(daSong))
				{
					isStoryLevel = true;
				}
			}
			if (isStoryLevel)
				loadJsonHard(_song.song.toLowerCase());
			else
				loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 999, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = Character.charArray;
		var charactersPlayable:Array<String> = ["radical", 'invisible', 'gaming'];

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(charactersPlayable, true), function(character:String)
		{
			_song.player1 = charactersPlayable[Std.parseInt(character)];
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
		});

		var player3DropDown = new FlxUIDropDownMenu(140, 200, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player3 = characters[Std.parseInt(character)];
		});

		var player4DropDown = new FlxUIDropDownMenu(280, 250, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player4 = characters[Std.parseInt(character)];
		});

		player2DropDown.selectedLabel = _song.player2;
		player3DropDown.selectedLabel = _song.player3;
		player4DropDown.selectedLabel = _song.player4;

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_record);
		tab_group_song.add(check_record_snap);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(charVisi);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1Label);
		tab_group_song.add(player1TextInput);
		tab_group_song.add(player2Label);
		tab_group_song.add(player2TextInput);
		tab_group_song.add(player3Label);
		tab_group_song.add(player3TextInput);
		tab_group_song.add(player4Label);
		tab_group_song.add(player4TextInput);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_getComboSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var check_gspotAnim:FlxUICheckBox;
	var check_dontplayAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		check_getComboSection = new FlxUICheckBox(10, 90, null, null, "Receive Combo Rating", 100);
		check_getComboSection.name = 'check_getCombo';
		check_getComboSection.checked = false;

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyLastButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copyLastSection(Std.int(stepperCopy.value));
		});

		var copyButton:FlxButton = new FlxButton(200, 130, "Copy Section to Clipboard", function()
		{
			copySection();
		});

		var pasteButton:FlxButton = new FlxButton(200, 160, "Paste Section from Clipboard", function()
		{
			pasteSection();
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		updateHeads();

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';
		check_gspotAnim = new FlxUICheckBox(10, 425, null, null, "3rd Character Animation", 100);
		check_gspotAnim.name = 'check_gspotAnim';
		check_dontplayAnim = new FlxUICheckBox(10, 450, null, null, "Dont Animate", 100);
		check_dontplayAnim.name = 'check_dontplayAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';
		check_changeBPM.callback = function() deez();

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_getComboSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_gspotAnim);
		tab_group_section.add(check_dontplayAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	function deez():Void
	{
		Conductor.mapBPMChanges(_song);
	}

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		FlxG.sound.playMusic('assets/music/' + daSong + "_Inst" + TitleState.soundExt, 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded("assets/music/" + daSong + "_Voices" + TitleState.soundExt);
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;

					updateHeads();

				case 'Receive Combo Rating':
					_song.notes[curSection].getComboSection = check.checked;

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
				case "3rd Character Animation":
					_song.notes[curSection].gspotAnim = check.checked;
				case "Dont Animate":
					_song.notes[curSection].dontplayAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		}
	}

	var updatedSection:Bool = false;

	function lengthBpmBullshit():Float
	{
		if (_song.notes[curSection].changeBPM)
			return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
		else
			return _song.notes[curSection].lengthInSteps;
	}

	function sectionStartTime():Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += (_song.notes[i].lengthInSteps / 4) * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var recording:Bool = false;
	var recSnap:Bool = true;
	var leftHold:Int = 0;
	var rightHold:Int = 0;
	var upHold:Int = 0;
	var downHold:Int = 0;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;
		_song.player1 = typingJunk.text.trim();
		_song.player2 = typingSopar.text.trim();
		_song.player3 = typingSussy.text.trim();
		_song.player4 = typingPLSBETHELASTONEEE.text.trim();

		if (Character.charArray.contains(_song.player1)
			&& Character.charArray.contains(_song.player2)
			&& Character.charArray.contains(_song.player3)
			&& Character.charArray.contains(_song.player4))
			theCoolText.visible = false;
		else
			theCoolText.visible = true;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep > 16 * (curSection + 1))
		{
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		curRenderedNotes.forEach(function(daNote:Note)
		{
			if (daNote.wasGoodHit && !daNote.didThing && FlxG.sound.music.playing)
			{
				daNote.didThing = true;
				if (_song.notes[curSection].mustHitSection)
				{
					switch (daNote.noteData)
					{
						case 0:
							char1.playAnim('singLEFT', true);
						case 1:
							char1.playAnim('singDOWN', true);
						case 2:
							char1.playAnim('singUP', true);
						case 3:
							char1.playAnim('singRIGHT', true);
						case 4:
							char2.playAnim('singLEFT', true);
						case 5:
							char2.playAnim('singDOWN', true);
						case 6:
							char2.playAnim('singUP', true);
						case 7:
							char2.playAnim('singRIGHT', true);
					}
				}
				else
				{
					switch (daNote.noteData)
					{
						case 0:
							char2.playAnim('singLEFT', true);
						case 1:
							char2.playAnim('singDOWN', true);
						case 2:
							char2.playAnim('singUP', true);
						case 3:
							char2.playAnim('singRIGHT', true);
						case 4:
							char1.playAnim('singLEFT', true);
						case 5:
							char1.playAnim('singDOWN', true);
						case 6:
							char1.playAnim('singUP', true);
						case 7:
							char1.playAnim('singRIGHT', true);
					}
				}
			}
		});

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;

			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();
			FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E && !recording)
		{
			changeNoteSustain(Conductor.stepCrochet);
		}
		if (FlxG.keys.justPressed.Q && !recording)
		{
			changeNoteSustain(-Conductor.stepCrochet);
		}

		if (FlxG.keys.justPressed.TAB && !recording)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else
			{
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus && !typingJunk.hasFocus && !typingSopar.hasFocus && !typingSussy.hasFocus && !typingPLSBETHELASTONEEE.hasFocus)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (recording && FlxG.sound.music.playing)
			{
				if (controls.LEFT)
					leftHold++;
				else
					leftHold = 0;

				if (controls.DOWN)
					downHold++;
				else
					downHold = 0;

				if (controls.UP)
					upHold++;
				else
					upHold = 0;

				if (controls.RIGHT)
					rightHold++;
				else
					rightHold = 0;

				if (!recSnap)
				{
					if (controls.LEFT_P)
						addNoteFromKeyPress(FlxG.sound.music.time, 0);
					if (controls.DOWN_P)
						addNoteFromKeyPress(FlxG.sound.music.time, 1);
					if (controls.UP_P)
						addNoteFromKeyPress(FlxG.sound.music.time, 2);
					if (controls.RIGHT_P)
						addNoteFromKeyPress(FlxG.sound.music.time, 3);
				}
				else
				{
					if (controls.LEFT_P)
						addNoteFromKeyPress((curStep + 1) * Conductor.stepCrochet, 0);
					if (controls.DOWN_P)
						addNoteFromKeyPress((curStep + 1) * Conductor.stepCrochet, 1);
					if (controls.UP_P)
						addNoteFromKeyPress((curStep + 1) * Conductor.stepCrochet, 2);
					if (controls.RIGHT_P)
						addNoteFromKeyPress((curStep + 1) * Conductor.stepCrochet, 3);
				}
			}

			if (FlxG.keys.justPressed.R && !recording)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0 && !recording)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT && !recording)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
			else if (!recording)
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;
		if (FlxG.keys.justPressed.RIGHT && !recording || FlxG.keys.justPressed.D && !recording)
			changeSection(curSection + shiftThing);
		if (FlxG.keys.justPressed.LEFT && !recording || FlxG.keys.justPressed.A && !recording)
			changeSection(curSection - shiftThing);

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			trace("DEEZ " + _song.notes[sec].bpm);
			curSection = sec;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
		}
	}

	var curCopiedSection:Array<Array<Dynamic>> = [];

	function pasteSection()
	{
		for (note in curCopiedSection)
		{
			var newStrum = note[0] + (Conductor.stepCrochet * (_song.notes[curSection].lengthInSteps * curSection));

			var newNote:Array<Dynamic> = [newStrum, note[1], note[2]];
			trace('PASTING NOTE $newNote');
			_song.notes[curSection].sectionNotes.push(newNote);
		}
		trace(_song.notes[curSection].sectionNotes);
		updateGrid();
	}

	function copySection()
	{
		curCopiedSection = [];
		for (note in _song.notes[curSection].sectionNotes)
		{
			var strum = note[0] - (Conductor.stepCrochet * (_song.notes[curSection].lengthInSteps * curSection));

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			curCopiedSection.push(copiedNote);
		}
		trace(curCopiedSection);
	}

	function copyLastSection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_getComboSection.checked = sec.getComboSection;
		check_altAnim.checked = sec.altAnim;
		check_gspotAnim.checked = sec.gspotAnim;
		check_dontplayAnim.checked = sec.dontplayAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		if (check_mustHitSection.checked)
		{
			leftIcon.loadIcon(_song.player1);
			rightIcon.loadIcon(_song.player2);
		}
		else
		{
			leftIcon.loadIcon(_song.player2);
			rightIcon.loadIcon(_song.player1);
		}
	}

	function reloadChars():Void
	{
		if (char1 != null)
		{
			remove(char1);
			char1.kill();
		}
		if (char2 != null)
		{
			remove(char2);
			char2.kill();
		}

		char1 = new Character(0, 0, _song.player1, true);
		char2 = new Character(0, 0, _song.player2);

		char1.screenCenter();
		char2.screenCenter();
		char1.x += FlxG.width / 2.5;
		char2.x -= FlxG.width / 2.5;

		char1.scrollFactor.set();
		char2.scrollFactor.set();

		add(char1);
		add(char2);
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Int = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];

			var note:Note = new Note(daStrumTime, daNoteInfo % 4);
			if (i[3])
				note.color = FlxColor.BLACK;
			note.sustainLength = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

			curRenderedNotes.add(note);

			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)));
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			getComboSection: false,
			bustomMaps: [],
			typeOfSection: 0,
			altAnim: false,
			gspotAnim: false,
			dontplayAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (FlxG.save.data.inputSystem == 'Kade Engine')
			{
				if (i.strumTime - FlxG.save.data.offset == note.strumTime - FlxG.save.data.offset && i.noteData % 4 == note.noteData)
				{
					curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
				}
			}
			else
			{
				if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
				{
					curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
				}
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (FlxG.save.data.inputSystem == 'Kade Engine')
			{
				if (i[0] == note.strumTime - FlxG.save.data.offset && i[1] % 4 == note.noteData)
				{
					FlxG.log.add('FOUND EVIL NUMBER');
					_song.notes[curSection].sectionNotes.remove(i);
				}
			}
			else
			{
				if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
				{
					FlxG.log.add('FOUND EVIL NUMBER');
					_song.notes[curSection].sectionNotes.remove(i);
				}
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNoteFromKeyPress(strumTime:Float, noteData:Int, noteSus:Float = 0):Void
	{
		_song.notes[curSection].sectionNotes.push([strumTime, noteData, noteSus]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		trace('RECORDED NOTE!! \nstrumTime: $strumTime \nnoteData: $noteData \nlength: $noteSus');

		updateGrid();
		updateNoteUI();

		var coolNote = curSelectedNote;

		switch (noteData)
		{
			case 0:
				new FlxTimer().start(0.001, function(offsetTmr:FlxTimer)
				{
					new FlxTimer().start(0, function(tmr:FlxTimer)
					{
						coolNote[2] = leftHold;
						if (leftHold > 0)
							tmr.reset();
					});
				});
		}
	}

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, FlxG.keys.pressed.ALT]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, FlxG.keys.pressed.ALT]);
		}

		trace(noteStrum);
		trace(curSection);

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	function calculateSectionLengths(?sec:SwagSection):Int
	{
		var daLength:Int = 0;

		for (i in _song.notes)
		{
			var swagLength = i.lengthInSteps;

			if (i.typeOfSection == Section.COPYCAT)
				swagLength * 2;

			daLength += swagLength;

			if (sec != null && sec == i)
			{
				trace('swag loop??');
				break;
			}
		}

		return daLength;
	}

	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJsonHard(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase() + '-hard', song.toLowerCase());
		FlxG.resetState();
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song,
			"bpm": Conductor.bpm,
			"sections": _song.notes.length,
			'notes': _song.notes
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song,
			"bpm": Conductor.bpm,
			"sections": _song.notes.length,
			'notes': _song.notes
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
