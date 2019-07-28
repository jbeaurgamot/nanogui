///
module nanogui.experimental.list;

import std.algorithm : min, max;
import nanogui.widget;
import nanogui.common : MouseButton, Vector2f, Vector2i, NVGContext;
import nanogui.experimental.utils : DataItem;

private class ListImplementor : Widget
{
	DataItem!string[] data;

	private
	{
		size_t _scroll_position;
		size_t _start_item;
		size_t _finish_item;
	}

	this(Widget p)
	{
		super(p);

		data.reserve(400_000);
		foreach(i; 0..400_000)
		{
			{
				import std.conv : text;
				import std.random : uniform;
				data ~= DataItem!string(text("item", i), Vector2i(80, 30 + uniform(0, 30)));
			}
		}
		_scroll_position = _scroll_position.max;
	}

	/// Draw the widget (and all child widgets)
	override void draw(NVGContext nvg)
	{
		int fontSize = mFontSize == -1 ? mTheme.mButtonFontSize : mFontSize;
		nvg.fontSize(fontSize);
		nvg.fontFace("sans-bold");

		nvg.save;
		nvg.translate(mPos.x, mPos.y);

		import std.math : approxEqual;
		auto l = cast(List) parent;
		const scroll_position = cast(size_t) (l.mScroll * (size.y - l.size.y));
		if (_scroll_position != scroll_position)
		{
			heightToItemIndex(scroll_position, scroll_position + l.size.y, _start_item, _finish_item);
			_scroll_position = scroll_position;
		}

		import nanogui.experimental.utils : Context;
		auto ctx = Context(nvg);

		import std.algorithm : min;
		foreach(child; data[_start_item..min(_finish_item, $)])
		{
			nvg.save;
			scope(exit) nvg.restore;

			ctx.position.x = child.position.x;
			ctx.position.y = child.position.y;

			child.draw(ctx, "");
		}
		nvg.restore;
	}

	/// Convert given range of List height to corresponding items indices
	private auto heightToItemIndex(double start, double finish, ref size_t start_index, ref size_t last_index)
	{
		import nanogui.layout : BoxLayout;
		double curr = (cast(BoxLayout) mLayout).margin;
		size_t idx;
		assert(start < finish);
		start_index = 0;
		last_index = 0;

		if (finish < curr)
			return;

		foreach(ref const e; data)
		{
			curr += e.size.y;
			if (curr >= start)
			{
				start_index = idx;
				break;
			}
			idx++;
		}

		if (idx == data.length)
		{
			start_index = last_index = data.length;
			return; // start (and finish too) is beyond the last index
		}

		const low_boundary = ++idx;
		foreach(ref const e; data[low_boundary..$])
		{
			curr += e.size.y;
			if (curr >= finish)
			{
				last_index = idx;
				break;
			}
			idx++;
		}

		if (idx == data.length)
			last_index = idx; // start is before and finish is beyond the last index
	}

	/// Convert given range of items indices to to corresponding List height range
	private auto itemIndexToHeight(size_t start_index, size_t last_index, ref float start, ref float finish)
	{
		import nanogui.layout : BoxLayout;
		double curr = (cast(BoxLayout) mLayout).margin;
		size_t idx;
		assert(start_index < last_index);
		start = 0;
		finish = 0;

		foreach(ref const e; data)
		{
			if (idx >= start_index)
			{
				start = curr;
				idx++;
				curr += e.size.y;
				break;
			}
			idx++;
			curr += e.size.y;
		}

		if (start_index >= data.length)
		{
			finish = start;
			return;
		}

		const low_boundary = ++idx;
		foreach(ref const e; data[low_boundary..$])
		{
			if (idx >= last_index)
			{
				finish = curr;
				break;
			}
			idx++;
			curr += e.size.y;
		}

		if (last_index >= data.length)
			finish = curr;
	}

	/// Compute the preferred size of the widget
	override Vector2i preferredSize(NVGContext nvg) const
	{
		static Vector2i[size_t] size_inited;

		if (this.hashOf !in size_inited)
			size_inited[hashOf(this)] = Vector2i();
		else if (size_inited[this.hashOf] != Vector2i())
			return size_inited[hashOf(this)];

		import nanogui.window : Window;
		import nanogui.layout : BoxLayout, Orientation;

		auto layout = cast(BoxLayout) mLayout;
		assert(layout);
		Vector2i size = Vector2i(2*layout.margin, 2*layout.margin);
		int yOffset = 0;
		auto widget = this;
		auto window = cast(Window) widget;
		if (window && window.title().length) {
			if (layout.orientation == Orientation.Vertical)
				size[1] += widget.theme.mWindowHeaderHeight - layout.margin/2;
			else
				yOffset = widget.theme.mWindowHeaderHeight;
		}

		bool first = true;
		int axis1 = cast(int) layout.orientation;
		int axis2 = (cast(int) layout.orientation + 1)%2;
		foreach (w; widget.data)
		{
			if (!w.visible)
				continue;
			if (first)
				first = false;
			else
				size[axis1] += layout.spacing;

			// here we need to calculate the widget size using
			// its fixed and preferred sizes.
			// Because there is no fixed size for list items then
			// we directly get size of the item
			auto targetSize = Vector2i(
				w.size.x,
				w.size.y,
			);

			size[axis1] += targetSize[axis1];
			size[axis2] = max(size[axis2], targetSize[axis2] + 2*layout.margin);
			first = false;
		}
		size_inited[this.hashOf] = size;
		return size + Vector2i(0, yOffset);
	}

