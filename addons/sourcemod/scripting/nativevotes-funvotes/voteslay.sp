 /**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Fun Votes Plugin
 * Provides voteslay functionality
 *
 * NativeVotes (C)2011-2014 Ross Bemrose (Powerlord).  All rights reserved.
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
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

void DisplayVoteSlayMenu(int client, int target, char[] name)
{
	if (!IsPlayerAlive(target))
	{
		ReplyToCommand(client, "[SM] %t", "Cannot be performed on dead", name);
		return;
	}
	
	g_voteClient[VOTE_CLIENTID] = target;
	GetClientName(target, g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]));

	LogAction(client, target, "\"%L\" initiated a slay vote against \"%L\"", client, target);
	ShowActivity2(client, "[SM] ", "%t", "Initiated Vote Slay", g_voteInfo[VOTE_NAME]);
	
	g_voteType = slay;
	
	if (g_NativeVotes)
	{
		NativeVote hVoteMenu = new NativeVote(Handler_NativeVoteCallback, NativeVotesType_Custom_YesNo, MENU_ACTIONS_ALL);
		hVoteMenu.SetTitle("Voteslay Player");
		hVoteMenu.DisplayVoteToAll(20);
	}
	else
	{
		Menu hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		hVoteMenu.SetTitle("Voteslay Player");
		hVoteMenu.AddItem(VOTE_YES, "Yes");
		hVoteMenu.AddItem(VOTE_NO, "No");
		hVoteMenu.ExitButton = false;
		hVoteMenu.DisplayVoteToAll(20);
	}
}

void DisplaySlayTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Slay);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Slay vote", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public void AdminMenu_VoteSlay(Handle topmenu, 
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
			Format(buffer, maxlength, "%T", "Slay vote", param);
		}
		
		case TopMenuAction_SelectOption:
		{
			DisplaySlayTargetMenu(param);
		}
		
		case TopMenuAction_DrawOption:
		{	
			/* disable this option if a vote is already running */
			buffer[0] = !Internal_IsNewVoteAllowed() ? ITEMDRAW_IGNORE : ITEMDRAW_DEFAULT;
		}
	}
}

public int MenuHandler_Slay(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			char info[32], name[32];
			int userid, target;
			
			menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[SM] %t", "Unable to target");
			}
			else if (!IsPlayerAlive(target))
			{
				PrintToChat(param1, "[SM] %t", "Player has since died");
			}
			else
			{
				DisplayVoteSlayMenu(param1, target, name);
			}
		}
	}
}

public Action Command_VoteSlay(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_voteslay <player>");
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
	
	char text[256], arg[64];
	GetCmdArgString(text, sizeof(text));
	
	BreakString(text, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int[] target_list = new int[MaxClients];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MaxClients,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	DisplayVoteSlayMenu(client, target_list[0], arg);
	
	return Plugin_Handled;
}
