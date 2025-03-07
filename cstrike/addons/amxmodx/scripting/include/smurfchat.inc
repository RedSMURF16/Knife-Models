#if defined _smurfchat_included
    #endinput
#endif

#define _smurfchat_included

#include <amxmodx>
#include <fakemeta>

#if !defined replace_string
    #define replace_string replace_all
#endif 

// Parent : SC_CLIENT_PRINT_COLOR
#if !defined SC_CLIENT_PRINT_COLOR
    #define client_print_color          SC_SendMatched
    #define print_team_default          SC_COLOR_TEAM
    #define print_team_grey             SC_COLOR_GREY
    #define print_team_blue             SC_COLOR_BLUE
    #define print_team_red              SC_COLOR_RED
#endif 

// Child : ChatColor, Parent : SC_CLIENT_PRINT_COLOR
#if !defined SC_CHAT_COLOR
    #define ChatColor                   SC_SendMatched
    #define DEFAULT_COLOR               SC_COLOR_TEAM
    #define NORMAL_COLOR                SC_COLOR_TEAM
    #define TEAM_COLOR                  SC_COLOR_TEAM
    #define GREY_COLOR                  SC_COLOR_GREY
    #define BLUE_COLOR                  SC_COLOR_BLUE
    #define RED_COLOR                   SC_COLOR_RED
#endif 

// Child : PrintChatColor, Parent : SC_CLIENT_PRINT_COLOR
#if !defined SC_PRINT_CHAT_COLOR
    #define PrintChatColor              SC_SendMatched
    #define PRINT_DEFAULT_COLOR         SC_COLOR_TEAM
    #define PRINT_NORMAL_COLOR          SC_COLOR_TEAM
    #define PRINT_TEAM_COLOR            SC_COLOR_TEAM
    #define PRINT_GREY_COLOR            SC_COLOR_GREY
    #define PRINT_BLUE_COLOR            SC_COLOR_BLUE
    #define PRINT_RED_COLOR             SC_COLOR_RED
#endif 

// Parent : SC_SHOW_ACTIVITY
#if !defined SC_SHOW_ACTIVITY
    #define show_activity               SC_SHOW_ACTIVITY
    #define show_activity_id            SC_SHOW_ACTIVITY_ID
    #define show_activity_key           SC_SHOW_ACTIVITY_KEY
#endif 

#if !defined SC_CHAT_PRINT
    #define ChatPrint                   SC_SendMessage
#endif 

#if !defined SC_PERCENT_REPLACE
    #define SC_PERCENT_REPLACE "％"
#endif 

#define SmurfChat                       SC_SendMessage

const Float:SC_VERSION                  = 1.1
const SC_MAX_ACT_PREFIX_SIZE            = 10
const SC_MAX_PLAYERS                    = 32 
const SC_MAX_PREFIX_SIZE                = 64
const SC_MAX_NAME_SIZE                  = 64
const SC_MAX_MESSAGE_SIZE               = 128
new SC_LIBRARY_NAME[]                   = "smurfchat"
new SC_FILTERING_FLAGS[]                = "ch"

#if !defined SC_COLORS_TYPE
    #define SC_COLORS_TYPE              SC_COLORS_STANDARD
#endif

#if !defined SC_ACTIVITY_FLAG
    #define SC_ACTIVITY_FLAG            -1
#endif

#if !defined SC_ACTIVITY_PREFIX_ADMIN
    #define SC_ACTIVITY_PREFIX_ADMIN    "ADMIN"
#endif 

#if !defined SC_ACTIVITY_PREFIX_PLAYER
    #define SC_ACTIVITY_PREFIX_PLAYER   "PLAYER"
#endif 

// Colors
enum 
{
    SC_COLOR_TEAM = MAX_PLAYERS + 25,
    SC_COLOR_GREY,
    SC_COLOR_BLUE,
    SC_COLOR_RED
}

const SC_COLOR_WHITE = SC_COLOR_GREY

// Colors Type 
enum 
{ 
    SC_COLORS_SMURFCHAT,
    SC_COLORS_SHORT,
    SC_COLORS_NAMED,
    SC_COLORS_NAMED_SHORT,
    SC_COLORS_STANDARD,
    SC_COLORS_CUSTOM
}

