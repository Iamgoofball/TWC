/*
 * Copyright � 2014 Duncan Fairley
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */

mob/TalkNPC
	EventMob
		icon = 'NPCs.dmi'
		icon_state = "palmer"
		name = "Event Mob"
		Gm = 1

		var
			list
				AlreadyGiven = list()
				id = list()
			Message = "Hello."

		/*
		This mob gives an item once to everyone who talks to it.
		*/
		Item
			var/EventItem
			var/Unique

			Talk()
				set src in oview(3)
				if(!EventItem)
					usr << "<span style=\"font-size:2; color:red;\"><b>[src]</b> : </span>I have nothing to give you."
					return
				if(..())
					if(Unique && (locate(text2path(EventItem)) in usr))
						usr << "<span style=\"font-size:2; color:red;\"><b>[src]</b> : </span>You already have the item I'm giving, move along!"
						return

					var/obj/O = new EventItem(usr)
					usr:Resort_Stacking_Inv()
					usr << "<span style=\"font-size:2; color:red;\">[src] hands you their [O.name].</span>"

		/* This mob changes a var to everyone who talks to it.
		   It can add/remove/double for number values. (Adding also works for lists I guess)
		   For example, it can give everyone who talks to it 100 Gold once. */
		Variable
			var
				EventVar
				VarTo
				Function = "+"

			Talk()
				set src in oview(3)
				if(!EventVar)
					usr << " <span style=\"font-size:2; color:red;\"><b>[src]</b> : </span>I have nothing to give you."
					return
				if(..())
					if(Function == "=")
						usr.vars[EventVar] = VarTo
					else if(Function == "+")
						usr.vars[EventVar] += VarTo
					else if(Function == "*")
						usr.vars[EventVar] *= VarTo


		Talk()
			set src in oview(3)
			if(AlreadyGiven == "reset")
				AlreadyGiven = list()
				id = list()
			if((usr.ckey in AlreadyGiven) || (usr.client.computer_id in id))
				usr << " <span style=\"font-size:2; color:red;\"><b>[src]</b> : </span>Hello! I've seen you before!"
				return 0
			else
				usr << " <span style=\"font-size:2; color:red;\"><b>[src]</b> : </span>[Message]"
				AlreadyGiven.Add(usr.ckey)
				id.Add(usr.client.computer_id)
				return 1

mob/Player
	var/tmp
		EditVar
		EditVal
		ClickEdit = 0
		ClickCreate = 0
		CreatePath
mob/GM
	verb
		Toggle_Click_Create()
			set category = "Events"
			var/mob/Player/p = src
			if(p.ClickCreate)
				p.ClickCreate = 0
				p.CreatePath = null
				p << "Click Creating mode toggled off."
			else
				if(p.ClickEdit) Toggle_Click_Editing()
				p.ClickCreate = 1
				p << "Click Creating mode toggled on."
		Toggle_Click_Editing()
			set category = "Events"
			var/mob/Player/p = src
			if(p.ClickEdit)
				p.ClickEdit = 0
				p.EditVar = null
				p.EditVal = null
				p << "Click Editing mode toggled off."
			else
				if(p.ClickCreate) Toggle_Click_Create()
				p.ClickEdit = 1
				p << "Click Editing mode toggled on."
		CreatePath(Path as null|anything in typesof(/area,/turf,/obj,/mob) + list("Delete"))
			set category = "Events"
			var/mob/Player/p = src
			p.CreatePath = Path
			p << "Your CreatePath is now set to [Path]."
		MassEdit(Var as text)
			set category = "Events"
			var/mob/Player/p = src
			var/Type = input("What type?","Var Type") as null|anything in list("text","num","reference","null")
			if(Type)
				p.EditVar = Var
				switch(Type)
					if("text")
						p.EditVal = input("Value:","Text") as text
						p << "Your MassEdit variable is now [p.EditVar] with the text value [p.EditVal]."
					if("num")
						p.EditVal = input("Value:","Number") as num
						p << "Your MassEdit variable is now [p.EditVar] with the number value [p.EditVal]."
					if("reference")
						p.EditVal = input("Value:","Reference") as area|turf|obj|mob in world
						p << "Your MassEdit variable is now [p.EditVar] with the reference [p.EditVal]."
					if("null")
						p.EditVal = null
		FFA_Mode(var/dmg as num, var/os as anything in list("On", "Off"))
			set category = "Events"
			var/area/a = locate(/area/arenas/MapThree/PlayArea)
			a.dmg = dmg
			a.oldsystem = os == "On"
			src << infomsg("Set dmg modifier to [dmg], old system is [os].")



atom/Click(location)
	..()

	var/mob/Player/p = usr
	if(p.ClickEdit)
		if(!p.admin)
			p << errormsg("Only Admins can use this.")
			return
		if(!p.EditVar)
			p << "Pick a var to edit using MassEdit verb."
		else if(p.EditVar in vars)
			vars[p.EditVar] = p.EditVal
	else if(p.ClickCreate)
		if(!p.CreatePath)
			p << "Pick a path to create using CreatePath verb."
		else

			if(!p.admin && (p.z < SWAPMAP_Z || src.z < SWAPMAP_Z || ispath(p.CreatePath, /obj/items) || ispath(p.CreatePath, /mob)))
				p << errormsg("Can't use outside swap maps or create items/mobs.")
				return

			if(p.CreatePath == "Delete" && !isplayer(src))
				del src
			else if(isturf(location))
				new p.CreatePath (location)