	/// Invoke the associated layout generator to properly place child widgets, if any
	override void performLayout(NVGContext nvg)
	{
		import nanogui.window : Window;
		import nanogui.layout : BoxLayout, Orientation, Alignment;

		auto layout = cast(BoxLayout) mLayout;
		assert(layout);

		auto widget = this;
		Vector2i fs_w = widget.fixedSize();
		auto containerSize = Vector2i(
			fs_w[0] ? fs_w[0] : widget.width,
			fs_w[1] ? fs_w[1] : widget.height
		);

		int axis1 = cast(int) layout.orientation;
		int axis2 = (cast(int) layout.orientation + 1)%2;
		int position = layout.margin;
		int yOffset = 0;

		import nanogui.window : Window;
		auto window = cast(const Window)(widget);
		if (window && window.title.length)
		{
			if (layout.orientation == Orientation.Vertical)
			{
				position += widget.theme.mWindowHeaderHeight - layout.margin/2;
			}
			else
			{
				yOffset = widget.theme.mWindowHeaderHeight;
				containerSize[1] -= yOffset;
			}
		}

		bool first = true;
		foreach(ref w; widget.data) {
			if (!w.visible)
				continue;
			if (first)
				first = false;
			else
				position += layout.spacing;

			// here we need to calculate the widget size using
			// its fixed and preferred sizes.
			// Because there is no fixed size for list items then
			// we directly get size of the item
			auto targetSize = Vector2i(
				w.size.x,
				w.size.y,
			);
			auto pos = Vector2i(0, yOffset);

			pos[axis1] = position;

			final switch (layout.alignment)
			{
				case Alignment.Minimum:
					pos[axis2] += layout.margin;
					break;
				case Alignment.Middle:
					pos[axis2] += (containerSize[axis2] - targetSize[axis2]) / 2;
					break;
				case Alignment.Maximum:
					pos[axis2] += containerSize[axis2] - targetSize[axis2] - layout.margin * 2;
					break;
				case Alignment.Fill:
					pos[axis2] += layout.margin;
					// targetSize[axis2] = fs[axis2] ? fs[axis2] : (containerSize[axis2] - layout.margin * 2);
					targetSize[axis2] = containerSize[axis2] - layout.margin * 2;
					break;
			}

			w.position(pos);
			w.size(targetSize);
			w.performLayout(nvg);
			position += targetSize[axis1];
		}
	}

	/// Handle a mouse button event (default implementation: propagate to children)
	override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
	{
		// foreach_reverse(ch; mChildren)
		// {
		// 	Widget child = ch;
		// 	if (child.visible && child.contains(p - mPos) &&
		// 		child.mouseButtonEvent(p - mPos, button, down, modifiers))
		// 		return true;
		// }
		// if (button == MouseButton.Left && down && !mFocused)
		// 	requestFocus();
		import std.stdio;
		writeln(__PRETTY_FUNCTION__, " ", p, " ", p.x, ", ", p.y + _scroll_position);
		size_t s, f;
		heightToItemIndex(p.y + _scroll_position, p.y + _scroll_position + 1, s, f);
		import std.stdio;
		writeln(s, " ", f);
		return false;
	}
}

class List : Widget
{
public:

	this(Widget parent)
	{
		super(parent);
		mChildPreferredHeight = 0;
		mScroll = 0.0f;
		mUpdateLayout = false;
		auto impl = new ListImplementor(this);
		impl.setId = "impl";
		impl.fixedSize(Vector2i(width, height));
		import nanogui.layout : BoxLayout, Orientation;
		auto l = new BoxLayout(Orientation.Vertical);
		l.setMargin = 40;
		impl.layout(l);
	}

	/// Return the current scroll amount as a value between 0 and 1. 0 means scrolled to the top and 1 to the bottom.
	float scroll() const { return mScroll; }
	/// Set the scroll amount to a value between 0 and 1. 0 means scrolled to the top and 1 to the bottom.
	void setScroll(float scroll) { mScroll = scroll; }