#define SC_SYM_MENU_YELLOW              "\y"
#define SC_SYM_MENU_WHITE               "\r"
#define SC_SYM_MENU_GREY                "\d"
#define SC_SYM_MENU_RIGHT               "\R"

#define SC_SYM_CHAT_DEFAULT_NORMAL      "^x01"
#define SC_SYM_CHAT_DEFAULT_TEAM        "^x03"
#define SC_SYM_CHAT_DEFAULT_GREEN       "^x04"

static bool:SC_FIRST_TIME_ACTIVITY = true, bool:SC_IS_CSCZ, bool:SC_COLOR_FORCE
static SC_ACTIVITY_POINTER, SC_COLOR_PLAYER_INDEX
new SC_PREFIX[ SC_MAX_PREFIX_SIZE ]

#if SC_COLORS_TYPE == SC_COLORS_CUSTOM
    #if !defined SC_SYM_CHAT_NORMAL
        #define SC_SYM_CHAT_NORMAL      "&x01"
    #endif 

    #if !defined SC_SYM_CHAT_TEAM
        #define SC_SYM_CHAT_TEAM        "&x03"
    #endif

    #if !defined SC_SYM_CHAT_GREEN
        #define SC_SYM_CHAT_GREEN       "&x04"
    #endif

    #if !defined SC_SYM_CHAT_WHITE
        #define SC_SYM_CHAT_WHITE       "&x05"
    #endif

    #if !defined SC_SYM_CHAT_BLUE
        #define SC_SYM_CHAT_BLUE        "&x06"
    #endif

    #if !defined SC_SYM_CHAT_RED
        #define SC_SYM_CHAT_RED         "&x07"
    #endif

    #if !defined SC_SYM_CHAT_NOPREF
        #define SC_SYM_CHAT_NOPREF      "&x00"
    #endif

#elseif SC_COLORS_TYPE == SC_COLORS_SMURFCHAT
    #define SC_SYM_CHAT_NORMAL          "&x01"
    #define SC_SYM_CHAT_TEAM            "&x03"
    #define SC_SYM_CHAT_GREEN           "&x04"
    #define SC_SYM_CHAT_WHITE           "&x05"
    #define SC_SYM_CHAT_BLUE            "&x06"
    #define SC_SYM_CHAT_RED             "&x07"
    #define SC_SYM_CHAT_NOPREF          "&x00"

#elseif SC_COLORS_TYPE == SC_COLORS_SHORT
    #define SC_SYM_CHAT_NORMAL          "!n"
    #define SC_SYM_CHAT_TEAM            "!t"
    #define SC_SYM_CHAT_GREEN           "!g"
    #define SC_SYM_CHAT_WHITE           "!w"
    #define SC_SYM_CHAT_BLUE            "!b"
    #define SC_SYM_CHAT_RED             "!r"
    #define SC_SYM_CHAT_NOPREF          "!p"

#elseif SC_COLORS_TYPE == SC_COLORS_NAMED
    #define SC_SYM_CHAT_NORMAL          "{normal}"
    #define SC_SYM_CHAT_TEAM            "{team}"
    #define SC_SYM_CHAT_GREEN           "{green}"
    #define SC_SYM_CHAT_WHITE           "{white}"
    #define SC_SYM_CHAT_BLUE            "{blue}"
    #define SC_SYM_CHAT_RED             "{red}"
    #define SC_SYM_CHAT_NOPREF          "{nopref}"

#elseif SC_COLORS_TYPE == SC_COLORS_NAMED_SHORT
    #define SC_SYM_CHAT_NORMAL          "{n}"
    #define SC_SYM_CHAT_TEAM            "{t}"
    #define SC_SYM_CHAT_GREEN           "{g}"
    #define SC_SYM_CHAT_WHITE           "{w}"
    #define SC_SYM_CHAT_BLUE            "{b}"
    #define SC_SYM_CHAT_RED             "{r}"
    #define SC_SYM_CHAT_NOPREF          "{p}"

