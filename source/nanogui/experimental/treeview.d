///
module nanogui.experimental.treeview;

/*
	NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
	The widget drawing code is based on the NanoVG demo application
	by Mikko Mononen.

	All rights reserved. Use of this source code is governed by a
	BSD-style license that can be found in the LICENSE.txt file.
*/

import nanogui.widget;
import nanogui.common : Vector2i, Vector2f, MouseButton;

/**
 * Tree view widget.
 *
 * Remarks:
 *     This class overrides `nanogui.Widget.mIconExtraScale` to be `1.2f`,
 *     which affects all subclasses of this Widget.  Subclasses must explicitly
 *     set a different value if needed (e.g., in their constructor).
 */
class TreeView : Widget
{
	import nanogui.experimental.utils : DataItem;
public:
	/**
	 * Adds a TreeView to the specified `parent`.
	 *
	 * Params:
	 *     parent   = The Widget to add this TreeView to.
	 *     caption  = The caption text of the TreeView (default `"Untitled"`).
	 *     callback = If provided, the callback to execute when the TreeView is 
	 *     checked or unchecked.  Default parameter function does nothing.  See
	 *     `nanogui.TreeView.mPushed` for the difference between "pushed"
	 *     and "checked".
	 */
	this(Widget parent, const string caption, void delegate(bool) callback)
	{
		super(parent);
		mCaption = caption;
		mPushed = false;
		mChecked = false;
		mCallback = callback;
		mIconExtraScale = 1.2f;// widget override

		const shift = cast(int)(fontSize() * 1.3f);
		import std.random, std.conv;
		foreach(i; 0..uniform(2, 5))
		{
			items ~= DataItem!string(text("item", i), Vector2i(120, cast(int)(fontSize() * 1.3f)));
		}
	}

	/// The caption of this TreeView.
	final string caption() const { return mCaption; }

	/// Sets the caption of this TreeView.
	final void caption(string caption) { mCaption = caption; }

	/// Whether or not this TreeView is currently checked.
	final bool checked() const { return mChecked; }

	/// Sets whether or not this TreeView is currently checked.
	final void checked(bool checked) { mChecked = checked; }

	/// Whether or not this TreeView is currently pushed.  See `nanogui.TreeView.mPushed`.
	final bool pushed() const { return mPushed; }

	/// Sets whether or not this TreeView is currently pushed.  See `nanogui.TreeView.mPushed`.
	final void pushed(bool pushed) { mPushed = pushed; }

	/// Returns the current callback of this TreeView.
	final void delegate(bool) callback() const { return mCallback; }

	/// Sets the callback to be executed when this TreeView is checked / unchecked.
	final void callback(void delegate(bool) callback) { mCallback = callback; }

	/**
	 * The mouse button callback will return `true` when all three conditions are met:
	 *
	 * 1. This TreeView is "enabled" (see `nanogui.Widget.mEnabled`).
	 * 2. `p` is inside this TreeView.
	 * 3. `button` is `MouseButton.Left`.
	 *
	 * Since a mouse button event is issued for both when the mouse is pressed, as well
	 * as released, this function sets `nanogui.TreeView.mPushed` to `true` when
	 * parameter `down == true`.  When the second event (`down == false`) is fired,
	 * `nanogui.TreeView.mChecked` is inverted and `nanogui.TreeView.mCallback`
	 * is called.
	 *
	 * That is, the callback provided is only called when the mouse button is released,
	 * **and** the click location remains within the TreeView boundaries.  If the user
	 * clicks on the TreeView and releases away from the bounds of the TreeView,
	 * `nanogui.TreeView.mPushed` is simply set back to `false`.
	 */
	override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
	{
		super.mouseButtonEvent(p, button, down, modifiers);
		if (!mEnabled)
			return false;

		if (button == MouseButton.Left)
		{
			if (down)
			{
				mPushed = true;
			}
			else if (mPushed)
			{
				if (contains(p))
				{
					mChecked = !mChecked;
					if (mCallback)
						mCallback(mChecked);
				}
				mPushed = false;
			}
			return true;
		}
		return false;
	}

