package base.debug;

import flixel.FlxG;
import haxe.Timer;
import openfl.Lib;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
	Overlay that displays FPS and memory usage.

	Based on this tutorial:
	https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
**/
class Overlay extends TextField
{
	var times:Array<Float> = [];
	var memPeak:Float = 0;

	// display info
	static var displayFps = true;
	static var displayMemory = true;
	static var displayExtra = true;
	static var displayForever = true;

	public function new(x:Float, y:Float)
	{
		super();

		this.x = x;
		this.y = x;

		autoSize = LEFT;
		selectable = false;

		defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 18, -1);
		text = "";

		addEventListener(Event.ENTER_FRAME, update);
	}

	static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']; // tb support for the myth engine modders :)

	public static function getInterval(size:Float):String
	{
		var data = 0;
		while (size > 1024 && data < intervalArray.length - 1)
		{
			data++;
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		return size + " " + intervalArray[data];
	}

	function update(_:Event)
	{
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		#if cpp
		var mem:Float = cpp.vm.Gc.memInfo64(3);
		#else
		var mem:Float = openfl.system.System.totalMemory.toFloat();
		#end

		if (mem > memPeak)
			memPeak = mem;

		if (visible)
		{
			text = '' // set up the text itself
				+ (displayFps ? times.length + " FPS\n" : '') // Framerate
				+ (displayMemory ? '${getInterval(mem)} / ${getInterval(memPeak)}\n' : '') // Current and Total Memory Usage
				+ (displayExtra ? 'State Object Count: ${FlxG.state.members.length}\n' : ''); // Current Game State Object Count
		}
	}

	public static function updateDisplayInfo(shouldDisplayFps:Bool, shouldDisplayExtra:Bool, shouldDisplayMemory:Bool, shouldDisplayForever:Bool)
	{
		displayFps = shouldDisplayFps;
		displayExtra = shouldDisplayExtra;
		displayMemory = shouldDisplayMemory;
		displayForever = shouldDisplayForever;
	}
}