/*
 * Copyright � 2014 Duncan Fairley
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */
mob/TalkNPC/merchant

	New()
		..()

		var/f = pick("Soxlax", "Zotold", "Noik", "Nixelee", "Zotgbles", "Jarex", "Filax", "Rizlax", "Zeeard", "Zeemo")
		var/l = pick("", " Goldnose", " Silvernose", " Saltmine", " Scrollgrinder", " Moneygear", " Saltytongue", " Steamrocket", " Sharpfingers", " Boomknob")

		name = "[f][l]"

		icon_state = "goblin[rand(1,3)]"

	Talk()
		set src in oview(3)
		var/mob/Player/p = usr
		p.auctionOpen()

proc
	init_auction()
		var/Event/Auction/e = new
		scheduler.schedule(e, world.tick_lag * 3 * 600)

	auctionBidTime()
		if(worldData.auctionItems)
			for(var/auction/a in worldData.auctionItems)
				if(!a.item)
					worldData.auctionItems -= a
					continue
				if(world.realtime - a.time >= 2592000 || !a.item.canAuction) // 3 days
					if(a.bid && a.bidder)
						mail(a.bidder, infomsg("Auction: You won the auction for the [a.item.name]."),     a.item)
						mail(a.owner,  infomsg("Auction: Your [a.item.name] was sold during an auction."), a.minPrice)

						goldlog << "[time2text(world.realtime,"MMM DD YYYY - hh:mm")]: (Bid) [a.owner] sold [a.item.name] x[a.item.stack] to [a.bidder] for [a.minPrice]<br />"
					else
						mail(a.owner,  errormsg("Auction: The [a.item.name] auction expired."), a.item)
					a.item = null
					worldData.auctionItems -= a
					if(!worldData.auctionItems.len) worldData.auctionItems = null

mail
	var
		message
		content

	New(i_Message, i_Content)
		..()
		content = i_Content
		message = i_Message

	proc/send(mob/Player/i_Player)
		if(message)
			i_Player << message
		if(content)
			if(isnum(content))
				i_Player << infomsg("[comma(content)] gold was sent to your bank.")
				i_Player.goldinbank.add(content)
			else
				var/obj/o = content
				i_Player << infomsg("[o.name] was sent to you.")
				o.loc = i_Player
				i_Player.Resort_Stacking_Inv()



proc/mail(i_Ckey, i_Message, i_Content)
	var/mail/m = new/mail(i_Message, i_Content)

	for(var/mob/Player/p in Players)
		if(p.ckey == i_Ckey)
			m.send(p)
			return

	if(!worldData.mailTracker) worldData.mailTracker = list()

	if(i_Ckey in worldData.mailTracker)
		if(islist(worldData.mailTracker[i_Ckey]))
			worldData.mailTracker[i_Ckey] += m
		else
			worldData.mailTracker[i_Ckey] = list(worldData.mailTracker[i_Ckey], m)
	else
		worldData.mailTracker[i_Ckey] = m

mob/Player/proc/checkMail()
	if(ckey in worldData.mailTracker)
		if(islist(worldData.mailTracker[ckey]))
			for(var/mail/m in worldData.mailTracker[ckey])
				m.send(src)
		else
			var/mail/m = worldData.mailTracker[ckey]
			m.send(src)
		worldData.mailTracker -= ckey

auction
	var

		bid
		bidder
		buyout
		minPrice
		buyoutPrice
		obj/items/item
		time
		owner



	Topic(href, href_list[])
		.=..()
		var/mob/Player/p = usr
		if(!(src in worldData.auctionItems)) return

		if(!src || !p) return
		if(!src.item)
			worldData.auctionItems -= src
			if(bidder)
				mail(bidder, errormsg("<b>Auction:</b> The auction for the [item.name] was cancelled."), minPrice)

			return


		if(href_list["action"] == "bidAuction")

			if(bid && owner != p.ckey && bidder != p.ckey)
				var/price = max(round(minPrice + (minPrice/10), 1), 1)
				if(p.gold.get() >= price)

					if(bidder)
						mail(bidder, errormsg("<b>Auction:</b> You were outbid for the [item.name] auction."), minPrice)

					bid++
					bidder   = p.ckey
					minPrice = price
					p.gold.add(-price)
					p.auctionBuild()
				else
					p << errormsg("You don't have enough money, the item costs [comma(price)] gold, you need [comma(price - p.gold.get())] more gold.")

		else if(href_list["action"] == "buyoutAuction")
			if(buyout && owner != p.ckey)

				if(p.gold.get() >= buyoutPrice)
					p.gold.add(-buyoutPrice)

					if(bid && bidder)
						mail(bidder, errormsg("<b>Auction:</b> The [item.name] auction was bought out at the auction, your bid is cancelled."), minPrice)

					var/taxedGold = round(buyoutPrice - (buyoutPrice/20), 1)
					mail(owner, infomsg("<b>Auction:</b> [item.name] was bought at the auction."), taxedGold)
					goldlog << "[time2text(world.realtime,"MMM DD YYYY - hh:mm")]: (Buyout) [owner] sold [item.name] to [p.name] ([p.ckey]) ([p.client.address]) for [buyoutPrice]<br />"

					worldData.auctionItems -= src
					if(!worldData.auctionItems.len) worldData.auctionItems = null
					p << infomsg("<b>Auction:</b> You bought [item.name] for [buyoutPrice] gold.")
					item.loc = p
					item = null
					p.Resort_Stacking_Inv()
					p.auctionBuild()
				else
					p << errormsg("You don't have enough money, the item costs [comma(buyoutPrice)] gold, you need [comma(buyoutPrice - p.gold.get())] more gold.")


		else if(href_list["action"] == "removeAuction")
			if(owner == p.ckey)
				worldData.auctionItems -= src
				if(!worldData.auctionItems.len) worldData.auctionItems = null

				if(bid && bidder)
					mail(bidder, errormsg("<b>Auction:</b> The auction for the [item.name] was cancelled."), minPrice)

				p << infomsg("<b>Auction:</b> You removed [item.name] from auction.")
				p.auctionBuild()
				item.Move(p)
				item = null
				p.Resort_Stacking_Inv()




