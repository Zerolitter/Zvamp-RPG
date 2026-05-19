class Zvamp_Camera extends Object config(ZvampCamera);

var config bool bEnabled;
var config bool bConfigsInit;
var config bool bDisableCamShakes;
var config bool bDisableSprintFOVChange;
var config bool bDisableEarsRinging;
var config bool bDisableCameraAnims;
var config float ZedTimeEffectReduction;

static final function InitDefaults()
{
	if (!default.bConfigsInit)
	{
		default.bEnabled = true;
		default.bDisableCamShakes = true;
		default.bDisableSprintFOVChange = true;
		default.bDisableEarsRinging = true;
		default.bDisableCameraAnims = true;
		default.ZedTimeEffectReduction = 1.0;
		default.bConfigsInit = true;
		StaticSaveConfig();
	}

	default.ZedTimeEffectReduction = FClamp(default.ZedTimeEffectReduction, 0.0, 1.0);
	StaticSaveConfig();
}
