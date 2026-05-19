class SML_BootstrapActor extends Info;

var string TargetMutatorClassName;
var Mutator SpawnedMutator;

event PreBeginPlay()
{
	super.PreBeginPlay();

	if (WorldInfo.NetMode == NM_Client)
		return;

	SpawnTargetMutator();
}

final function bool SameMutatorClass(Mutator M, class<Mutator> TargetClass)
{
	return (M != None && TargetClass != None && M.Class == TargetClass);
}

final function bool MutatorInChain(Mutator M)
{
	local Mutator It;

	if (M == None || WorldInfo == None || WorldInfo.Game == None)
		return false;

	It = WorldInfo.Game.BaseMutator;
	while (It != None)
	{
		if (It == M)
			return true;
		It = It.NextMutator;
	}

	return false;
}

final function Mutator FindExistingMutator(class<Mutator> TargetClass)
{
	local Mutator M;

	foreach WorldInfo.DynamicActors(class'Mutator', M)
	{
		if (SameMutatorClass(M, TargetClass))
			return M;
	}

	return None;
}

final function SpawnTargetMutator()
{
	local class<Mutator> TargetClass;
	local Mutator M;

	if (TargetMutatorClassName == "")
	{
		`log("[SMLCompat] No target mutator configured for" @ PathName(Self));
		return;
	}

	TargetClass = class<Mutator>(DynamicLoadObject(TargetMutatorClassName, class'Class'));
	if (TargetClass == None)
	{
		`log("[SMLCompat] Could not load target mutator" @ TargetMutatorClassName);
		return;
	}

	M = FindExistingMutator(TargetClass);
	if (M == None)
	{
		M = WorldInfo.Spawn(TargetClass);
		if (M == None)
		{
			`log("[SMLCompat] Could not spawn target mutator" @ TargetMutatorClassName);
			return;
		}
	}

	SpawnedMutator = M;

	if (MutatorInChain(M))
	{
		`log("[SMLCompat] WARN target mutator is still in BaseMutator chain" @ TargetMutatorClassName);
	}

	`log("[SMLCompat] Active SML runtime" @ TargetMutatorClassName);
}

simulated function vector GetTargetLocation(optional Actor RequestedBy, optional bool bRequestAlternateLoc)
{
	local Controller C;

	C = Controller(RequestedBy);
	if (C != None && SpawnedMutator != None)
	{
		if (bRequestAlternateLoc)
			SpawnedMutator.NotifyLogout(C);
		else
			SpawnedMutator.NotifyLogin(C);
	}

	return Super.GetTargetLocation(RequestedBy, bRequestAlternateLoc);
}

defaultproperties
{
	TargetMutatorClassName=""
}
