/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Basic Votes Plugin
 * Provides map functionality
 *
 * NativeVotes (C)2011-2015 Ross Bemrose (Powerlord).  All rights reserved.
 * SourceMod (C)2004-2015 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

Menu g_MapList;
int g_mapCount;

ArrayList g_SelectedMaps;
bool g_VoteMapInUse;

void DisplayVoteMapMenu(int client, int mapCount, char[][] maps)
{
	LogAction(client, -1, "\"%L\" initiated a map vote.", client);
	ShowActivity2(client, "[SM] ", "%t", "Initiated Vote Map");
	
	g_voteType = map;
	
	if (g_NativeVotes && (mapCount == 1 || NativeVotes_IsVoteTypeSupported(NativeVotesType_NextLevelMult)) )
	{
		NativeVote voteMenu;
		
		if (mapCount == 1)
		{
			strcopy(g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]), maps[0]);
			
			voteMenu = new NativeVote(Handler_NativeVoteCallback, NativeVotesType_ChgLevel, MENU_ACTIONS_ALL);
			
			// No title, builtin type
			voteMenu.SetDetails(maps[0]);
		}
		else
		{
			voteMenu = new NativeVote(Handler_NativeVoteCallback, NativeVotesType_NextLevelMult, MENU_ACTIONS_ALL);

			g_voteInfo[VOTE_NAME][0] = '\0';
			
			// No title, builtin type
			for (int i = 0; i < mapCount; i++)
			{
				voteMenu.AddItem(maps[i], maps[i]);
			}
		}
		
		voteMenu.DisplayVoteToAll(20);
	}
	else
	{
		Menu voteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		
		if (mapCount == 1)
		{
			strcopy(g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]), maps[0]);
				
			voteMenu.SetTitle("Change Map To");
			voteMenu.AddItem(maps[0], "Yes");
			voteMenu.AddItem(VOTE_NO, "No");
		}
		else
		{
			g_voteInfo[VOTE_NAME][0] = '\0';
			
			voteMenu.SetTitle("Map Vote");
			for (int i = 0; i < mapCount; i++)
			{
				voteMenu.AddItem(maps[i], maps[i]);
			}	
		}
		
		voteMenu.ExitButton = false;
		voteMenu.DisplayVoteToAll(20);
	}
}

void ResetMenu()
{
	g_VoteMapInUse = false;
	g_SelectedMaps.Clear();
}

void ConfirmVote(int client)
{
	Menu menu = new Menu(MenuHandler_Confirm);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Confirm Vote", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	char itemtext[256];
	Format(itemtext, sizeof(itemtext), "%T", "Start the Vote", client);
	menu.AddItem("Confirm", itemtext);
	
	menu.Display(client, MENU_TIME_FOREVER);	
}

public int MenuHandler_Confirm(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
			g_VoteMapInUse = false;
		}
		
		case MenuAction_Cancel:
		{
			ResetMenu();
			
			if (param2 == MenuCancel_ExitBack && hTopMenu != null)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			char maps[5][PLATFORM_MAX_PATH];
			int selectedmaps = g_SelectedMaps.Length;
			
			for (int i = 0; i < selectedmaps; i++)
			{
				g_SelectedMaps.GetString(i, maps[i], sizeof(maps[]));
			}
			
			DisplayVoteMapMenu(param1, selectedmaps, maps);
			
			ResetMenu();
		}
	}
}

public int MenuHandler_Map(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{		
			if (param2 == MenuCancel_ExitBack && hTopMenu != null)
			{
				ConfirmVote(param1);
			}
			else // no action was selected.
			{
				/* Re-enable the menu option */
				ResetMenu();
			}
		}
		
		case MenuAction_DrawItem:
		{
			char info[32], name[32];
			
			menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			
			if (g_SelectedMaps.FindString(info) != -1)
			{
				return ITEMDRAW_IGNORE;
			}
			else
			{
				return ITEMDRAW_DEFAULT;
			}
		}
		
		case MenuAction_Select:
		{
			char info[32], name[32];
			
			menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			
			g_SelectedMaps.PushString(info);
			
			/* Redisplay the list */
			if (g_SelectedMaps.Length < 5)
			{
				g_MapList.Display(param1, MENU_TIME_FOREVER);
			}
			else
			{
				ConfirmVote(param1);
			}
		}
		
		case MenuAction_Display:
		{
			char title[128];
			Format(title, sizeof(title), "%T", "Please select a map", param1);
			Panel panel = view_as<Panel>param2;
			panel.SetTitle(title);
		}
	}
	
	return 0;
}

public void AdminMenu_VoteMap(Handle topmenu, 
							  TopMenuAction action,
							  TopMenuObject object_id,
							  int param,
							  char[] buffer,
							  int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%T", "Map vote", param);
		}
		
		case TopMenuAction_SelectOption:
		{
			if (!g_VoteMapInUse)
			{
				ResetMenu();
				g_VoteMapInUse = true;
				g_MapList.Display(param, MENU_TIME_FOREVER);
			}
			else 
			{
				PrintToChat(param, "[SM] %T", "Map Vote In Use", param);
			}
		}
		
		case TopMenuAction_DrawOption:
		{	
			/* disable this option if a vote is already running, theres no maps listed or someone else has already acessed this menu */
			buffer[0] = (!Internal_IsNewVoteAllowed() || g_mapCount < 1 || g_VoteMapInUse) ? ITEMDRAW_IGNORE : ITEMDRAW_DEFAULT;
		}
	}
}

public Action Command_Votemap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_votemap <mapname> [mapname2] ... [mapname5]");
		return Plugin_Handled;	
	}
	
	if (Internal_IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
		
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	char text[256];
	GetCmdArgString(text, sizeof(text));

	char maps[5][64];
	int mapCount;	
	int len, pos;
	
	while (pos != -1 && mapCount < 5)
	{	
		pos = BreakString(text[len], maps[mapCount], sizeof(maps[]));
		
		if (!IsMapValid(maps[mapCount]))
		{
			ReplyToCommand(client, "[SM] %t", "Map was not found", maps[mapCount]);
			return Plugin_Handled;
		}		

		mapCount++;
		
		if (pos != -1)
		{
			len += pos;
		}	
	}

	DisplayVoteMapMenu(client, mapCount, maps);
	
	return Plugin_Handled;	
}

ArrayList g_map_array;
int g_map_serial = -1;

int LoadMapList(Menu menu)
{
	ArrayList map_array;
	
	if ((map_array = view_as<ArrayList>(ReadMapList(g_map_array,
			g_map_serial,
			"sm_votemap menu",
			MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_MAPSFOLDER)))
		!= null)
	{
		g_map_array = map_array;
	}
	
	if (g_map_array == null)
	{
		return 0;
	}
	
	menu.RemoveAllItems();
	
	char map_name[PLATFORM_MAX_PATH];
	int map_count = g_map_array.Length;
	
	for (int i = 0; i < map_count; i++)
	{
		g_map_array.GetString(i, map_name, sizeof(map_name));
		menu.AddItem(map_name, map_name);
	}
	
	return map_count;
}
