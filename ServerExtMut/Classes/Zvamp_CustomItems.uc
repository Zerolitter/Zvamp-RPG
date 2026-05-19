// Simple Zvampext-owned custom trader item config.
//
// This intentionally replaces the narrow TIM use case we need without running
// TIM's client sync actor.
class Zvamp_CustomItems extends Object
	config(ZvampCustomItems);

var config bool bAddNewWeaponsToConfig;
var config array<string> Item;
var config array<string> StorePrice;
