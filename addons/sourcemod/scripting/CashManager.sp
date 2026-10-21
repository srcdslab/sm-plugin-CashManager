#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define MAXMATCHES 10

Address AddAccountAddr;
Address maxmoney[MAXMATCHES];
int matches = 0;

ConVar mp_maxmoney;

public Plugin myinfo = 
{
	name = "CashManager",
	author = "Dr!fter, .Rushaway",
	description = "Patches max money",
	version = "1.2.2"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if(strcmp(gamedir, "cstrike") != 0)
	{
		strcopy(error, err_max, "This plugin is only supported on CS:S");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	FindConVar("mp_startmoney").SetBounds(ConVarBound_Upper, false);
	FindConVar("mp_startmoney").SetBounds(ConVarBound_Lower, false);

	mp_maxmoney = CreateConVar("mp_maxmoney", "65000", "Set's max money limit", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);
	mp_maxmoney.AddChangeHook(MaxMoneyChange);

	GameData hGameConf = new GameData("CashManager.games");
	if(hGameConf == null)
		SetFailState("Failed to load gamedata CashManager.games.txt");

	AddAccountAddr = hGameConf.GetAddress("AddAccount");

	if(!AddAccountAddr)
		SetFailState("Failed to get AddAccount address");

	int len = hGameConf.GetOffset("AddAccountLen");

	for(int i = 0; i <= len; i++)
	{
		if(LoadFromAddress(AddAccountAddr+view_as<Address>(i), NumberType_Int32) == 16000 && matches < MAXMATCHES)
		{
			maxmoney[matches] = AddAccountAddr+view_as<Address>(i);
			matches++;
		}
	}
	PatchMoney();
	
	delete hGameConf;
}

public void MaxMoneyChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PatchMoney();
}

public void OnPluginEnd()
{
	for(int i = 0; i < matches; i++)
	{
		StoreToAddress(maxmoney[i], 16000, NumberType_Int32);
		maxmoney[i] = Address_Null;
	}
}

void PatchMoney()
{	
	int money = mp_maxmoney.IntValue;
	
	for(int i = 0; i < matches; i++)
	{
		StoreToAddress(maxmoney[i], money, NumberType_Int32);
	}
}