#elseif SC_COLORS_TYPE == SC_COLORS_STANDARD
    #define SC_SYM_CHAT_NORMAL          "^1"
    #define SC_SYM_CHAT_TEAM            "^3"
    #define SC_SYM_CHAT_GREEN           "^4"
    #define SC_SYM_CHAT_WHITE           "^5"
    #define SC_SYM_CHAT_BLUE            "^6"
    #define SC_SYM_CHAT_RED             "^7"
    #define SC_SYM_CHAT_NOPREF          "^0"

#endif 

static const SC_NO_PREFIX[] =             SC_SYM_CHAT_NOPREF
static const SC_MENU_COLORS[][] =       { SC_SYM_MENU_YELLOW, SC_SYM_MENU_WHITE, SC_SYM_MENU_GREY, SC_SYM_MENU_RIGHT }
static const SC_REPLACE_COLORS[][] =    { SC_SYM_CHAT_NORMAL, SC_SYM_CHAT_DEFAULT_NORMAL, SC_SYM_CHAT_TEAM, SC_SYM_CHAT_DEFAULT_TEAM, SC_SYM_CHAT_GREEN, SC_SYM_CHAT_DEFAULT_GREEN }
static const SC_PLUS_COLORS_STR[][] =   { SC_SYM_CHAT_WHITE, SC_SYM_CHAT_BLUE, SC_SYM_CHAT_RED }
static const SC_PLUS_COLORS_INT[] =     { SC_COLOR_WHITE, SC_COLOR_BLUE, SC_COLOR_RED }
static const SC_COLORS_LIST[][] =       { SC_SYM_CHAT_NORMAL, SC_SYM_CHAT_TEAM, SC_SYM_CHAT_GREEN, SC_SYM_CHAT_WHITE, SC_SYM_CHAT_BLUE, SC_SYM_CHAT_RED, SC_SYM_CHAT_NOPREF }

/**
 * Sends a colored chat message
 *
 * @param id            Client index (use 0 to send to all players)
 * @param input         The message to send
 * @param ...           Formatting paramters
 *
 * @return              Length of printed message or 0 if no players were found
 */
stock SC_SendMessage( id, const input[], any:... )
{
    SC_ModInit()
    static iPlayers[ SC_MAX_PLAYERS ], iNum

    if ( id )
    {
        if ( !is_user_connected( id ) )
        {
            return 0
        }
    }
    else 
    {
        get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

        if ( !iNum )
        {
            return 0
        }
    }

    static szMessage[ SC_MAX_MESSAGE_SIZE ], szName[ SC_MAX_NAME_SIZE ], bool:bNoPrefix, i
    vformat( szMessage, sizeof( szMessage ), input, 3 )
    get_user_name( id, szName, charsmax( szName ) )

    bNoPrefix = bool:( equal( szMessage[ 1 ], SC_NO_PREFIX, charsmax( SC_NO_PREFIX ) ) || equal( szMessage[ 2 ], SC_NO_PREFIX, charsmax( SC_NO_PREFIX ) ))

    if ( bNoPrefix )
    {
        replace( szMessage, sizeof( szMessage ), SC_NO_PREFIX, "" )
    }
    else if ( SC_PREFIX[ 0 ] )
    {
        if ( SC_IS_CSCZ )
        {
            format( szMessage, sizeof( szMessage ), "%s%s %s: %s", SC_SYM_CHAT_DEFAULT_NORMAL, SC_PREFIX, szName, szMessage )
        }
        else 
        {
            format( szMessage, sizeof( szMessage ), "%s %s: %s", SC_PREFIX, szName, szMessage )
        }
    }

    for ( i = 0; i < sizeof( SC_REPLACE_COLORS ) - 1; i += 2 )
    {
        if ( contain( szMessage, SC_REPLACE_COLORS[ i ] ) != -1 )
        {
            if ( SC_IS_CSCZ )
            {
                replace_string( szMessage, sizeof( szMessage ), SC_REPLACE_COLORS[ i ], SC_REPLACE_COLORS[ i + 1 ] )
            }
            else 
            {
                replace_string( szMessage, sizeof( szMessage ), SC_REPLACE_COLORS[ i ], "" )
            }
        }
    }

    for ( i = 0; i < sizeof( SC_PLUS_COLORS_STR ); i ++ )
    {
        if ( contain( szMessage, SC_PLUS_COLORS_STR[ i ] ) != -1 )
        {
            if ( !SC_COLOR_FORCE )
            {
                SC_COLOR_PLAYER_INDEX = SC_PLUS_COLORS_INT[ i ]
            }

            for ( i = 0; i < sizeof( SC_PLUS_COLORS_STR ); i ++ )
            {
                if ( SC_IS_CSCZ )
                {
                    replace_string( szMessage, sizeof( szMessage ), SC_PLUS_COLORS_STR[ i ], SC_SYM_CHAT_DEFAULT_TEAM )
                }
                else 
                {
                    replace_string( szMessage, sizeof( szMessage ), SC_PLUS_COLORS_STR[ i ], "" )
                }
            }

            break

        }
    }

    if ( id )
    {
        SC_WriteMessage( id, szMessage )
    }
    else 
    {
        for ( i = 0; i < iNum; i ++ )
        {
            SC_WriteMessage( iPlayers[ i ], szMessage )
        }
    }

    SC_COLOR_FORCE = false
    SC_COLOR_PLAYER_INDEX = 0

    return strlen( szMessage )

}