mob/Player
	var/tmp
		auction/auctionInfo
		auctionCount = 0

	proc
		auctionBuild()
			auctionCount = 0
			var/count = 2
			if(worldData.auctionItems)

				var/const/style = {"\
body
{
	text-align:center;
	background-color:#a8d8f0;
	color:#508cb4;
}

.content
{
	text-align:center;
	vertical-align:middle;
}
"}

				winset(src, null, "Auction.gridAuction.cells=6x[worldData.auctionItems.len + 2];Auction.gridAuction.style='[style]'")
				if(!worldData.auctionItems) return

				var/list/filters = list("Auction.buttonClothing" = /obj/items/wearable,
				                        "Auction.buttonShoes"    = /obj/items/wearable/shoes,
				                        "Auction.buttonScarves"  = /obj/items/wearable/scarves,
				                        "Auction.buttonWands"    = /obj/items/wearable/wands,
				                        "Auction.buttonTitle"    = /obj/items/wearable/title,
				                        "Auction.buttonOther",
				                        "Auction.buttonOwned",
				                        "Auction.buttonNotOwned")

				var/qry = ""
				for(var/f in filters)
					qry += "[f];"

				var/list/options = params2list(winget(src, qry, "is-checked"))

				var/option
				for(var/i = 1 to 6)
					var/o = options[i]
					if(options[o] == "true")
						option = copytext(o, 1, -11)
						break

				for(var/i = 1 to worldData.auctionItems.len)
					var/auction/a = worldData.auctionItems[i]
					if(!a.item) continue
					if(a.owner == ckey)
						auctionCount++

					if(option)
						if(option == "Auction.buttonOther")
							if(istype(a.item, /obj/items/wearable)) continue
						else if(!istype(a.item, filters[option]))   continue

					if(options["Auction.buttonOwned.is-checked"]    == "false" && a.owner == ckey) continue
					if(options["Auction.buttonNotOwned.is-checked"] == "false" && a.owner != ckey) continue

					count++

					src << output(a.item,                                         "Auction.gridAuction:1,[count]")
					src << output("<span class='content'>x[a.item.stack]</span>", "Auction.gridAuction:2,[count]")
					src << output("<span class='content'>[a.item.desc]</span>",   "Auction.gridAuction:3,[count]")

					if(a.buyout)
						src << output("<span class='content'><a href=\"?src=\ref[a];action=buyoutAuction\">Buyout</a> [comma(a.buyoutPrice)]</span>", "Auction.gridAuction:4,[count]")
					else
						src << output(null, "Auction.gridAuction:4,[count]")

					if(a.bid)
						if(a.bidder == ckey)
							src << output("<span class='content'>You're at lead bidding [comma(a.minPrice)] gold. (Bids: [a.bid - 1])</span>", "Auction.gridAuction:5,[count]")
						else
							src << output("<span class='content'><a href=\"?src=\ref[a];action=bidAuction\">Bid</a> [comma(round(a.minPrice + (a.minPrice / 10), 1))] (Bids: [a.bid - 1])</span>", "Auction.gridAuction:5,[count]")
					else
						src << output(null, "Auction.gridAuction:5,[count]")

					var/days = round((2592000 - (world.realtime - a.time)) / 864000, 1)
					src << output("<span class='content'>[days] days remaining</span>", "Auction.gridAuction:6,[count]")

					if(a.owner == ckey)
						src << output("<span class='content'><a href=\"?src=\ref[a];action=removeAuction\">Remove</a></span>", "Auction.gridAuction:7,[count]")
					else
						src << output(null, "Auction.gridAuction:7,[count]")

				winset(src, null, "Auction.gridAuction.cells=7x[count]")

			if(count < 3)
				winset(src, null, "Auction.gridAuction.cells=7x2")

		auctionOpen()
			auctionInfo = new(src)

			src << output(null, "Auction.gridAuctionAddItem:1,1")
			src << output(null, "Auction.gridAuctionAddItem:2,1")

			winset(src, "Auction.gridAuction", "style='body{vertical-align:middle;text-align:center;background-color:#508cb4;color:#a8d8f0;}'")
			src << output("<b>Item</b>", "Auction.gridAuction:1,1")
			src << output("<b>Amount</b>", "Auction.gridAuction:2,1")
			src << output("<b>Description</b>", "Auction.gridAuction:3,1")
			src << output("<b>Buyout (Click Buyout to buy)</b>", "Auction.gridAuction:4,1")
			src << output("<b>Bid (Click Bid to bid)</b>", "Auction.gridAuction:5,1")
			src << output("<b>Time Remaining</b>", "Auction.gridAuction:6,1")
			src << output(null, "Auction.gridAuction:7,1")

			auctionBuild()

			winshow(src, "Auction", 1)

		auctionError(var/msg)

			winset(src, "Auction.labelError", "text=\"[msg]\"")


	verb
		auctionAdd()
			set name = ".auctionAdd"

			if(auctionInfo && auctionInfo.item)
				var/list/options = params2list(winget(src, "Auction.buttonBid;Auction.buttonBuyout;Auction.inputMinPrice;Auction.inputBuyoutPrice;Auction.button2Days;", "is-checked;text;"))

				var/bid         = options["Auction.buttonBid.is-checked"]    == "true"
				var/buyout      = options["Auction.buttonBuyout.is-checked"] == "true"

				if(bid + buyout == 0)
					auctionError("You to select either bid, buyout or both.")
					return

				var/minPrice
				var/buyoutPrice

				if(bid)
					minPrice    = text2num(options["Auction.inputMinPrice.text"])

					if(!minPrice || !isnum(minPrice) || minPrice < 0 || minPrice > 1000000000)
						auctionError("Invalid minimum price.")
						return
					minPrice = round(minPrice, 1)

				if(buyout)
					buyoutPrice = text2num(options["Auction.inputBuyoutPrice.text"])

					if(!buyoutPrice || !isnum(buyoutPrice) || buyoutPrice < 0 || buyoutPrice > 1000000000)
						auctionError("Invalid buyout price.")
						return
					buyoutPrice = round(buyoutPrice, 1)

				auctionInfo.bid         = bid
				auctionInfo.buyout      = buyout
				auctionInfo.minPrice    = minPrice
				auctionInfo.buyoutPrice = buyoutPrice
				auctionInfo.time        = world.realtime
				auctionInfo.owner       = ckey

				if(options["Auction.button2Days.is-checked"] == "true")
					auctionInfo.time -= 864000

				if(!worldData.auctionItems) worldData.auctionItems = list()

				worldData.auctionItems += auctionInfo

				auctionInfo = new(src)
				src << output(null, "Auction.gridAuctionAddItem:1,1")
				src << output(null, "Auction.gridAuctionAddItem:2,1")
				auctionError("")
				auctionBuild()

		auctionClosed()
			set name = ".auctionClosed"
			if(auctionInfo)
				if(auctionInfo.item)
					auctionInfo.item.Move(src)
					auctionInfo.item = null
					Resort_Stacking_Inv()

				auctionInfo = null


		auctionRefresh()
			set name = ".auctionRefresh"
			if(auctionInfo)
				auctionBuild()


obj/items
	var/canAuction = TRUE

	MouseDrop(over_object,src_location,over_location,src_control,over_control,params)
		.=..()
		var/mob/Player/P = usr
		if((src in usr) && P.auctionInfo)
			if(over_control == "Auction.gridAuctionAddItem" && src != P.auctionInfo.item)
				if(dropable && canAuction)

					if(P.auctionInfo.item)
						P.auctionInfo.item.Move(P)

					if(stack <= 1 && (src in usr:Lwearing))
						src:Equip(usr)
					else if(istype(src, /obj/items/lamps) && src:S)
						var/obj/items/lamps/lamp = src
						lamp.S.Deactivate()

					Unmacro(P)

					var/obj/items/i
					if(stack > 1)
						var/s = P.split(src)
						if(!P || !s || !P.auctionInfo) return
						i = Split(s)
					else
						i = src

				//	var/obj/items/i = stack > 1 ? Split(1) : src

					if("ckeyowner" in i.vars)
						src:ckeyowner = null
					P << output(i, "Auction.gridAuctionAddItem:1,1")
					P << output("<b class='item'>x[i.stack]</b>", "Auction.gridAuctionAddItem:2,1")
					P.auctionInfo.item = i
					P.contents -= i
					P.Resort_Stacking_Inv()
				else
					P << errormsg("This item can't be used in auction.")

	Click(location,control,params)
		var/mob/Player/P = usr
		if(P.auctionInfo && P.auctionInfo.item == src)
			P << output(null, "Auction.gridAuctionAddItem:1,1")
			P << output(null, "Auction.gridAuctionAddItem:2,1")
			P.auctionInfo.item = null
			Move(P)
			P.Resort_Stacking_Inv()
		else
			..()
