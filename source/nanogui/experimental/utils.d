module nanogui.experimental.utils;

struct DataItem(T)
{
	import std.traits : isAggregateType, isPointer, isArray, isSomeString, isAssociativeArray;
	import gfm.math : vec2i;
	import arsd.nanovega : NVGTextAlign, textAlign, text;
	import nanogui.common : Vector2i;

	enum textBufferSize = 1024;

	T content;
	private vec2i _position;
	private vec2i _size;

	this(string c, vec2i s)
	{
		content = c;
		_size = s;
	}

	auto draw(Context)(Context ctx, const(char)[] header)
		if (!isAggregateType!T && 
			!isPointer!T &&
			(!isArray!T || isSomeString!T) &&
			!isAssociativeArray!T)
	{
		// import core.stdc.stdio : snprintf;
		import std.format : sformat;
		import std.traits : isIntegral, isFloatingPoint, isBoolean;

		char[textBufferSize] buffer;
		size_t l;
		if (header.length)
			l = sformat(buffer, "%s: ", header).length;

		// format specifier depends on type
		static if (is(T == enum))
		{
			const s = content.enumToString;
			l += sformat(buffer[l..$], min(buffer.length-l, s.length), "%s", s).length;
		}
		else static if (isIntegral!T)
			l += sformat(buffer[l..$], "%d", content).length;
		else static if (isFloatingPoint!T)
			l += sformat(buffer[l..$], "%f", content).length;
		else static if (isBoolean!T)
			l += sformat(buffer[l..$], content ? "true\0" : "false\0").length;
		else static if (isSomeString!T)
			l += sformat(buffer[l..$], "%s", content).length;
		else
			static assert(0, T.stringof);

		NVGTextAlign algn;
		algn.left = true;
		algn.middle = true;
		ctx.textAlign(algn);
		ctx.text(position.x, position.y + size.y * 0.5f, buffer[0..l]);
	}

	// auto draw(Context)(Context ctx, const(char)[] header)
	// 	if (isAggregateType!T)// && !isInstanceOf!(TaggedAlgebraic, T) && !isNullable!T)
	// {
	// 	// static if (DrawnAsAvailable)
	// 	// {
	// 	// 	nk_layout_row_dynamic(ctx, itemHeight, 1);
	// 	// 	static if (Cached)
	// 	// 		state_drawn_as.draw(ctx, header, cached);
	// 	// 	else
	// 	// 		state_drawn_as.draw(ctx, "", t.drawnAs);
	// 	// }
	// 	// else
	// 	static if (DrawableMembers!t.length == 1)
	// 	{
	// 		static foreach(member; DrawableMembers!t)
	// 			mixin("state_" ~ member ~ ".draw(ctx, \"" ~ member ~"\", t." ~ member ~ ");");
	// 	}
	// 	else
	// 	{
	// 		import core.stdc.stdio : sprintf;
			
	// 		char[textBufferSize] buffer;
	// 		snprintf(buffer.ptr, buffer.length, "%s", header.ptr);

	// 		if (nk_tree_state_push(ctx, NK_TREE_NODE, buffer.ptr, &collapsed))
	// 		{
	// 			scope(exit)
	// 				nk_tree_pop(ctx);
				
	// 			static foreach(member; DrawableMembers!t) 
	// 			{
	// 				mixin("height += state_" ~ member ~ ".draw(ctx, \"" ~ member ~"\", t." ~ member ~ ");");
	// 			}
	// 		}
	// 	}
	// }

	auto visible() const nothrow @safe pure @nogc { return true; }
	auto performLayout(NVG)(NVG nvg) { };

	auto position() const nothrow @safe pure @nogc { return _position; }
	auto position(vec2i v) nothrow @safe pure @nogc { _position = v; }

	auto size() const nothrow @safe pure @nogc { return _size; }
	auto size(vec2i v) nothrow @safe pure @nogc { _size = v; }

	auto preferredSize(NVG)(NVG nvg) const { return Vector2i(0, 0); }
	auto fixedSize()  const nothrow @safe pure @nogc  { return _size; }
}