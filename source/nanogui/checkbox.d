module nanogui.checkbox;

/*
	NanoGUI was developed by Wenzel Jakob <wenzel.jakob@epfl.ch>.
	The widget drawing code is based on the NanoVG demo application
	by Mikko Mononen.

	All rights reserved. Use of this source code is governed by a
	BSD-style license that can be found in the LICENSE.txt file.
*/
/**
 * \file nanogui/checkbox.h
 *
 * \brief Two-state check box Widget.
 */

import nanogui.widget;
import nanogui.common : Vector2i, Vector2f;
import nanogui.nanogui : MouseButton;

/**
 * \class CheckBox checkbox.h nanogui/checkbox.h
 *
 * \brief Two-state check box widget.
 *
 * \remark
 *     This class overrides \ref nanogui::Widget::mIconExtraScale to be ``1.2f``,
 *     which affects all subclasses of this Widget.  Subclasses must explicitly
 *     set a different value if needed (e.g., in their constructor).
 */
class CheckBox : Widget
{
public:
	/**
	 * Adds a CheckBox to the specified ``parent``.
	 *
	 * \param parent
	 *     The Widget to add this CheckBox to.
	 *
	 * \param caption
	 *     The caption text of the CheckBox (default ``"Untitled"``).
	 *
	 * \param callback
	 *     If provided, the callback to execute when the CheckBox is checked or
	 *     unchecked.  Default parameter function does nothing.  See
	 *     \ref nanogui::CheckBox::mPushed for the difference between "pushed"
	 *     and "checked".
	 */
	this(Widget parent, const string caption, void delegate(bool) callback)
	{
		super(parent);
		mCaption = caption;
		mPushed = false;
		mChecked = false;
		mCallback = callback;
		mIconExtraScale = 1.2f;// widget override}
	}

	/// The caption of this CheckBox.
	final string caption() const { return mCaption; }

	/// Sets the caption of this CheckBox.
	final void caption(string caption) { mCaption = caption; }

	/// Whether or not this CheckBox is currently checked.
	final bool checked() const { return mChecked; }

	/// Sets whether or not this CheckBox is currently checked.
	final void checked(bool checked) { mChecked = checked; }

	/// Whether or not this CheckBox is currently pushed.  See \ref nanogui::CheckBox::mPushed.
	final bool pushed() const { return mPushed; }

	/// Sets whether or not this CheckBox is currently pushed.  See \ref nanogui::CheckBox::mPushed.
	final void pushed(bool pushed) { mPushed = pushed; }

	/// Returns the current callback of this CheckBox.
	final void delegate(bool) callback() const { return mCallback; }

	/// Sets the callback to be executed when this CheckBox is checked / unchecked.
	final void callback(void delegate(bool) callback) { mCallback = callback; }

	/**
	 * The mouse button callback will return ``true`` when all three conditions are met:
	 *
	 * 1. This CheckBox is "enabled" (see \ref nanogui::Widget::mEnabled).
	 * 2. ``p`` is inside this CheckBox.
	 * 3. ``button`` is ``GLFW_MOUSE_BUTTON_1`` (left mouse click).
	 *
	 * Since a mouse button event is issued for both when the mouse is pressed, as well
	 * as released, this function sets \ref nanogui::CheckBox::mPushed to ``true`` when
	 * parameter ``down == true``.  When the second event (``down == false``) is fired,
	 * \ref nanogui::CheckBox::mChecked is inverted and \ref nanogui::CheckBox::mCallback
	 * is called.
	 *
	 * That is, the callback provided is only called when the mouse button is released,
	 * **and** the click location remains within the CheckBox boundaries.  If the user
	 * clicks on the CheckBox and releases away from the bounds of the CheckBox,
	 * \ref nanogui::CheckBox::mPushed is simply set back to ``false``.
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
				//if (contains(p))
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

	/// The preferred size of this CheckBox.
	override Vector2i preferredSize(NVGContext nvg) const
	{
		if (mFixedSize != Vector2i())
			return mFixedSize;
		nvg.fontSize(fontSize());
		nvg.fontFace("sans");
		float[4] bounds;
		return cast(Vector2i) Vector2f(
			(nvg.textBounds(0, 0, mCaption, bounds[]) +
				1.8f * fontSize()),
			fontSize() * 1.3f);
	}

	/// Draws this CheckBox.
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
		nvg.text(mPos.x + 1.6f * fontSize, mPos.y + mSize.y * 0.5f,
				mCaption);

		NVGPaint bg = nvg.boxGradient(mPos.x + 1.5f, mPos.y + 1.5f,
									 mSize.y - 2.0f, mSize.y - 2.0f, 3, 3,
									 mPushed ? Color(0, 0, 0, 100) : Color(0, 0, 0, 32),
									 Color(0, 0, 0, 180));

		nvg.beginPath;
		nvg.roundedRect(mPos.x + 1.0f, mPos.y + 1.0f, mSize.y - 2.0f,
					   mSize.y - 2.0f, 3);
		nvg.fillPaint(bg);
		nvg.fill;

		if (mChecked)
		{
			nvg.fontSize(mSize.y * icon_scale());
			nvg.fontFace("icons");
			nvg.fillColor(mEnabled ? mTheme.mIconColor
									   : mTheme.mDisabledTextColor);
			algn = NVGTextAlign();
			algn.center = true;
			algn.middle = true;
			nvg.textAlign(algn);
			nvg.text(mPos.x + mSize.y * 0.5f + 1,
					mPos.y + mSize.y * 0.5f, mTheme.mCheckBoxIcon);
		}
	}

///// Saves this CheckBox to the specified Serializer.
//override void save(Serializer &s) const;

///// Loads the state of the specified Serializer to this CheckBox.
//override bool load(Serializer &s);

protected:
	/// The caption text of this CheckBox.
	string mCaption;

	/**
	 * Internal tracking variable to distinguish between mouse click and release.
	 * \ref nanogui::CheckBox::mCallback is only called upon release.  See
	 * \ref nanogui::CheckBox::mouseButtonEvent for specific conditions.
	 */
	bool mPushed;

	/// Whether or not this CheckBox is currently checked or unchecked.
	bool mChecked;

	/// The function to execute when \ref nanogui::CheckBox::mChecked is changed.
	void delegate(bool) mCallback;
}
