/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Basic Votes Plugin
 * Provides kick functionality
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

void DisplayVoteKickMenu(int client, int target)
{
	g_voteClient[VOTE_CLIENTID] = target;
	g_voteClient[VOTE_USERID] = GetClientUserId(target);

	GetClientName(target, g_voteInfo[VOTE_NAME], sizeof(g_voteInfo[]));

	LogAction(client, target, "\"%L\" initiated a kick vote against \"%L\"", client, target);
	ShowActivity(client, "%t", "Initiated Vote Kick", g_voteInfo[VOTE_NAME]);
	
	g_voteType = kick;
	
	if (g_NativeVotes)
	{
		NativeVote voteMenu = new NativeVote(Handler_NativeVoteCallback, NativeVotesType_Kick, MENU_ACTIONS_ALL);
		// No title, builtin type
		voteMenu.SetTarget(target);
		voteMenu.DisplayVoteToAll(20);
	}
	else
	{
		Menu voteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
		voteMenu.SetTitle("Votekick Player");
		voteMenu.AddItem(VOTE_YES, "Yes");
		voteMenu.AddItem(VOTE_NO, "No");
		voteMenu.ExitButton = false;
		voteMenu.DisplayVoteToAll(20);
	}
}

void DisplayKickTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Kick);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Kick vote", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, false, false);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public void AdminMenu_VoteKick(Handle topmenu, 
							  TopMenuAction action,
							  TopMenuObject object_id,
							  int param,
							  char[] buffer,
							  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Kick vote", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayKickTargetMenu(param);
	}
	else if (action == TopMenuAction_DrawOption)
	{	
		/* disable this option if a vote is already running */
		buffer[0] = !Internal_IsNewVoteAllowed() ? ITEMDRAW_IGNORE : ITEMDRAW_DEFAULT;
	}
}

public int MenuHandler_Kick(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
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
			else
			{
				g_voteArg[0] = '\0';
				DisplayVoteKickMenu(param1, target);
			}
		}
	}
}

public Action Command_Votekick(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_votekick <player> [reason]");
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
	
	int len = BreakString(text, arg, sizeof(arg));
	
	int target = FindTarget(client, arg);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	if (len != -1)
	{
		strcopy(g_voteArg, sizeof(g_voteArg), text[len]);
	}
	else
	{
		g_voteArg[0] = '\0';
	}
	
	DisplayVoteKickMenu(client, target);
	
	return Plugin_Handled;
}