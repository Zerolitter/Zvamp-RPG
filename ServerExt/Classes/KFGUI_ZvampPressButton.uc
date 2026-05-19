// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_ZvampPressButton extends KFGUI_ZvampFooterButton;

function MouseClick(bool bRight)
{
	if (!bDisabled)
	{
		bPressedDown = true;
		HandleMouseClick(bRight);
		bPressedDown = false;
		PressedDown[0] = 0;
		PressedDown[1] = 0;
	}
}

function MouseRelease(bool bRight)
{
	PressedDown[0] = 0;
	PressedDown[1] = 0;
	bPressedDown = false;
}
