#pragma semicolon 1
#pragma newdecls required
#include <smrpg>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#define UPGRADE_SHORTNAME "AutoRefill"
#define PLUGIN_VERSION "1.0"

bool bJumping[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "SM:RPG Upgrade > Old Scout",
	author = "WanekWest",
	description = "Refill clip instantly when clip has 1 bullet left.",
	version = PLUGIN_VERSION,
	url = "https://vk.com/wanek_west"
}

ConVar hAutoRefilChance;
int g_hAutoRefilChance;

public void OnPluginStart()
{
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Pre);

	LoadTranslations("smrpg_stock_upgrades.phrases");
}

public void OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
}

public void OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "smrpg"))
    {
        SMRPG_RegisterUpgradeType("AutoRefill", UPGRADE_SHORTNAME, "Refill clip instantly when clip has 1 bullet left.", 0, true, 4, 1400, 1200);
        SMRPG_SetUpgradeTranslationCallback(UPGRADE_SHORTNAME, SMRPG_TranslateUpgrade);

        hAutoRefilChance = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_upgrade_auto_refil_chance", "3", "Chance of skill working(Level*Value).", _, true, 1.0);
        hAutoRefilChance.AddChangeHook(OnAutoRefilChanceCh);
        g_hAutoRefilChance = hAutoRefilChance.IntValue;
	}
}

public void OnAutoRefilChanceCh(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hAutoRefilChance = hCvar.IntValue;
}

public void SMRPG_TranslateUpgrade(int client, const char[] shortname, TranslationType type, char[] translation, int maxlen)
{
	if(type == TranslationType_Name)
		Format(translation, maxlen, "%T", UPGRADE_SHORTNAME, client);
	else if(type == TranslationType_Description)
	{
		char sDescriptionKey[MAX_UPGRADE_SHORTNAME_LENGTH+12] = UPGRADE_SHORTNAME;
		StrCat(sDescriptionKey, sizeof(sDescriptionKey), " description");
		Format(translation, maxlen, "%T", sDescriptionKey, client);
	}
}

void EventWeaponFire(Event hEvent, const char[] sEvName, bool bdontBoadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")), iLevel = SMRPG_GetClientUpgradeLevel(iClient, UPGRADE_SHORTNAME) > 0;

	if(iClient && iLevel > 0)
	{
		int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		if (iActiveWeapon != -1 && IsValidEdict(iActiveWeapon)) 
		{
            int AmountOfAmmo = GetEntProp(iActiveWeapon, Prop_Send, "m_iClip1");
            if(AmountOfAmmo == 1)
            {
                int chance = GetRandomInt(0, 100);
                if(chance < iLevel * g_hAutoRefilChance)
                {
                    SetEntProp(iActiveWeapon, Prop_Send, "m_iClip1", GetAmountOfReqAmmo(iActiveWeapon));
                }
            }
		}
	}
}

public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon)
{
	if(iClient && IsClientInGame(iClient) && IsPlayerAlive(iClient)) bJumping[iClient]=(buttons & IN_JUMP)?true:false;
	return Plugin_Continue;
}

int GetAmountOfReqAmmo(int WeaponId)
{
    char weaponname[128];
    GetEntityClassname(WeaponId, weaponname, sizeof(weaponname));

    if(StrContains(weaponname, "m4a1") != -1 || StrContains(weaponname, "weapon_m4a1_silencer") != -1 || StrContains(weaponname, "weapon_ak47") != -1 || StrContains(weaponname, "weapon_galilar") != -1 || StrContains(weaponname, "weapon_sg556") != -1 || StrContains(weaponname, "weapon_aug") != -1 || StrContains(weaponname, "weapon_mp9") != -1 || StrContains(weaponname, "weapon_mp7") != -1 || StrContains(weaponname, "weapon_mp5sd") != -1 || StrContains(weaponname, "weapon_mac10") != -1)
    {
        return 30;
    }
    else if(StrContains(weaponname, "weapon_awp") != -1 || StrContains(weaponname, "weapon_ssg08") != -1)
    {
        return 10;
    }
    else if(StrContains(weaponname, "weapon_bizon") != -1 || StrContains(weaponname, "weapon_p90") != -1)
    {
        return 50;
    }
    else if(StrContains(weaponname, "weapon_famas") != -1 || StrContains(weaponname, "weapon_ump45") != -1)
    {
        return 25;
    }
    else if(StrContains(weaponname, "weapon_g3sg1") != -1 || StrContains(weaponname, "weapon_scar20") != -1)
    {
        return 20;
    }

    return 10;
}