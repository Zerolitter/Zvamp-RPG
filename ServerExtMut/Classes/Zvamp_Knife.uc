class Zvamp_Knife extends Object config(ZvampKnife);

var config bool bEnabled;
var config bool bConfigsInit;
var config float MovespeedMultiplier;
var config float ParryBlockMultiplier;
var config float QuickTraderKnife;

static final function InitDefaults()
{
	if (!default.bConfigsInit)
	{
		default.bEnabled = true;
		default.MovespeedMultiplier = 1.25;
		default.ParryBlockMultiplier = 0.80;
		default.QuickTraderKnife = 1.0;
		default.bConfigsInit = true;
		StaticSaveConfig();
	}

	default.MovespeedMultiplier = FClamp(default.MovespeedMultiplier, 1.0, 2.0);
	default.ParryBlockMultiplier = FClamp(default.ParryBlockMultiplier, 0.40, 1.0);
	default.QuickTraderKnife = FClamp(default.QuickTraderKnife, 1.0, 5.0);
	StaticSaveConfig();
}

static final function float GetQuickTraderKnife()
{
	InitDefaults();
	return default.QuickTraderKnife;
}