/**
 * Sends a colored chat message matching a specific player's color.
 *
 * @note You can set the "player" argument to match a specific color
 *       To do this you can use of the following colors : 
 *       SC_COLOR_TEAM, SC_COLOR_GREY or ( SC_COLOR_WHITE ), SC_COLOR_BLUE and SC_COLOR_RED.
 *
 * @param id            Client index (use 0 to send to all players)
 * @param player        Matching player's index
 * @param input         The message to send
 * @param ...           Formatting paramters
 *
 * @return              Length of printed message
 */
 stock SC_SendMatched( id, player, const input[], any:... )
 {
    static szMessage[ SC_MAX_MESSAGE_SIZE ]
    vformat( szMessage, sizeof( szMessage ), input, 4 )

    SC_COLOR_PLAYER_INDEX = player
    // SC_COLOR_FORCE = true

    return SC_SendMessage( id, szMessage )
 }

 /**
  * Sends a colored chat message to group of players specified in "flags" with get_players()
  *
  *
  * @param flags        Matching players flags
  * @param param        String to match against if flags requires it
  * @param input        The message to send
  * @param ...          Formatting paramters
  *
  * @return             Length of printed message or 0 if no playerse were found
  */
 stock SC_GroupMessage( const flags[] = "", const param[] = "", const input[], any:... )
 {
    // new szMessage[ SC_MAX_MESSAGE_SIZE ], iPlayers[ SC_MAX_PLAYERS ], iNum
    // vformat( szMessage, sizeof( szMessage ), input, 4 )
    get_players( iPlayers, iNum, flags, param )

    if ( iNum == 0 )
    {
        return 0
    }

    static bool:bForce, iColor, i
    for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
    {
        SC_SetColor( iColor, bForce ) // useless for now 
        SC_SendMessage( iPlayers[ i ], input )
    }

    return strlen( input )
 }

/**
 * Sends a colored chat to all players with the specified admin flags
 *
 * @param flags         Admin Flags
 * @param allflags      If set to true, the player must match all the provided admin flags
 *                      instead he must match at least one admin flag
 * @param input         The Message to send 
 * @param ...           Formatting parameters 
 *
 * @return              Length of printed message or 0 if no players were found
 */
 stock SC_AdminMessage( const flags[] = "", bool:allflags = true, const input[], any:... )
 {
    // new szMessage[ SC_MAX_MESSAGE_SIZE ], iPlayers[ SC_MAX_PLAYERS ], iNum
    // vformat( szMessage, sizeof( szMessage ), input, 4 )
    get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

    if ( iNum == 0)
    {
        return 0
    }

    new bool:bForce, iColor, iCount, iFlags, iPlayer, i
    iFlags = read_flags( flags )
    iCount

    for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
    {
        iPlayer = iPlayers[ i ]
        if ( allflags )
        {
            if ( get_user_flags( iPlayer ) & iFlags != iFlags )
            {
                continue
            }
        }
        else 
        {
            if ( !( get_user_flags( iPlayer ) & iFlags ) )
            {
                continue
            }
        }

        iCount++

        SC_SetColor( iColor, bForce )
        SC_SendMessage( iPlayer, input )
    }

    if ( !iCount )
    {
        return 0
    }

    return strlen( input )
 }