	/// The preferred size of this TreeView.
	override Vector2i preferredSize(NVGContext nvg) const
	{
		if (mFixedSize != Vector2i())
			return mFixedSize;
		nvg.fontSize(fontSize());
		nvg.fontFace("sans");
		float[4] bounds;
		const extra = mChecked ? (fontSize() * 1.3f * items.length) : 0;
		return cast(Vector2i) Vector2f(
			(nvg.textBounds(0, 0, mCaption, bounds[]) +
				1.8f * fontSize()),
			fontSize() * 1.3f + extra);
	}

	/// Draws this TreeView.
	override void draw(NVGContext nvg)
	{
		super.draw(nvg);

		nvg.fontSize(fontSize);
		nvg.fontFace("sans");
		nvg.fillColor(mEnabled ? mTheme.mTextColor : mTheme.mDisabledTextColor);
		NVGTextAlign algn;
		algn.left = true;
		algn.middle = true;
		nvg.textAlign(algn);
		Vector2i titleSize;
		if (mChecked)
		{
			titleSize = mSize;
			titleSize.y = cast(int) (fontSize() * 1.3f);
		}
		else
			titleSize = mSize;
		nvg.text(mPos.x + 1.6f * fontSize, mPos.y + titleSize.y * 0.5f,
				mCaption);

		NVGPaint bg = nvg.boxGradient(mPos.x + 1.5f, mPos.y + 1.5f,
									 titleSize.y - 2.0f, titleSize.y - 2.0f, 3, 3,
									 mPushed ? Color(0, 0, 0, 100) : Color(0, 0, 0, 32),
									 Color(0, 0, 0, 180));

		nvg.beginPath;
		nvg.roundedRect(mPos.x + 1.0f, mPos.y + 1.0f, titleSize.y - 2.0f,
					   titleSize.y - 2.0f, 3);
		nvg.fillPaint(bg);
		nvg.fill;

		nvg.fontSize(titleSize.y * icon_scale());
		nvg.fontFace("icons");
		nvg.fillColor(mEnabled ? mTheme.mIconColor
									: mTheme.mDisabledTextColor);
		algn = NVGTextAlign();
		algn.center = true;
		algn.middle = true;
		nvg.textAlign(algn);

		import nanogui.entypo : Entypo;
		nvg.text(mPos.x + titleSize.y * 0.5f + 1,
				mPos.y + titleSize.y * 0.5f, 
				[mChecked ? cast(dchar)Entypo.ICON_CHEVRON_DOWN :
							cast(dchar)Entypo.ICON_CHEVRON_RIGHT
				]);

		if (mChecked)
		{
			nvg.fontSize(fontSize);
			nvg.fontFace("sans");
			algn.left = true;
			algn.middle = true;
			nvg.textAlign(algn);
			import nanogui.experimental.utils : Context;
			auto ctx = Context(nvg);
			ctx.position.x = 20;
			ctx.position.y = 60;
			foreach(item; items)
			{
				item.draw(ctx, "header", 20);
			}
		}
	}

// // Saves this TreeView to the specified Serializer.
//override void save(Serializer &s) const;

// // Loads the state of the specified Serializer to this TreeView.
//override bool load(Serializer &s);

protected:
	/// The caption text of this TreeView.
	string mCaption;

	/**
	 * Internal tracking variable to distinguish between mouse click and release.
	 * `nanogui.TreeView.mCallback` is only called upon release.  See
	 * `nanogui.TreeView.mouseButtonEvent` for specific conditions.
	 */
	bool mPushed;

	/// Whether or not this TreeView is currently checked or unchecked.
	bool _mChecked;
	
	bool mChecked() const { return _mChecked; };
	auto mChecked(bool v)
	{
		if (_mChecked != v)
		{
			_mChecked = v;
			import std.stdio;
			writeln("mChecked changed: ", v);
			mSize += Vector2i(0, v ? 100 : -100);
			screen.needToPerfomLayout = true;
		}
	}

	DataItem!string[] items;

	/// The function to execute when `nanogui.TreeView.mChecked` is changed.
	void delegate(bool) mCallback;
}
