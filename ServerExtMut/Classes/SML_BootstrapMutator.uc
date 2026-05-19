class SML_BootstrapMutator extends KFMutator;

var SML_BootstrapActor BootstrapActor;

simulated function bool SafeDestroy()
{
	return (bPendingDelete || bDeleteMe || Destroy());
}

function class<SML_BootstrapActor> GetBootstrapActorClass()
{
	return None;
}

event PreBeginPlay()
{
	local class<SML_BootstrapActor> ActorClass;

	super.PreBeginPlay();

	if (WorldInfo.NetMode == NM_Client)
		return;

	ActorClass = GetBootstrapActorClass();
	if (ActorClass != None)
	{
		foreach WorldInfo.DynamicActors(class'SML_BootstrapActor', BootstrapActor)
		{
			if (BootstrapActor.Class == ActorClass)
				break;
			BootstrapActor = None;
		}
		if (BootstrapActor == None)
			BootstrapActor = WorldInfo.Spawn(ActorClass);
	}

	if (BootstrapActor == None)
		`log("[SMLCompat] Could not spawn bootstrap actor for" @ PathName(Self));

	SafeDestroy();
}

function AddMutator(Mutator M)
{
	if (M == Self)
		return;
	if (M.Class == Class)
		SML_BootstrapMutator(M).SafeDestroy();
	else
		super.AddMutator(M);
}

defaultproperties
{
}
