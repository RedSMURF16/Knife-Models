/*
*
*	Knife Models by RedSMURF
*	
*
*	Description:
*		Knife Models for general purposes.
*
*	Cvars:
*		None
*	
*	Commands:
*       say /knife                  "Opens the knives menu."
*       say_team /knife             "Opens the knives menu."
*       km_select                   "Selects a knife by it's index."
*       km_reload                   "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*       v1.1: Optimized code.
*       v2.0: Wrapped all Knives and player data in a single enumeration *PLAYER_DATA*.
*       v2.1: Handles all knife sounds.
*
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <nvault> 
#include <smurfchat>
#include <knifemodels_const>

#if !defined m_pPlayer 
    new const m_pPlayer =  41
#endif 

new const PLUGIN_VERSION[]              = "2.1"
new const Float:DELAY_ON_CONNECT        = 0.9
new const Float:DELAY_VAULT_SET         = 1.0
new const ERROR_FILE[]                  = "KnifeModels_ERRORS.log"

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_IP_LENGTH
    #define MAX_IP_LENGTH 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_AUTHID_LENGTH
    #define MAX_AUTHID_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_KNIVES
}

enum 
{
    SOUND_NONE,
    SOUND_DEPLOY1,
    SOUND_HIT1,
    SOUND_HIT2,
    SOUND_HIT3,
    SOUND_HIT4,
    SOUND_HITWALL1,
    SOUND_SLASH1,
    SOUND_SLASH2,
    SOUND_STAB
}

enum
{
    FLAG_ENABLED,
    FLAG_ANY,
    FLAG_ALL,
    FLAG_DISABLED
}

enum _:MAIN_SETTINGS
{
    SETTING_KNIFE_DEFAULT,
    SETTING_KNIFE_AUTO_SWITCH,
    SETTING_OPEN_AT_SPAWN,
    SETTING_ONLY_DEAD,
    SETTING_MESSAGE_SELECT,
    SETTING_ADMIN_BYPASS,
    SETTING_VAULT_SET,
    SETTING_VAULT_SAVE
}

enum _:KNIVES
{
    KNIFE_NAME[ MAX_VALUE_LENGTH ],
    KNIFE_V_MODEL[ MAX_RESOURCE_PATH_LENGTH ],
    KNIFE_P_MODEL[ MAX_RESOURCE_PATH_LENGTH ],
    KNIFE_FLAGS[ MAX_VALUE_LENGTH ],
    KNIFE_FLAGS_INFO,
    KNIFE_SOUND_DEPLOY1[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_HIT1[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_HIT2[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_HIT3[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_HIT4[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_HITWALL1[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_SLASH1[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_SLASH2[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_STAB[ KM_MAX_SOUND_LENGTH ],
    KNIFE_SOUND_SELECT[ KM_MAX_SOUND_LENGTH ],
    Array:KNIFE_MESSAGE_SELECT,
    KNIFE_MESSAGE_SELECT_NUM
}

enum _:PLAYER_DATA
{
    PDATA_NAME[ MAX_VALUE_LENGTH ],
    PDATA_AUTHID[ MAX_AUTHID_LENGTH ],
    PDATA_ADMIN_FLAGS,
    PDATA_KNIFE,
    PDATA_KNIFE_ENUM[ KNIVES ],
    bool:PDATA_SOUND_DEPLOY1
}

new Array:g_aKnives,
    g_eSettings[ MAIN_SETTINGS ],
    g_ePlayerData[ MAX_PLAYERS + 1 ][ PLAYER_DATA ],
    g_szFileName[ MAX_RESOURCE_PATH_LENGTH ],
    bool:g_bFileWasRead = false,
    g_iFwdKnifeUpdated,
    g_iKnives,
    g_iCallback,
    g_iVault

public plugin_init()
{
    register_plugin( "Knife Models", PLUGIN_VERSION, "RedSMURF" )
    register_cvar( "SMURFKnifeModels", PLUGIN_VERSION, FCVAR_SPONLY | FCVAR_SERVER )

    register_dictionary( "KnifeModels.txt" )

    RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawnPre" )
    RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawnPost", 1 )
    RegisterHam( Ham_Item_Deploy, "weapon_knife", "fwdKnifeDeploy", 1 )
    register_forward( FM_EmitSound, "fwdEmitSound" )

    register_clcmd( "say /knife", "showMenu" )
    register_clcmd( "say_team /knife", "showMenu" )
    register_concmd( "km_select", "cmdSelect", ADMIN_ALL, "<Knife ID>" )
    register_concmd( "km_reload", "cmdReload", ADMIN_RCON, "-- Reloads the configuration file" )

    g_iFwdKnifeUpdated = CreateMultiForward( "km_on_knife_updated", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL )

    g_iVault = nvault_open( "KnivesModels" )
    g_iCallback = menu_makecallback( "ItemHandler" )
}

public plugin_end()
{
    new eKnives[ KNIVES ]

    for ( new i = 0; i < g_iKnives; i ++ )
    {
        ArrayGetArray( g_aKnives, i, eKnives )
        ArrayDestroy( eKnives[ KNIFE_MESSAGE_SELECT ] )
    }

    ArrayDestroy( g_aKnives )
    nvault_close( g_iVault )
}

public plugin_precache()
{
    g_aKnives = ArrayCreate( KNIVES )

    ReadFile()
}

public cmdSelect( id, iLevel, iCmd )
{
    if ( !cmd_access( id, iLevel, iCmd, 2 ) )
        return PLUGIN_HANDLED

    if ( g_eSettings[ SETTING_ONLY_DEAD ] && is_user_alive( id ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_SETTING_ONLY_DEAD" )
        return PLUGIN_HANDLED
    }

    new iKnife
    iKnife = read_argv_int( 1 )

    if ( !isKnifeValid( iKnife ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_INVALID_KNIFE", g_iKnives - 1 )
    }
    else if ( !hasKnifeAccess( id, iKnife ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_NO_ACCESS" )
    }
    else 
    {
        selectKnife( id, iKnife )
    }

    return PLUGIN_HANDLED
}

public cmdReload( id, iLevel, iCmd )
{
   if ( !cmd_access( id, iLevel, iCmd, 1 ) )
        return PLUGIN_HANDLED

   ReadFile()
   console_print( id, "The configuration file has been reloaded successfully." )

   return PLUGIN_HANDLED
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        new eKnives[ KNIVES ], iPlayers[ MAX_PLAYERS ], iNum, i
        get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

        for ( i = 0; i < g_iKnives; i ++ )
        {
            ArrayGetArray( g_aKnives, i, eKnives )
            ArrayDestroy( eKnives[ KNIFE_MESSAGE_SELECT ] )
        }
        ArrayClear( g_aKnives )
        g_iKnives = 0

        for ( i = 0; i < iNum; i ++ )
            UpdateData( iPlayers[ i ] )
    }

    get_configsdir( g_szFileName, charsmax( g_szFileName ) )
    add( g_szFileName, charsmax( g_szFileName ), "/KnifeModels.ini" )

    new iFileHandler = fopen( g_szFileName, "rt" )

    if ( !iFileHandler )
    {
        set_fail_state( "An error occured during the opening of the configuration file" )
    }

    new szData[ MAX_FILE_CELL_SIZE ], 
        szKey[ MAX_VALUE_LENGTH ], 
        szValue[ MAX_RESOURCE_PATH_LENGTH ],
        eKnives[ KNIVES ], iSection = SECTION_NONE, iLine

    while( !feof( iFileHandler ) )
    {
        iLine++
        fgets( iFileHandler, szData, charsmax( szData ) )
        trim( szData )

        switch( szData[ 0 ] )
        {
            case EOS, ';', '#': 
            {
                continue
            }
            case '[':
            {
                if ( szData[ strlen( szData ) - 1 ] == ']' )
                {
                    replace( szData, charsmax( szData ), "[", "" )
                    replace( szData, charsmax( szData ), "]", "" )
                    trim( szData )

                    if ( equali( szData, "Main Settings" ) )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iKnives )
                            pushKnife( eKnives )

                        copy( eKnives[ KNIFE_NAME ], charsmax( eKnives[ KNIFE_NAME ] ), szData )
                        eKnives[ KNIFE_V_MODEL ]        = EOS
                        eKnives[ KNIFE_P_MODEL ]        = EOS
                        eKnives[ KNIFE_FLAGS ]          = EOS
                        eKnives[ KNIFE_FLAGS_INFO ]     = 0
                        eKnives[ KNIFE_SOUND_DEPLOY1 ]  = EOS
                        eKnives[ KNIFE_SOUND_HIT1 ]     = EOS
                        eKnives[ KNIFE_SOUND_HIT2 ]     = EOS
                        eKnives[ KNIFE_SOUND_HIT3 ]     = EOS
                        eKnives[ KNIFE_SOUND_HIT4 ]     = EOS
                        eKnives[ KNIFE_SOUND_HITWALL1 ] = EOS
                        eKnives[ KNIFE_SOUND_SLASH1 ]   = EOS
                        eKnives[ KNIFE_SOUND_SLASH2 ]   = EOS
                        eKnives[ KNIFE_SOUND_STAB ]     = EOS
                        eKnives[ KNIFE_SOUND_SELECT ]   = EOS

                        eKnives[ KNIFE_MESSAGE_SELECT ]     = _:ArrayCreate( KM_MAX_MESSAGE_LENGTH )
                        eKnives[ KNIFE_MESSAGE_SELECT_NUM ] = 0

                        iSection = SECTION_KNIVES
                        g_iKnives++
                    }
                }
                else 
                {
                    LogConfigError( iLine, "Unclosed section name: %s", szData )
                    iSection = SECTION_NONE 
                }
            }
            default : 
            {
                switch( iSection )
                {
                    case SECTION_NONE: 
                    {
                        LogConfigError( iLine, "Data is not in any defined section: %s", szData )
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        strtok( szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=' )
                        trim( szKey )
                        trim( szValue )

                        if ( equal( szKey, "KNIFE_DEFAULT" ) )
                        {
                            g_eSettings[ SETTING_KNIFE_DEFAULT ] = str_to_num( szValue )
                        }
                        else if ( equal( szKey, "KNIFE_AUTO_SWITCH" ) )
                        {
                            g_eSettings[ SETTING_KNIFE_AUTO_SWITCH ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "OPEN_AT_SPAWN" ) )
                        {
                            g_eSettings[ SETTING_OPEN_AT_SPAWN ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "ONLY_DEAD" ) )
                        {
                            g_eSettings[ SETTING_ONLY_DEAD ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "MESSAGE_SELECT" ) )
                        {
                            g_eSettings[ SETTING_MESSAGE_SELECT ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "ADMIN_BYPASS" ) )
                        {
                            g_eSettings[ SETTING_ADMIN_BYPASS ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "VAULT_SET" ) )
                        {
                            g_eSettings[ SETTING_VAULT_SET ] = bool:str_to_num( szValue )
                        }
                        else if ( equal( szKey, "VAULT_SAVE" ) )
                        {
                            g_eSettings[ SETTING_VAULT_SAVE ] = bool:str_to_num( szValue )
                        }
                    }
                    case SECTION_KNIVES:
                    {
                        strtok( szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=' )
                        trim( szKey )
                        trim( szValue )

                        if ( equal( szKey, "V_MODEL" ) )
                        {
                            if ( !g_bFileWasRead ) precache_model( szValue )
                            copy( eKnives[ KNIFE_V_MODEL ], charsmax( eKnives[ KNIFE_V_MODEL ] ), szValue )
                        }
                        else if ( equal( szKey, "P_MODEL" ) )
                        {
                            if ( !g_bFileWasRead ) precache_model( szValue )
                            copy( eKnives[ KNIFE_P_MODEL ], charsmax( eKnives[ KNIFE_P_MODEL ] ), szValue )
                        }
                        else if ( equal( szKey, "FLAGS" ) )
                        {
                            eKnives[ KNIFE_FLAGS ] = read_flags( szValue )
                        }
                        else if ( equal( szKey, "FLAGS_INFO" ) )
                        {
                            eKnives[ KNIFE_FLAGS_INFO ] = str_to_num( szValue )
                            clamp( eKnives[ KNIFE_FLAGS_INFO ], 0, 3 )
                        }
                        else if ( equal( szKey, "SOUND_DEPLOY1" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_DEPLOY1 ], charsmax( eKnives[ KNIFE_SOUND_DEPLOY1 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_HIT1" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_HIT1 ], charsmax( eKnives[ KNIFE_SOUND_HIT1 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_HIT2" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_HIT2 ], charsmax( eKnives[ KNIFE_SOUND_HIT2 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_HIT3" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_HIT3 ], charsmax( eKnives[ KNIFE_SOUND_HIT3 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_HIT4" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_HIT4 ], charsmax( eKnives[ KNIFE_SOUND_HIT4 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_HITWALL1" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_HITWALL1 ], charsmax( eKnives[ KNIFE_SOUND_HITWALL1 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_SLASH1" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_SLASH1 ], charsmax( eKnives[ KNIFE_SOUND_SLASH1 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_SLASH2" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_SLASH2 ], charsmax( eKnives[ KNIFE_SOUND_SLASH2 ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_STAB" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_STAB ], charsmax( eKnives[ KNIFE_SOUND_STAB ] ), szValue )
                        }
                        else if ( equal( szKey, "SOUND_SELECT" ) )
                        {
                            if ( !g_bFileWasRead ) precache_sound( szValue )
                            copy( eKnives[ KNIFE_SOUND_SELECT ], charsmax( eKnives[ KNIFE_SOUND_SELECT ] ), szValue )
                        }
                        else if ( equal( szKey, "MESSAGE_SELECT" ) )
                        {
                            ArrayPushString( eKnives[ KNIFE_MESSAGE_SELECT ], szValue )
                            eKnives[ KNIFE_MESSAGE_SELECT_NUM ]++
                        }
                    }
                }
            }
        }
    }

    if ( g_iKnives ) 
        pushKnife( eKnives )
    else             
        set_fail_state( "No knives were found in the configuration file." )


    g_eSettings[ SETTING_KNIFE_DEFAULT ] = clamp( g_eSettings[ SETTING_KNIFE_DEFAULT ], 0, g_iKnives - 1 )
    if ( g_bFileWasRead )
    {
        new iPlayers[ MAX_PLAYERS ], iNum, i, id
        get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

        for ( i = 0; i < iNum; i ++ )
        {
            id = iPlayers[ i ]

            if ( !hasKnifeAccess( id, g_ePlayerData[ id ][ PDATA_KNIFE ] ) )
            {
                SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_NO_LONGER_ACCESS" )

                setKnifeDefault( id )
            }
        }
    }
    g_eSettings[ SETTING_KNIFE_DEFAULT ] = clamp( g_eSettings[ SETTING_KNIFE_DEFAULT ], 0, g_iKnives - 1 )

    g_bFileWasRead = true
    fclose( iFileHandler )
}

public client_authorized( id )
{
    get_user_name( id, g_ePlayerData[ id ][ PDATA_NAME ], charsmax( g_ePlayerData[][ PDATA_NAME ] ) )
    get_user_authid( id, g_ePlayerData[ id ][ PDATA_AUTHID ], charsmax( g_ePlayerData[][ PDATA_AUTHID ] ) )

    set_task( DELAY_ON_CONNECT, "UpdateData", id )

    if ( g_eSettings[ SETTING_VAULT_SET ] )
    {
        set_task( DELAY_VAULT_SET, "setData", id )
    }
    else 
    {
        setKnifeDefault( id )
    }
}

public UpdateData( id )
{
    get_user_name( id, g_ePlayerData[ id ][ PDATA_NAME ], charsmax( g_ePlayerData[][ PDATA_NAME ] ) )

    g_ePlayerData[ id ][ PDATA_ADMIN_FLAGS ] = get_user_flags( id )
}

public setData( id )
{
    new iKnife
    iKnife = nvault_get( g_iVault, g_ePlayerData[ id ][ PDATA_AUTHID ] )

    if ( isKnifeValid( iKnife ) && hasKnifeAccess( id, iKnife ) )
    {
        new iRet

        g_ePlayerData[ id ][ PDATA_KNIFE ] = iKnife
        ArrayGetArray( g_aKnives, iKnife, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ] )

        ExecuteForward( g_iFwdKnifeUpdated, iRet, id, iKnife, true )

        if ( is_user_alive( id ) && get_user_weapon( id ) == CSW_KNIFE )
            setKnife( id )
    }
    else if ( !hasKnifeAccess( id, iKnife ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_NO_LONGER_ACCESS" )

        setKnifeDefault( id )
    }
}

public client_disconnected( id )
{
    if ( g_eSettings[ SETTING_VAULT_SAVE ] )
        saveData( id )
}

public saveData( id )
{
    new szKnife[ 4 ]
    formatex( szKnife, charsmax( szKnife ), "%d", g_ePlayerData[ id ][ PDATA_KNIFE ] )

    nvault_set( g_iVault, g_ePlayerData[ id ][ PDATA_AUTHID ], szKnife )
}

public fwdPlayerSpawnPre( id )
{
    g_ePlayerData[ id ][ PDATA_SOUND_DEPLOY1 ] = false

    return HAM_IGNORED
}

public fwdPlayerSpawnPost( id )
{
    if ( is_user_alive( id )
    && g_eSettings[ SETTING_OPEN_AT_SPAWN ]
    && !g_eSettings[ SETTING_ONLY_DEAD ] )
        showMenu( id )

    return HAM_IGNORED
}

public fwdKnifeDeploy( iWeapon )
{
    new id 
    id = get_pdata_cbase( iWeapon, m_pPlayer, 4 )

    if ( is_user_alive( id ) )
        setKnife( id )

    return HAM_IGNORED
}

public fwdEmitSound( id, iChannel, szSample[] )
{
    if ( !is_user_alive( id ) || !isKnifeSound( szSample ) )
        return FMRES_IGNORED

    switch( detectKnifeSound( szSample ) )
    {
        case SOUND_DEPLOY1:
        {
            if ( g_ePlayerData[ id ][ PDATA_SOUND_DEPLOY1 ] ) playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_DEPLOY1 ] ) 
            else g_ePlayerData[ id ][ PDATA_SOUND_DEPLOY1 ] = true
        }

        case SOUND_HIT1:        { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_HIT1 ] );        return FMRES_SUPERCEDE; }
        case SOUND_HIT2:        { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_HIT2 ] );        return FMRES_SUPERCEDE; }
        case SOUND_HIT3:        { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_HIT3 ] );        return FMRES_SUPERCEDE; }
        case SOUND_HIT4:        { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_HIT4 ] );        return FMRES_SUPERCEDE; }
        case SOUND_HITWALL1:    { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_HITWALL1 ] );    return FMRES_SUPERCEDE; }
        case SOUND_SLASH1:      { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_SLASH1 ] );      return FMRES_SUPERCEDE; }
        case SOUND_SLASH2:      { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_SLASH2 ] );      return FMRES_SUPERCEDE; }
        case SOUND_STAB:        { playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_STAB ] );        return FMRES_SUPERCEDE; }
    }

    return FMRES_IGNORED
}

public showMenu( id )
{
    if ( g_eSettings[ SETTING_ONLY_DEAD ] && is_user_alive( id ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_ONLY_DEAD" )
        return PLUGIN_HANDLED
    }

    new eKnives[ KNIVES ], szTitle[ 64 ], szItem[ 64 ]
    formatex( szTitle, charsmax( szTitle ), "%L", id, "KM_MENU_TITLE" )

    new iMenu = menu_create( szTitle, "MenuHandler" )

    for ( new i = 0; i < g_iKnives; i ++ )
    {
        ArrayGetArray( g_aKnives, i, eKnives )
        copy( szItem, charsmax( szItem ), eKnives[ KNIFE_NAME ] )

        if ( eKnives[ KNIFE_FLAGS ] != ADMIN_ALL && !( eKnives[ KNIFE_FLAGS ] & ADMIN_USER ) )
            format( szItem, charsmax( szItem ), "%s %L", szItem, id, "KM_MENU_VIP" )

        if ( g_ePlayerData[ id ][ PDATA_KNIFE ] == i )
            format( szItem, charsmax( szItem ), "%s %L", szItem, id, "KM_MENU_SELECTED" )

        menu_additem( iMenu, szItem, eKnives[ KNIFE_NAME ], ADMIN_ALL, g_iCallback )
    }

    if ( menu_pages( iMenu ) > 1 )
    {
        formatex( szItem, charsmax( szItem ), "%s^n%L", szTitle, id, "KM_MENU_TITLE_PAGE" )
        menu_setprop( iMenu, MPROP_TITLE, szItem )
    }

    menu_setprop( iMenu, MPROP_EXIT, MEXIT_ALL )
    menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\y" )

    menu_display( id, iMenu )
    return PLUGIN_HANDLED
}

public MenuHandler( id, iMenu, iItem )
{
    if ( iItem == MENU_EXIT )
    {
        menu_destroy( iMenu )
        return PLUGIN_HANDLED
    }

    if ( g_eSettings[ SETTING_ONLY_DEAD ] && is_user_alive( id ) )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_ONLY_DEAD" )
    }
    else
    {
        selectKnife( id, iItem )
    }

    menu_destroy( iMenu )
    return PLUGIN_HANDLED
}

public ItemHandler( id, iMenu, iItem )
{
    if ( g_ePlayerData[ id ][ PDATA_KNIFE ] == iItem
    || ( !hasKnifeAccess( id, iItem ) && !g_eSettings[ SETTING_ADMIN_BYPASS ] ) )
        return ITEM_DISABLED

    return ITEM_IGNORE
}

selectKnife( id, iKnife )
{
    new iReturn

    g_ePlayerData[ id ][ PDATA_KNIFE ] = iKnife
    ArrayGetArray( g_aKnives, iKnife, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ] )
    ExecuteForward( g_iFwdKnifeUpdated, iReturn, id, iKnife, false )

    if ( g_eSettings[ SETTING_KNIFE_AUTO_SWITCH ] && get_user_weapon( id ) != CSW_KNIFE )
    {
        engclient_cmd( id, "weapon_knife" )
    }
    if ( get_user_weapon( id ) == CSW_KNIFE )
    {
        setKnife( id )
    }

    if ( g_eSettings[ SETTING_MESSAGE_SELECT ] )
    {
        SC_SendMessage( id, "%L %L", id, "KM_CHAT_TAG", id, "KM_CHAT_SELECTED", g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_NAME ] )
    }

    if ( g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_MESSAGE_SELECT_NUM ] )
    {
        for ( new i = 0; i < g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_MESSAGE_SELECT_NUM ]; i ++ )
        {
            SC_SendMessage( id, "%a", ArrayGetStringHandle( g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_MESSAGE_SELECT ], i ) )
        }
    }

    if ( g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_SELECT ][ 0 ] )
    {
        playKnifeSound( id, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_SOUND_SELECT ] )
    }
}

public setKnifeDefault( id )
{
    g_ePlayerData[ id ][ PDATA_KNIFE ] = g_eSettings[ SETTING_KNIFE_DEFAULT ]
    ArrayGetArray( g_aKnives, g_eSettings[ SETTING_KNIFE_DEFAULT ], g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ] )

    if ( get_user_weapon( id ) == CSW_KNIFE )
        setKnife( id )
}

public setKnife( id )
{
    set_pev( id, pev_viewmodel2, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_V_MODEL ] )
    set_pev( id, pev_weaponmodel2, g_ePlayerData[ id ][ PDATA_KNIFE_ENUM ][ KNIFE_P_MODEL ] )
}

public pushKnife( eKnives[ KNIVES ] )
{
    if ( !eKnives[ KNIFE_V_MODEL ] )        copy( eKnives[ KNIFE_V_MODEL ], charsmax( eKnives[ KNIFE_V_MODEL ] ), KM_MODEL_V_DEFAULT )
    if ( !eKnives[ KNIFE_P_MODEL ] )        copy( eKnives[ KNIFE_P_MODEL ], charsmax( eKnives[ KNIFE_P_MODEL ] ), KM_MODEL_P_DEFAULT )

    if ( !eKnives[ KNIFE_SOUND_DEPLOY1 ] )  copy( eKnives[ KNIFE_SOUND_DEPLOY1 ], charsmax( eKnives[ KNIFE_SOUND_DEPLOY1 ] ), KM_SOUND_DEPLOY1 )
    if ( !eKnives[ KNIFE_SOUND_HIT1 ] )     copy( eKnives[ KNIFE_SOUND_HIT1 ], charsmax( eKnives[ KNIFE_SOUND_HIT1 ] ), KM_SOUND_HIT1 )
    if ( !eKnives[ KNIFE_SOUND_HIT2 ] )     copy( eKnives[ KNIFE_SOUND_HIT2 ], charsmax( eKnives[ KNIFE_SOUND_HIT2 ] ), KM_SOUND_HIT2 )
    if ( !eKnives[ KNIFE_SOUND_HIT3 ] )     copy( eKnives[ KNIFE_SOUND_HIT3 ], charsmax( eKnives[ KNIFE_SOUND_HIT3 ] ), KM_SOUND_HIT3 )
    if ( !eKnives[ KNIFE_SOUND_HIT4 ] )     copy( eKnives[ KNIFE_SOUND_HIT4 ], charsmax( eKnives[ KNIFE_SOUND_HIT4 ] ), KM_SOUND_HIT4 )
    if ( !eKnives[ KNIFE_SOUND_HITWALL1 ] ) copy( eKnives[ KNIFE_SOUND_HITWALL1 ], charsmax( eKnives[ KNIFE_SOUND_HITWALL1 ] ), KM_SOUND_HITWALL1 )
    if ( !eKnives[ KNIFE_SOUND_SLASH1 ] )   copy( eKnives[ KNIFE_SOUND_SLASH1 ], charsmax( eKnives[ KNIFE_SOUND_SLASH1 ] ), KM_SOUND_SLASH1 )
    if ( !eKnives[ KNIFE_SOUND_SLASH2 ] )   copy( eKnives[ KNIFE_SOUND_SLASH2 ], charsmax( eKnives[ KNIFE_SOUND_SLASH2 ] ), KM_SOUND_SLASH2 )
    if ( !eKnives[ KNIFE_SOUND_STAB ] )     copy( eKnives[ KNIFE_SOUND_STAB ], charsmax( eKnives[ KNIFE_SOUND_STAB ] ), KM_SOUND_STAB )

    ArrayPushArray( g_aKnives, eKnives )
}

stock bool:hasKnifeAccess( id, iKnife )
{
    new eKnives[ KNIVES ]
    ArrayGetArray( g_aKnives, iKnife, eKnives )

    switch( eKnives[ KNIFE_FLAGS_INFO ] )
    {
        case FLAG_ANY: { if ( g_ePlayerData[ id ][ PDATA_ADMIN_FLAGS ] & eKnives[ KNIFE_FLAGS ] )                           return true; }
        case FLAG_ALL: { if ( g_ePlayerData[ id ][ PDATA_ADMIN_FLAGS ] & eKnives[ KNIFE_FLAGS ] == eKnives[ KNIFE_FLAGS ] ) return true; }
        case FLAG_DISABLED: return false 
        default: return true 
    }

    if ( g_eSettings[ SETTING_ADMIN_BYPASS ]
    || eKnives[ KNIFE_FLAGS ] == ADMIN_ALL
    || eKnives[ KNIFE_FLAGS ] & ADMIN_USER )
        return true

    return false
}

stock bool:isKnifeValid( iKnife )
{
    return 0 <= iKnife < g_iKnives
}

stock bool:isKnifeSound( const szSample[] )
{
    return bool:equal( szSample[ 8 ], "knife", 5 )
}

stock playKnifeSound( id, const szSample[] )
{
    engfunc( EngFunc_EmitSound, id, CHAN_WEAPON, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
}

stock detectKnifeSound( const szSample[] )
{
    new iSound 
    iSound = SOUND_NONE

    if      ( equal( szSample[ 14 ], "deploy1",     7 ) )  iSound = SOUND_DEPLOY1
    else if ( equal( szSample[ 14 ], "hit1",        4 ) )  iSound = SOUND_HIT1
    else if ( equal( szSample[ 14 ], "hit2",        4 ) )  iSound = SOUND_HIT2
    else if ( equal( szSample[ 14 ], "hit3",        4 ) )  iSound = SOUND_HIT3
    else if ( equal( szSample[ 14 ], "hit4",        4 ) )  iSound = SOUND_HIT4
    else if ( equal( szSample[ 14 ], "hitwall1",    8 ) )  iSound = SOUND_HITWALL1
    else if ( equal( szSample[ 14 ], "slash1",      6 ) )  iSound = SOUND_SLASH1
    else if ( equal( szSample[ 14 ], "slash2",      6 ) )  iSound = SOUND_SLASH2
    else if ( equal( szSample[ 14 ], "stab",        4 ) )  iSound = SOUND_STAB

    return iSound
}

stock LogConfigError( const iLine, const szText[], any:... )
{
    static szError[ MAX_PLATFORM_PATH_LENGTH ]
    vformat( szError, charsmax( szError ), szText, 3 )

    log_to_file( ERROR_FILE, "^nLine %d: %s^n", iLine, szError )
} 

public plugin_natives()
{
    register_library( "knifemodels" )
    set_native_filter( "native_filter" )

    register_native( "km_total_knives",                 "_km_total_knives" )
    register_native( "km_current_knife",                "_km_current_knife" )
    register_native( "km_has_knife_access",             "_km_has_knife_access" )
    register_native( "km_is_knife_valid",               "_km_is_knife_valid" )
}

public native_filter( const szNative[], id, iTrap )
{
    return iTrap ? PLUGIN_CONTINUE : PLUGIN_HANDLED
}

public _km_total_knives( iPlugin, iArgc )
{
    return g_iKnives
}

public _km_current_knife( iPlugin, iArgc )
{
    return g_ePlayerData[ get_param( 1 ) ][ PDATA_KNIFE ]
}

public bool:_km_has_knife_access( iPlugin, iArgc )
{
    return hasKnifeAccess( get_param( 1 ), get_param( 2 ) )
}

public bool:_km_is_knife_valid( iPlugin, iArgc )
{
    return isKnifeValid( get_param( 1 ) )
}