	override void performLayout(NVGContext nvg)
	{
		super.performLayout(nvg);

		if (mChildren.empty)
			return;
		if (mChildren.length > 1)
			throw new Exception("List should have one child.");

		Widget child = mChildren[0];
		mChildPreferredHeight = child.preferredSize(nvg).y;

		if (mChildPreferredHeight > mSize.y)
		{
			auto y = cast(int) (-mScroll*(mChildPreferredHeight - mSize.y));
			child.position(Vector2i(0, y));
			child.size(Vector2i(mSize.x-12, mChildPreferredHeight));
		}
		else 
		{
			child.position(Vector2i(0, 0));
			child.size(mSize);
			mScroll = 0;
		}
		child.performLayout(nvg);
	}

	override Vector2i preferredSize(NVGContext nvg) const
	{
		if (mChildren.empty)
			return Vector2i(0, 0);
		return mChildren[0].preferredSize(nvg) + Vector2i(12, 0);
	}
	
	override bool mouseDragEvent(Vector2i p, Vector2i rel, MouseButton button, int modifiers)
	{
		if (!mChildren.empty && mChildPreferredHeight > mSize.y) {
			float scrollh = height *
				min(1.0f, height / cast(float)mChildPreferredHeight);

			mScroll = max(cast(float) 0.0f, min(cast(float) 1.0f,
						mScroll + rel.y / cast(float)(mSize.y - 8 - scrollh)));
			mUpdateLayout = true;
			return true;
		} else {
			return super.mouseDragEvent(p, rel, button, modifiers);
		}
	}

	override bool scrollEvent(Vector2i p, Vector2f rel)
	{
		if (!mChildren.empty && mChildPreferredHeight > mSize.y)
		{
			assert(cast(ListImplementor) mChildren[0]);
			float s, f;
			with (cast(ListImplementor) mChildren[0])
			{
				itemIndexToHeight(_start_item, _start_item + 1, s, f);
			}
			const scrollAmount = rel.y * (f - s);
			mScroll = max(0.0f, min(1.0f, mScroll - scrollAmount/cast(float)mChildPreferredHeight));
			mUpdateLayout = true;
			return true;
		} else {
			return super.scrollEvent(p, rel);
		}
	}

	/// Handle a mouse button event (default implementation: propagate to children)
	override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
	{
		const r = super.mouseButtonEvent(p, button, down, modifiers);
		if (p.x < mPos.x + mSize.x - 12)
			return r;

		if (!down)
			return false;

		const l = mScroll * height;
		if (!mChildren.empty && mChildPreferredHeight > mSize.y)
		{
			assert(cast(ListImplementor) mChildren[0]);
			float s, f;
			with (cast(ListImplementor) mChildren[0])
			{
				itemIndexToHeight(_start_item, _finish_item, s, f);
			}
			const scrollAmount = l > p.y ? (f - s) : -(f - s);

			mScroll = max(0.0f, min(1.0f, mScroll - scrollAmount/cast(float)mChildPreferredHeight));
			mUpdateLayout = true;
			return true;
		}
		return false;
	}

	override void draw(NVGContext nvg)
	{
		if (mChildren.empty)
			return;
		Widget child = mChildren[0];
		auto y = cast(int) (-mScroll*(mChildPreferredHeight - mSize.y));
		child.position(Vector2i(0, y));
		mChildPreferredHeight = child.preferredSize(nvg).y;
		float scrollh = max(16, height *
			min(1.0f, height / cast(float) mChildPreferredHeight));

		if (mUpdateLayout)
		{
			child.performLayout(nvg);
			mUpdateLayout = false;
		}

		nvg.save;
		nvg.translate(mPos.x, mPos.y);
		nvg.intersectScissor(0, 0, mSize.x, mSize.y);
		if (child.visible)
			child.draw(nvg);
		nvg.restore;

		if (mChildPreferredHeight <= mSize.y)
			return;

		NVGPaint paint = nvg.boxGradient(
			mPos.x + mSize.x - 12 + 1, mPos.y + 4 + 1, 8,
			mSize.y - 8, 3, 4, Color(0, 0, 0, 32), Color(0, 0, 0, 92));
		nvg.beginPath;
		nvg.roundedRect(mPos.x + mSize.x - 12, mPos.y + 4, 8,
					mSize.y - 8, 3);
		nvg.fillPaint(paint);
		nvg.fill;

		paint = nvg.boxGradient(
			mPos.x + mSize.x - 12 - 1,
			mPos.y + 4 + (mSize.y - 8 - scrollh) * mScroll - 1, 8, scrollh,
			3, 4, Color(220, 220, 220, 100), Color(128, 128, 128, 100));

		nvg.beginPath;
		nvg.roundedRect(
			mPos.x + mSize.x - 12 + 1,
			mPos.y + 4 + 1 + (mSize.y - 8 - scrollh) * mScroll, 8 - 2,
			scrollh - 2, 2);
		nvg.fillPaint(paint);
		nvg.fill;
	}
	// override void save(Serializer &s) const;
	// override bool load(Serializer &s);
protected:
	int mChildPreferredHeight;
	float mScroll;
	bool mUpdateLayout;
}
