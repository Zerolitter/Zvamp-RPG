class SML_ZedSpawner extends SML_BootstrapMutator;

function class<SML_BootstrapActor> GetBootstrapActorClass()
{
	return class'SML_ZedSpawnerActor';
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	return string(class'SML_ZedSpawnerActor');
}

defaultproperties
{
}
