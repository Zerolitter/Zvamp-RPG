// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UI_AdminAutoMessage extends KFGUI_FloatingWindow;

var KFGUI_TextField PreviewField;
var KFGUI_EditBox MessageField, ColorField;
var KFGUI_NumericBox IntervalBox;
var KFGUI_CheckBox EnabledBox;
var KFGUI_Button SaveButton, CancelButton;

function InitMenu()
{
	Super.InitMenu();

	PreviewField = KFGUI_TextField(FindComponentID('Preview'));
	MessageField = KFGUI_EditBox(FindComponentID('Message'));
	ColorField = KFGUI_EditBox(FindComponentID('Color'));
	IntervalBox = KFGUI_NumericBox(FindComponentID('Interval'));
	EnabledBox = KFGUI_CheckBox(FindComponentID('Enabled'));
	SaveButton = KFGUI_Button(FindComponentID('Save'));
	CancelButton = KFGUI_Button(FindComponentID('Cancel'));

	WindowTitle = "Recurring Auto Message";
	EnabledBox.LableString = "Enabled";
	EnabledBox.Tooltip = "Enable recurring server chat message";
	MessageField.ToolTip = "Message text broadcast to players; separate rotating messages with ;; and optionally prefix a message with <RRGGBB>";
	ColorField.ToolTip = "Chat color as RRGGBB, for example 9B7CFF";
	IntervalBox.ToolTip = "Seconds between broadcasts";
	SaveButton.ButtonText = "SAVE";
	CancelButton.ButtonText = "CANCEL";

	if (MessageField.Value=="")
		MessageField.ChangeValue("Welcome to Zvampext RPG");
	if (ColorField.Value=="")
		ColorField.ChangeValue("9B7CFF");
	if (IntervalBox.Value=="")
		IntervalBox.ChangeValue("300");
	EnabledBox.bChecked = true;
	UpdatePreview(None);
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Save':
		IntervalBox.ValidateValue();
		ExtPlayerController(GetPlayer()).AdminSetAutoMessage(EnabledBox.bChecked,IntervalBox.GetValueInt(),MessageField.Value,ColorField.Value);
		DoClose();
		break;
	case 'Cancel':
		DoClose();
		break;
	}
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
	UpdatePreview(None);
}

function UpdatePreview(KFGUI_EditBox Sender)
{
	PreviewField.SetText("Preview|#{"$ColorField.Value$"}"$MessageField.Value$"#{DEF}|Use ;; between messages | "$Len(MessageField.Value)$"/512");
}

defaultproperties
{
	XPosition=0.18
	YPosition=0.16
	XSize=0.64
	YSize=0.60
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextField Name=PreviewText
		ID="Preview"
		XPosition=0.05
		YPosition=0.14
		XSize=0.90
		YSize=0.18
	End Object
	Components.Add(PreviewText)

	Begin Object Class=KFGUI_CheckBox Name=EnabledCheckBox
		ID="Enabled"
		XPosition=0.05
		YPosition=0.34
		XSize=0.32
		YSize=0.06
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(EnabledCheckBox)

	Begin Object Class=KFGUI_EditBox Name=MessageEditBox
		ID="Message"
		XPosition=0.05
		YPosition=0.44
		XSize=0.90
		YSize=0.08
		MaxTextLength=512
		OnTextChange=UpdatePreview
	End Object
	Components.Add(MessageEditBox)

	Begin Object Class=KFGUI_EditBox Name=ColorEditBox
		ID="Color"
		XPosition=0.05
		YPosition=0.57
		XSize=0.22
		YSize=0.08
		MaxTextLength=6
		OnTextChange=UpdatePreview
	End Object
	Components.Add(ColorEditBox)

	Begin Object Class=KFGUI_NumericBox Name=IntervalNumericBox
		ID="Interval"
		XPosition=0.32
		YPosition=0.57
		XSize=0.22
		YSize=0.08
		MinValue=30
		MaxValue=3600
		MaxTextLength=4
		OnTextChange=UpdatePreview
	End Object
	Components.Add(IntervalNumericBox)

	Begin Object Class=KFGUI_Button Name=SaveAutoMessageButton
		ID="Save"
		XPosition=0.31
		YPosition=0.78
		XSize=0.18
		YSize=0.08
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(SaveAutoMessageButton)

	Begin Object Class=KFGUI_Button Name=CancelAutoMessageButton
		ID="Cancel"
		XPosition=0.52
		YPosition=0.78
		XSize=0.18
		YSize=0.08
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(CancelAutoMessageButton)
}
