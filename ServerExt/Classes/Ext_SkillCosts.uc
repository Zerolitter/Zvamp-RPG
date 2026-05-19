Class Ext_SkillCosts extends Object
	Abstract
	Config(Skillcosts)
	DependsOn(Ext_PerkBase);

struct FSkillCostStat
{
	var config int MaxValue;
	var config int CostPerValue;
	var config float Progress;
	var config name StatType;
	var config name StatGroup;
};

struct FPerkSkillCostStat
{
	var config int MaxValue;
	var config int CostPerValue;
	var config float Progress;
	var config name StatType;
	var config name StatGroup;
	var config string PerkClass;
	var config string PerkClasses;
	var config string PerkGroup;
};

struct FSkillCostPerkGroup
{
	var config string GroupName;
	var config string PerkClasses;
};

var const int CurrentConfigVer;
var config int ConfigVersion;
var config array<FSkillCostPerkGroup> PerkGroups;
var config array<FSkillCostStat> PerkStats;
var config array<FPerkSkillCostStat> PerkStatOverrides;
var config array<FPerkSkillCostStat> PerkStatAdditions;

static final function bool IsPerkStatForClass(FPerkSkillCostStat Stat, class<Ext_PerkBase> PerkClass)
{
	return Stat.PerkClass~=PathName(PerkClass) || Stat.PerkClass~=string(PerkClass.Name) || ClassListHasPerk(Stat.PerkClasses,PerkClass) || PerkGroupHasPerk(Stat.PerkGroup,PerkClass);
}

static final function bool ClassListHasPerk(string PerkClasses, class<Ext_PerkBase> PerkClass)
{
	local string PerkPath, PerkName, CheckList;

	if (PerkClasses=="")
		return false;

	PerkPath = Caps(PathName(PerkClass));
	PerkName = Caps(string(PerkClass.Name));
	CheckList = ";"$Caps(PerkClasses)$";";
	return InStr(CheckList,";"$PerkPath$";")>=0 || InStr(CheckList,";"$PerkName$";")>=0;
}

static final function bool PerkGroupHasPerk(string PerkGroup, class<Ext_PerkBase> PerkClass)
{
	local int i;

	if (PerkGroup=="")
		return false;

	for (i=0; i<Default.PerkGroups.Length; ++i)
	{
		if (Default.PerkGroups[i].GroupName~=PerkGroup)
			return ClassListHasPerk(Default.PerkGroups[i].PerkClasses,PerkClass);
	}
	return false;
}

static final function bool SameStat(FSkillCostStat A, Ext_PerkBase.FPerkStat B)
{
	return A.MaxValue==B.MaxValue && A.CostPerValue==B.CostPerValue && A.Progress==B.Progress;
}

static final function CopyGlobalStat(class<Ext_PerkBase> PerkClass, FSkillCostStat Src)
{
	local int i;

	i = PerkClass.Default.PerkStats.Length;
	PerkClass.Default.PerkStats.Length = i+1;
	PerkClass.Default.PerkStats[i].MaxValue = Src.MaxValue;
	PerkClass.Default.PerkStats[i].CostPerValue = Src.CostPerValue;
	PerkClass.Default.PerkStats[i].Progress = Src.Progress;
	PerkClass.Default.PerkStats[i].StatType = Src.StatType;
	PerkClass.Default.PerkStats[i].StatGroup = Src.StatGroup;
}

static final function ApplyPerkStat(class<Ext_PerkBase> PerkClass, FPerkSkillCostStat Src, bool bAddMissing)
{
	local int i;

	i = PerkClass.Default.PerkStats.Find('StatType',Src.StatType);
	if (i<0)
	{
		if (!bAddMissing)
			return;
		i = PerkClass.Default.PerkStats.Length;
		PerkClass.Default.PerkStats.Length = i+1;
	}
	PerkClass.Default.PerkStats[i].MaxValue = Src.MaxValue;
	PerkClass.Default.PerkStats[i].CostPerValue = Src.CostPerValue;
	PerkClass.Default.PerkStats[i].Progress = Src.Progress;
	PerkClass.Default.PerkStats[i].StatType = Src.StatType;
	PerkClass.Default.PerkStats[i].StatGroup = Src.StatGroup;
}

static final function bool LoadPerkStats(class<Ext_PerkBase> PerkClass)
{
	local int i;

	if (PerkClass==None || Default.PerkStats.Length==0)
		return false;

	PerkClass.Default.PerkStats.Length = 0;
	for (i=0; i<Default.PerkStats.Length; ++i)
		CopyGlobalStat(PerkClass,Default.PerkStats[i]);
	for (i=0; i<Default.PerkStatAdditions.Length; ++i)
		if (IsPerkStatForClass(Default.PerkStatAdditions[i],PerkClass))
			ApplyPerkStat(PerkClass,Default.PerkStatAdditions[i],true);
	for (i=0; i<Default.PerkStatOverrides.Length; ++i)
		if (IsPerkStatForClass(Default.PerkStatOverrides[i],PerkClass))
			ApplyPerkStat(PerkClass,Default.PerkStatOverrides[i],true);
	return true;
}

static final function StorePerkStats(class<Ext_PerkBase> PerkClass)
{
	local int i,j;
	local FPerkSkillCostStat Stat;

	if (PerkClass==None)
		return;

	RemovePerkStats(PerkClass);
	for (i=0; i<PerkClass.Default.PerkStats.Length; ++i)
	{
		Stat.MaxValue = PerkClass.Default.PerkStats[i].MaxValue;
		Stat.CostPerValue = PerkClass.Default.PerkStats[i].CostPerValue;
		Stat.Progress = PerkClass.Default.PerkStats[i].Progress;
		Stat.StatType = PerkClass.Default.PerkStats[i].StatType;
		Stat.StatGroup = PerkClass.Default.PerkStats[i].StatGroup;
		Stat.PerkClass = PathName(PerkClass);
		Stat.PerkClasses = "";
		Stat.PerkGroup = "";

		j = Default.PerkStats.Find('StatType',Stat.StatType);
		if (j<0)
			Default.PerkStatAdditions.AddItem(Stat);
		else if (!SameStat(Default.PerkStats[j],PerkClass.Default.PerkStats[i]))
			Default.PerkStatOverrides.AddItem(Stat);
	}
	if (Default.ConfigVersion!=Default.CurrentConfigVer)
		Default.ConfigVersion = Default.CurrentConfigVer;
	StaticSaveConfig();
}

static final function RemovePerkStats(class<Ext_PerkBase> PerkClass)
{
	local int i;

	for (i=Default.PerkStatOverrides.Length-1; i>=0; --i)
	{
		if (IsPerkStatForClass(Default.PerkStatOverrides[i],PerkClass))
			Default.PerkStatOverrides.Remove(i,1);
	}
	for (i=Default.PerkStatAdditions.Length-1; i>=0; --i)
	{
		if (IsPerkStatForClass(Default.PerkStatAdditions[i],PerkClass))
			Default.PerkStatAdditions.Remove(i,1);
	}
}

DefaultProperties
{
	CurrentConfigVer=6
}
