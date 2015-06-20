
mob/Player
	var/tmp
		spellBookOpen = FALSE
		list/spells
	verb
		spellBookClosed()
			set name= ".spellBookClosed"
			spellBookOpen = 0
			toggle_actionbar(0)

	proc

		saveSpells()
			if(!UsedKeys) return

			for(var/k in UsedKeys)
				if(istype(UsedKeys[k], /obj/spells))
					var/obj/spells/s = UsedKeys[k]

					if((s.path in verbs) || !s.path)
						UsedKeys[k] = s.name
					else
						UsedKeys -= k

		loadSpells()
			if(!UsedKeys || !spells) return

			for(var/k in UsedKeys)
				var/o = UsedKeys[k]
				if(istext(o))
					UsedKeys[k] = spells[o]

		updateSpellbook()

			var/list/verbList = list("Meditate", "Take")

			if(!spells) spells = list()
			var/count = spells.len

			for(var/v in verbList)
				if(v in spells) continue
				count++
				var/obj/spells/o = new (null, v, null)
				spells[v] = o

				src << output(o, "SpellBook.gridSpellbook:[count]")

			for(var/v in verbs)
				var/mob/Spells/verb/generic = v
				if(generic.name in spells)                     continue
				if(!findtext("[v]", "/mob/Spells/verb")) continue
				count++

				var/obj/spells/o = new (null, generic.name, text2path("[v]"))
				spells[generic.name] = o

				src << output(o, "SpellBook.gridSpellbook:[count]")

obj/spells
	icon = 'SpellbookIcons.dmi'

	var/path

	New(Loc, name, path)
		..()

		src.name   = name
		src.path   = path
		icon_state = name


	Click()
		var/mob/m = usr
		if(path && !(path in m.verbs))
			if(m:spells && (src in m:spells))
				m:spells -= src
				return
			if(m:UsedKeys)
				for(var/k in m:UsedKeys)
					var/obj/o = m:UsedKeys[k]
					if(o == src)
						m:removeKey(k)
						m:UsedKeys -= k
						break
		switch(name)
			if("Glacius")
				m:Glacius()
			if("Inflamari")
				m:Inflamari()
			if("Waddiwasi")
				m:Waddiwasi()
			if("Flippendo")
				m:Flippendo()
			if("Incindia")
				m:Incindia()
			if("Incendio")
				m:Incendio()
			if("Tremorio")
				m:Tremorio()
			if("Aqua Eructo")
				m:Aqua_Eructo()
			if("Chaotica")
				m:Chaotica()
			if("Meditate")
				m.Meditate()
			if("Episkey")
				m:Episky()

	MouseDrag()
		..()
		usr.client.mouse_pointer_icon = icon(icon,icon_state)

	MouseDrop(over_object,src_location,over_location,src_control,over_control,params)
		..()
		usr.client.mouse_pointer_icon = 'pointer.dmi'
		if(istype(over_object, /obj/actionbar/keys))
			var/obj/actionbar/keys/k = over_object
			k.SetKey(src)

obj/hud/spellbook

	icon = 'HUD.dmi'
	icon_state = "spellbook"
	screen_loc = "EAST-2,1"
	mouse_over_pointer = MOUSE_HAND_POINTER

	Click()
		..()
		var/mob/Player/p = usr
		if(p.spellBookOpen)
			p.spellBookOpen = 0
			winshow(p, "SpellBook", 0)
		else
			p.spellBookOpen = 1
			p.updateSpellbook()
			winshow(p, "SpellBook", 1)

		p.toggle_actionbar(p.spellBookOpen)