/**
 * Sends a colored chat message and logs it at the same time 
 *
 * @param id            Client index (use 0 to send to all players)
 * @param file          The log file that will be used
 * @param input         The message to send
 * @param ...           Formatting paramters
 *
 * @return              Length of printed message or 0 if no players were found
 */
 stock SC_LogMessage( id, const file[] = "", const input[], any:... )
 {
    // new szMessage[ SC_MAX_MESSAGE_SIZE ]
    // vformat( szMessage, sizeof( szMessage ), input, 4 )
    if ( !SC_SendMessage( id, input ) )
    {
        return 0
    }
    SC_RemoveColors( input, sizeof( input ) )
    file[0] ? log_to_file( file, input ) : log_amx( input )

    return strlen( input )
 }

 /**
 * Send colored chat message to all players that obeys the amx_show_activity cvar
 *
 * @note This function was made to mimic show_activity() function, but sends a colored
 *       chat message using the SC_SendMessage() function, this means that the default 
 *       AMXX Function can directly be replaced with this one in order for it to display 
 *       a colored chat message rather than a default one 
 * @note By default smurfchat.inc will replace all the show_activity() functions in the file 
 *       with the SC_ShowActivity() function
 * @param id            Client index performing the action
 * @param name          Name of client performing the action
 * @param input         Formatting rules
 * @param ...           Formatting parameters
 * @return              Length of printed message or 0 if no players were found
 */
 stock SC_ShowActivity( id, const name[], const input[], any:... )
 {
    if ( SC_FIRST_TIME_ACTIVITY )
    {
        SC_ActivityInit()
    }
    static szMessage[ SC_MAX_MESSAGE_SIZE ], szPrefix[ SC_MAX_ACT_PREFIX_SIZE ], iPlayers[ SC_MAX_PLAYERS ], iNum, bool:bForce, iColor, iPlayer, i
    vformat( szMessage, sizeof( szMessage ), input, 4 )
    SC_GetActivityPrefix( id, szPrefix, charsmax( szPrefix ) )

    switch( get_pcvar_num( SC_ACTIVITY_POINTER ) )
    {
        case 1 : SC_SendMessage( id, "%L : %s", LANG_PLAYER, szPrefix, szMessage )
        case 2 : SC_SendMessage( id, "%L %s: %s", LANG_PLAYER, szPrefix, name, szMessage )
        case 3 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

            for ( i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    SC_SendMessage( iPlayer, "%L %s: %s", iPlayer, szPrefix, name, szMessage )
                }
                else 
                {
                    SC_SendMessage( iPlayer, "%L : %s", iPlayer, szPrefix, szMessage )
                }
            }
        }
        case 4 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

            for ( i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    SC_SendMessage( iPlayer, "%L %s: %s", iPlayer, szPrefix, name, szMessage )
                }
            }
        }
        case 5 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

            for ( i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    SC_SendMessage( iPlayer, "%L %s", iPlayer, szPrefix, szMessage )
                }
            }
        }
    }
 }

/**
 * Sends a colored chat message to a single client that obeys the amx_show_activity cvar
 *
 * @note This function is made to mimic the show_activity_id() function, but sends a
 *		 colored chat message instead using the SC_SendMessage() function. This means
 *		 that the default AMXX function can directly be replaced with this one in order
 *		 for it to display a colored chat message rather than a default one
 * @note By default, smurfchat.inc will replace all show_activity_id() functions in the file
 *		 with the SC_ShowActivityId() function
 *
 * @param target        Client index to display message to
 * @param id            Client index performing the action
 * @param name          Name of client performing the action
 * @param input         Formatting rules
 * @param ...           Variable number of formatting parameters
 *
 * @noreturn
 */
 stock SC_ShowActivityId( target, id, const name[], const input[], any:... )
 {
    if ( !is_user_connected( target ) )
    {
        return 
    }

    if ( SC_FIRST_TIME_ACTIVITY )
    {
        SC_ActivityInit()
    }
    static szMessage[ SC_MAX_MESSAGE_SIZE ], szPrefix[ SC_MAX_ACT_PREFIX_SIZE ]
    vformat( szMessage, sizeof( szMessage ), input, 4 )
    SC_GetActivityPrefix( id, szPrefix, charsmax( szPrefix ) )

    switch( get_pcvar_num( SC_ACTIVITY_POINTER ) )
    {
        case 1 : SC_SendMessage( target, "%L : %s", LANG_PLAYER, szPrefix, szMessage )
        case 2 : SC_SendMessage( target, "%L %s: %s", LANG_PLAYER, szPrefix, name, szMessage )
        case 3 : 
        {
            if ( SC_IsActivityAdmin( target ) )
            {
                SC_SendMessage( target, "%L %s: %s", target, szPrefix, name, szMessage )
            }
            else 
            {
                SC_SendMessage( target, "%L : %s", target, szPrefix, szMessage )
            }
        }
        case 4 : 
        {
            if ( SC_IsActivityAdmin( target ) )
            {
                SC_SendMessage( target, "%L %s: %s", target, szPrefix, name, szMessage )
            }
        }
        case 5 : 
        {
            if ( SC_IsActivityAdmin( target ) )
            {
                SC_SendMessage( target, "%L: %s", target, szPrefix, szMessage )
            }
        }
    }
 }

