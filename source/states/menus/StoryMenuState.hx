package states.menus;

import base.*;
import base.MusicBeat.MusicBeatState;
import base.SongLoader.Song;
import base.WeekParser.WeekDataDef;
import base.WeekParser.WeekSongDef;
import dependency.Discord;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Alphabet;
import funkin.Highscore;
import funkin.ui.menu.*;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	static var lastDifficultyName:String = '';

	var scoreText:FlxText;
	var curDifficulty:Int = 1;

	public static var weekCharacters:Array<Dynamic> = [];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var allWeeks:Array<WeekParser> = [];
	var weekData:Array<WeekDataDef> = [];

	override function create()
	{
		super.create();

		PlayState.chartingMode = false;
		CoolUtil.difficulties = CoolUtil.baseDifficulties;

		WeekParser.loadJsons(true);
		if (curWeek >= WeekParser.weeksList.length)
			curWeek = 0;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		#if DISCORD_RPC
		Discord.changePresence('CHOOSING A WEEK', 'Story Menu');
		#end

		// freeaaaky
		ForeverTools.resetMenuMusic();

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var weekNum:Int = 0;
		for (i in 0...WeekParser.weeksList.length)
		{
			var newWeek:Dynamic = WeekParser.loadedWeeks.get(WeekParser.weeksList[i]);
			var weekImage = WeekParser.loadedWeeks.get(WeekParser.weeksList[i]).weekImage;

			var lockedWeek:Bool = checkLock(WeekParser.weeksList[i]);

			if (!WeekParser.loadedWeeks.get(WeekParser.weeksList[i]).hideStoryMode)
			{
				allWeeks.push(newWeek);

				// creates the week image label;
				var weekImageLabel:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weekImage);
				weekImageLabel.y += ((weekImageLabel.height + 20) * weekNum);
				weekImageLabel.targetY = weekNum;
				grpWeekText.add(weekImageLabel);

				weekImageLabel.screenCenter();
				weekImageLabel.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
				// weekImageLabel.updateHitbox();

				// Needs an offset thingie
				if (lockedWeek)
				{
					var lock:FlxSprite = new FlxSprite(weekImageLabel.width + 10 + weekImageLabel.x);
					lock.frames = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
					grpLocks.add(lock);
				}
				weekNum++;
			}
		}

		#if DEBUG_TRACES trace("Line 96"); #end

		var weekChars = WeekParser.loadedWeeks.get(WeekParser.weeksList[curWeek]).weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, weekChars[char]);
			weekCharacterThing.antialiasing = !Init.trueSettings.get('Disable Antialiasing');
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		#if DEBUG_TRACES trace("Line 124"); #end

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		if (lastDifficultyName == '')
		{
			lastDifficultyName = 'NORMAL';
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.difficulties.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = !Init.trueSettings.get('Disable Antialiasing');

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		#if DEBUG_TRACES trace("Line 150"); #end

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		// very unprofessional yoshubs!

		changeDifficulty();
		updateText();
	}

	override function update(elapsed:Float)
	{
		var lerpVal = Main.framerateAdjust(0.5);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, lerpVal));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UI_UP_P)
					changeWeek(-1);
				else if (controls.UI_DOWN_P)
					changeWeek(1);

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P)
					changeDifficulty(1);
				if (controls.UI_LEFT_P)
					changeDifficulty(-1);

				if (FlxG.mouse.wheel != 0)
				{
					changeWeek(-FlxG.mouse.wheel);
					changeDifficulty();
				}
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
				selectWeek();
		}

		if (controls.BACK || FlxG.mouse.justPressedRight && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			Main.switchState(this, new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		var locked = checkLock(WeekParser.weeksList[curWeek]);

		if (!locked)
		{
			//Main.isSongTrans = true;

			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				for (char in grpWeekCharacters.members)
					if (char.character != "" && char.charJson.heyAnim != null)
						char.animation.play('hey');
				stopspamming = true;
			}

			var baseWeek = WeekParser.loadedWeeks.get(WeekParser.weeksList[curWeek]);
			var songArray:Array<String> = [];

			// get songs from the week and push them to the song array;
			for (i in 0...baseWeek.songs.length)
			{
				songArray.push(baseWeek.songs[i].name);
			}

			if (songArray != null)
				PlayState.storyPlaylist = songArray;

			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic:String = '-' + CoolUtil.difficultyFromNumber(curDifficulty).toLowerCase();
			diffic = diffic.replace('-normal', '');

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadSong(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				Main.switchState(this, new PlayState());
			});
		}
	}

	function checkLock(week:String):Bool
	{
		var weekName = WeekParser.loadedWeeks.get(week);
		return (weekName.locked);
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyLength - 1;
		if (curDifficulty > CoolUtil.difficultyLength - 1)
			curDifficulty = 0;

		var diff:String = CoolUtil.difficulties[curDifficulty];
		var newImage:FlxGraphic = Paths.image('menus/base/storymenu/difficulties/' + Paths.songPath(diff));

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null)
				tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});
		}
		lastDifficultyName = diff;

		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= allWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = allWeeks.length - 1;

		var locked:Bool = checkLock(WeekParser.weeksList[curWeek]);

		difficultySelectors.visible = !locked;

		var weekTitle = WeekParser.loadedWeeks.get(WeekParser.weeksList[curWeek]).weekName;
		txtWeekTitle.text = weekTitle.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && !locked)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		var weekChars = WeekParser.loadedWeeks.get(WeekParser.weeksList[curWeek]).weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].createCharacter(weekChars[i], true);
		}
		txtTracklist.text = "Tracks\n";

		var baseWeek = WeekParser.loadedWeeks.get(WeekParser.weeksList[curWeek]);
		var stringThing:Array<String> = [];

		for (i in 0...baseWeek.songs.length)
		{
			stringThing.push(baseWeek.songs[i].name);
		}

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + CoolUtil.dashToSpace(i);
		}

		txtTracklist.text += "\n"; // pain
		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
	}
}
