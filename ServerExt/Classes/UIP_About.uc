// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UIP_About extends KFGUI_MultiComponent;

var KFGUI_TextField HelpText;
var string LastHelpText;

function InitMenu()
{
	HelpText = KFGUI_TextField(FindComponentID('Help'));

	Super.InitMenu();
	UpdateHelpText();
}

function DrawMenu()
{
	local float W,H;

	W = CompPos[2];
	H = CompPos[3];

	Canvas.SetDrawColor(34,34,38,105);
	Canvas.SetPos(W*0.025,H*0.055);
	Owner.CurrentStyle.DrawWhiteBox(W*0.93,H*0.82);
	Canvas.SetDrawColor(82,55,142,205);
	Canvas.SetPos(W*0.025,H*0.055);
	Owner.CurrentStyle.DrawWhiteBox(W*0.93,4.f);
	Canvas.SetPos(W*0.025,H*0.055+H*0.82-4.f);
	Owner.CurrentStyle.DrawWhiteBox(W*0.93,4.f);
	Canvas.SetPos(W*0.025,H*0.055);
	Owner.CurrentStyle.DrawWhiteBox(4.f,H*0.82);
	Canvas.SetPos(W*0.025+W*0.93-4.f,H*0.055);
	Owner.CurrentStyle.DrawWhiteBox(4.f,H*0.82);

	Super.DrawMenu();
	UpdateHelpText();
}

function UpdateHelpText()
{
	local ExtPlayerController EPC;
	local string S;

	EPC = ExtPlayerController(GetPlayer());

	S = "#{9B7CFF}Zvampext Help#{DEF}||";
	S $= "Commands shown here are server-side helpers exposed by the current Zvampext configuration.||";
	S $= "#{D8CFFF}Active commands#{DEF}|";
	if (EPC!=None && EPC.bRevampTraderGuardEnabled && EPC.bRevampTraderGuardPublicOpenTrader)
		S $= "#{10D5C7}ACTIVE#{DEF}  RvOpenTrader - open trader time/menu when TraderGuard allows public access.|";
	else
		S $= "#{777088}DISABLED#{DEF}  RvOpenTrader - admin has not enabled public open trader.|";
	S $= "#{9B7CFF}DoshThrowAmount <amount>#{DEF} - set your thrown dosh bundle amount.|";
	S $= "#{9B7CFF}DoshThrow <amount>#{DEF} - short alias for DoshThrowAmount.|";
	S $= "#{9B7CFF}ZClassResetyesimcertain#{DEF} - reset your current RPG class after you really mean it.|";

	S $= "||#{D8CFFF}Planned section#{DEF}|";
	S $= "#{777088}V3#{DEF}  Swappable grenade loadout - choose perk grenade style when backend support exists.|";
	S $= "#{777088}V3#{DEF}  Pet controls - follow, hold, defend, or roam with owned helpers.|";
	S $= "#{777088}V3#{DEF}  Player vote ProgressWave - optional vote-gated wave progression helper.|";
	S $= "#{777088}V3#{DEF}  Admin weapon rules - server-side damage, magazine, and weapon behavior controls.|";

	S $= "||#{D8CFFF}Admin notes#{DEF}|";
	S $= "AdminMenu - open the Zvampext admin dashboard.|";
	S $= "Admin BuildID - print the loaded ServerExt and ServerExtMut build labels.|";
	S $= "Admin zCheckHands - print the weapon/item class currently held in your hands.|";
	S $= "Admin DoshMe <value> - add dosh for fast trader testing.|";
	S $= "Admin ProgressWave <x> - advance waves through the wave-end cleanup flow.|";
	S $= "Admin ZRefreshNewItems - refresh custom trader item entries.|";
	S $= "Fast Forward remains an admin-only trader control. Public players should use the normal Skip Trader vote unless a separate public command is enabled.";

	if (S!=LastHelpText)
	{
		LastHelpText = S;
		HelpText.SetText(S);
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_TextField Name=HelpField
		ID="Help"
		XPosition=0.05
		YPosition=0.08
		XSize=0.90
		YSize=0.78
		FontScale=1
	End Object
	Components.Add(HelpField)
}