/**
 * Sends a colored chat message to all clients using normal language keys that obeys the amx_show_activity cvar
 *
 * @note This function is made to mimic the show_activity_id() function, but sends a
 *		 colored chat message instead using the SC_SendMessage() function. This means
 *		 that the default AMXX function can directly be replaced with this one in order
 *		 for it to display a colored chat message rather than a default one
 * @note By default, smurfchat.inc will replace all show_activity_key() functions in the file
 *		 with the SC_ShowActivityKey() function
 *
 * @param without           The language key that does not have the name field
 * @param with              The language key that does have the name field
 * @param name              The name of the person doing the action
 * @param ...               Pass any extra format arguments for the language key in the variable arguments list
 *
 * @noreturn
 */
 stock SC_ShowActivityKey( const without[], const with[], const name[], any:... )
 {
    #pragma unused name

    if ( SC_FIRST_TIME_ACTIVITY )
    {
        SC_ActivityInit()
    }

    static szKey[ SC_MAX_MESSAGE_SIZE ], iPlayers[ SC_MAX_PLAYERS ], iNum, bool:bForce, iColor, iPlayer, i

    switch( get_pcvar_num( SC_ACTIVITY_POINTER ) )
    {
        case 1 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )
            SC_SetColor( bForce, iColor )
            
            for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]
                LookupLangKey( szKey, sizeof( szKey ), without, iPlayer )
                SC_SendMessage( iPlayer, szKey )
            }
        }
        case 2 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )
            
            for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]
                LookupLangKey( szKey, sizeof( szKey ), with, iPlayer )
                SC_SendMessage( iPlayer, szKey )
            }
        }
        case 3 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )
            
            for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    LookupLangKey( szKey, sizeof( szKey ), with, iPlayer )
                }
                else 
                {
                    LookupLangKey( szKey, sizeof( szKey ), without, iPlayer )
                }

                SC_SendMessage( iPlayer, szKey )
            }
        }
        case 4 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )
            
            for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    LookupLangKey( szKey, sizeof( szKey ), with, iPlayer )
                    SC_SendMessage( iPlayer, szKey )
                }
            }
        }
        case 5 : 
        {
            get_players( iPlayers, iNum, SC_FILTERING_FLAGS )
            
            for ( bForce = SC_COLOR_FORCE, iColor = SC_COLOR_PLAYER_INDEX, i = 0; i < iNum; i ++ )
            {
                iPlayer = iPlayers[ i ]

                if ( SC_IsActivityAdmin( iPlayer ) )
                {
                    LookupLangKey( szKey, sizeof( szKey ), without, iPlayer )
                    SC_SendMessage( iPlayer, szKey )
                }
            }
        }
    }
 }

 /**
 * Replacing the coloring symbols with the appropriate coloring symbol
 *
 * @param message       Message to remove colors from
 * @param len           Maximum message length
 *
 * @return              Colored message or it might stay the same if no coloring symbols were detected
 */
 stock SC_ApplyColors( message[], len )
 {
    static i

    for ( i = 0; i < sizeof( SC_REPLACE_COLORS ); i += 2 )
    {
        replace_string( message, len, SC_REPLACE_COLORS[ i ], SC_REPLACE_COLORS[ i + 1 ] )
    }

    for ( i = 0; i < sizeof( SC_PLUS_COLORS_STR ); i ++ )
    {
        replace_string( message, len, SC_PLUS_COLORS_STR[ i ], SC_SYM_CHAT_DEFAULT_TEAM )
    }

 }

