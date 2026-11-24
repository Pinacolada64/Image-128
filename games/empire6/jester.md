# Empire 6: the court jester

A plan for the TODO item "a court jester" (user, 11/24/2026). Not
written yet.

## What the jester does

- **Hired at the court** (the town), for a yearly wage like the court
  wizard's; dismissed there too. One at a time, with a name dealt from the
  pool below ("Pip the Motley").
- **A joke at the start of each turn**, picked at random from the jokes
  file: the setup, a pause (`{pound}w1`), then the punchline. A good
  joke cheers the court: a little less unrest among the serfs and nobles
  that year.
- **Cheeky jokes** poke fun at the ruler (marked below). Usually they
  land; sometimes the ruler is offended: the game asks "Off with the
  fool's head?", and dismissing or jailing the jester costs the court's good
  mood, while laughing it off wins the nobles' loyalty.
- **At banquets and festivals** (their items) the jester entertains the
  guests: extra courtship points with a suitor who attends (the suitors
  item), or, now and then, a joke that offends a visiting envoy (the
  alliances item: talks set back).
- **Gossip**: jesters hear everything. Now and then the jester whispers
  a rumour about another ruler, a hint of their stats, true or not (the
  spies item, cheaply and unreliably).
- **The jokes file**: a file the sysop can add to, like Image's sayings
  (`e.say`, a REL file edited with `i/SM.sayedit`): `e.emp6.jokes`,
  each joke a setup line and a punchline line, each at most 39
  characters, and a flag for the cheeky ones. Callers could suggest
  jokes too, for the sysop to approve; across the network (that item),
  boards could trade them.

## Jesters' names

Pip the Motley, Tobias Bells, Hob Merriwether, Jolly Jack Thimble,
Fennick the Fool, Wat Tumbletoes, Lark o' the Lute, Motley Meg,
Rollo Ruffle, Patch, Kit Capering, Nell Jinglecap

## The jokes

Twenty to start the file with, for 40 columns: a setup, then a
punchline. Six are cheeky (they tease the ruler).

1. Which knight built the Round Table?  
   Sir Cumference.
2. What do you call a knight who flees?  
   Sir Render.
3. Why did the miller retire?  
   He was tired of the daily grind.
4. Why was the archer sent home?  
   He kept missing the point.
5. Why did the soldier sleep in the mill?  
   He wanted to be well-bread.
6. What's a king's favourite weather?  
   Reign, of course.
7. Why did the tax man bring a ladder? (cheeky)  
   To reach the higher rates.
8. How many serfs to light a candle, sire? (cheeky)  
   None. You taxed the candles.
9. Knock knock. Who's there? Tax.  
   Tax who? Tax-actly what you owe!
10. Why won't the dragon raid our castle?  
   It tasted the cook's stew once.
11. Our army is so small, sire... (cheeky)  
   ...they counted it twice to be polite.
12. Why is our grain so safe, my liege? (cheeky)  
   Even the rats won't eat it.
13. Why did the foundry close?  
   It couldn't stand the heat.
14. What did the wall say to the catapult?  
   "Stop throwing yourself at me!"
15. I asked the wizard to make me rich.  
   Now I'm a very rich toad. Ribbit.
16. Why do sailors make bad courtiers?  
   Every compliment goes overboard.
17. What does a noble do with his gold? (cheeky)  
   Counts it. Then counts it again.
18. Why did the horse join the cavalry?  
   It heard the pay was stable.
19. Why are diplomats such poor cooks?  
   They let everything simmer for years.
20. Our palace is so grand, my lord... (cheeky)  
   ...even the debts have their own wing.
