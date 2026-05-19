class Zvamp_Syringe extends Object config(ZvampSyringe);

var config bool bEnabled;
var config bool bConfigsInit;
var config float StandAloneHealAmount;
var config float OthersHealAmount;
var config float HealSelfRechargeSeconds;
var config float HealOthersRechargeSeconds;

static final function InitDefaults()
{
	if (!default.bConfigsInit)
	{
		default.bEnabled = true;
		default.StandAloneHealAmount = 50.0;
		default.OthersHealAmount = 50.0;
		default.HealSelfRechargeSeconds = 10.0;
		default.HealOthersRechargeSeconds = 5.0;
		default.bConfigsInit = true;
		StaticSaveConfig();
	}

	default.StandAloneHealAmount = FMax(default.StandAloneHealAmount, 0.0);
	default.OthersHealAmount = FMax(default.OthersHealAmount, 0.0);
	default.HealSelfRechargeSeconds = FMax(default.HealSelfRechargeSeconds, 0.1);
	default.HealOthersRechargeSeconds = FMax(default.HealOthersRechargeSeconds, 0.1);
	StaticSaveConfig();
}