/**
 * Remove the colors from a message
 *
 * @param message       Message to remove colors from
 * @param len           Maximum message length
 * @param chat          If set to true, it will remove the chat color codes
 * @param menu          If set to true, it will remove the menu color codes
 *
 * @noreturn
 */
 stock SC_RemoveColors( message[], len, bool:chat = true, bool:menu = true )
 {
    static i
    if ( chat )
    {
        for ( i = 0; i < sizeof( SC_COLORS_LIST ); i ++ )
        {
            replace_string( message, len, SC_COLORS_LIST[ i ], "" )
        }
    }
    if ( menu )
    {
        for ( i = 0; i < sizeof( SC_MENU_COLORS ); i ++ )
        {
            replace_string( message, len, SC_MENU_COLORS[ i ], "" )
        }
    }

 }

 /**
 * Removes exploits from the message
 *
 * @note You can change the '%' replacement symbol by adding #define SC_PERCENT_REPLACE "symbol here" before #include <smurfchat>
 * @note It is strongly advised to use this function whenever you're sending messages based on hooking "say" or "say_team"
 *
 * @param message       The message to remove exploits from
 * @param len           Maximum message length
 * @param colors        If set to true, it will remove the ETX, EOT & SOH chat color codes
 *                      this prevents player from manually changing their chat color when they have the chance to
 * @param percent       If set to true, it will replace the '%' symbol with '％'
 *
 * @noreturn
 */
stock SC_RemoveExploits( message[], len, bool:colors = true, bool:percent = true )
{
	static i

	if( colors )
	{
		static const SC_COLOR_EXPLOITS[][] = { "", "", "" }

		for( i = 0; i < sizeof( SC_COLOR_EXPLOITS ); i++ )
		{
			replace_string( message, len, SC_COLOR_EXPLOITS[i], "" )
		}
	}

	if( percent )
	{
		static const SC_PERCENT_FIND[] = "%"
		replace_string( message, len, SC_PERCENT_FIND, SC_PERCENT_REPLACE )
	}
}

/**
 * Sets a global prefix that will be used for all sent messages.
 *
 * @note The prefix can be removed in a given message if the prefix-removing symbol is
 *       used in the beginning of the message. By default, this symbol is equal to &x00.
 *
 * @param prefix        Prefix to set
 *
 * @noreturn
 */
stock SC_SetPrefix( const prefix[] )
{
	SC_ModInit()
	copy( SC_PREFIX, charsmax( SC_PREFIX ), prefix )

	if( !SC_IS_CSCZ )
	{
		CC_RemoveColors( SC_PREFIX, charsmax( SC_PREFIX ) )
	}
}
	
/**
 * Removes the global message prefix.
 *
 * @noreturn
 */
stock SC_RemovePrefix()
{
	SC_PREFIX[0] = EOS
}

 /**
 * Sets the team color for the message that going to be sent
 *
 * @param color         SC_COLOR_* or player index to get team color
 * @param force         if set to true, custom colors in the code will be ignored 
 *                      and the message will be forced to use the color set here
 *
 * @noreturn
 */
 stock SC_SetColor( color, bool:force = false )
 {
    SC_COLOR_PLAYER_INDEX = color
    SC_COLOR_FORCE = force
 }

/**
 * This function is used by other stocks in order to send raw stock
 *
 * @param id            Client index (use 0 to send to all players)
 * @param message       The message to send
 *
 * @noreturn
 */
 stock SC_WriteMessage( id, const message[] )
 {
    static SC_INIT, SC_MSG_SAYTEXT

    if ( !SC_INIT )
    {
        SC_INIT = true
        SC_MSG_SAYTEXT = get_user_msgid( "SayText" )

        if ( !LibraryExists( SC_LIBRARY_NAME, LibType_Library ) )
        {
            register_library( SC_LIBRARY_NAME )

            if ( SC_IS_CSCZ )
            {
                new iCacheList[]        = { SC_COLOR_GREY, SC_COLOR_BLUE, SC_COLOR_RED }
                new szCacheList[][]     = { "SPECTATOR", "CT", "TERRORIST" }
                new SC_MSG_TEAMINFO     = get_user_msgid( "TeamInfo" )

                for ( new i = 0; i < sizeof( iCacheList ); i ++ )
                {
                    engfunc( EngFunc_MessageBegin, MSG_INIT, SC_MSG_TEAMINFO, 0, 0 )
                    write_byte( iCacheList[ i ] )
                    write_string( szCacheList[ i ] )
                    message_end()
                }

                new iPlayers[ SC_MAX_PLAYERS ], iNum
                get_players( iPlayers, iNum, SC_FILTERING_FLAGS )

                for ( new i, j, id; i < iNum; i ++ )
                {
                    id = iPlayers[ i ]

                    for ( j = 0; j < sizeof( iCacheList ); j ++ )
                    {
                        message_begin( MSG_ONE, SC_MSG_TEAMINFO, .player = id )
                        write_byte( iCacheList[ j ] )
                        write_string( szCacheList[ j ] )
                        message_end()
                    }
                }
            }
        }
    }

    static const SC_PLAYER_ITEM_PHRASE[] = "#Spec_PlayerItem"

    message_begin( MSG_ONE, SC_MSG_SAYTEXT, .player = id )

    if ( SC_IS_CSCZ )
    {
        write_byte( SC_COLOR_PLAYER_INDEX && SC_COLOR_PLAYER_INDEX != SC_COLOR_TEAM ? SC_COLOR_PLAYER_INDEX : id )
    }
    else 
    {
        write_byte( id )
    } 

    write_string( SC_PLAYER_ITEM_PHRASE )
    write_string( message )
    message_end()
 }



/**
 * Checks if the server is running Counter-Strike
 *
 * @noreturn 
 */
stock SC_ModInit()
{
    static bool:SC_MOD_INIT

    if ( !SC_MOD_INIT ){

        SC_MOD_INIT = true

        static const SC_CSTRIKE_MODNAME[]   = "cstrike"
        static const SC_CZERO_MODNAME[]     = "czero"
        
        new szModName[ sizeof( SC_CSTRIKE_MODNAME ) ]
        get_modname( szModName, sizeof( szModName ) )

        if ( equal( szModName, SC_CSTRIKE_MODNAME ) || equal( szModName, SC_CZERO_MODNAME ) )
        {
            SC_IS_CSCZ = true
        }
    }
}

 /**
 * Stores the amx_show_activity pointer for use with "ShowActivity" functions.     	
 *
 * @noreturn
 */
stock SC_ActivityInit()
{
	SC_FIRST_TIME_ACTIVITY = false
	SC_ACTIVITY_POINTER = get_cvar_pointer( "amx_show_activity" )

	if( !SC_ACTIVITY_POINTER )
	{
		SC_ACTIVITY_POINTER = register_cvar( "amx_show_activity", "2", FCVAR_PROTECTED )
	}
}

/**
 * Returns the player prefix used with "ShowActivity" functions
 *
 * @param id            Client index
 * @param buffer        Buffer to store the prefix in
 * @param len           Maximum buffer length
 *
 * @noreturn
 */
stock SC_GetActivityPrefix( id, buffer[ SC_MAX_ACT_PREFIX_SIZE ], len )
{
	copy( buffer, len, SC_IsActivityAdmin( id ) ? SC_ACTIVITY_PREFIX_ADMIN : SC_ACTIVITY_PREFIX_PLAYER )
}

/**
 * Checks whether the client has the required flag to be marked as an admin for the "ShowActivity" functions.
 *
 * @param id        Client index
 *
 * @return          True if he has, false otherwise
 */
stock bool:SC_IsActivityAdmin( id )
{
	#if SC_ACTIVITY_FLAG == -1
	static iFlags
	iFlags = get_user_flags( id )
	return ( iFlags > 0 && !( iFlags & ADMIN_USER ) )
	#else
	return bool:( get_user_flags( id ) & SC_ACTIVITY_FLAG )
	#endif
}






    











