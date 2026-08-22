# FromZoid — Night People Voice Commission

For **ElevenLabs** generation, then **Higgsfield MCP** (or drop `.ogg` into the mod).  
Project: FromZoid (Project Zomboid Build 42.20).  
Tone: isolated town, people at the door after dark. They look human. They are not.

Do **not** copy TV-show scripts or copyrighted song lyrics. All lines below are original.

---

## Deliverables

| Voice (ElevenLabs name) | Gender | Count | Filename prefix |
| --- | --- | --- | --- |
| **Vlad** | male | 24 | `FromZoid_Vlad_01` … `24` |
| **Miles** | male | 24 | `FromZoid_Miles_01` … `24` |
| **Knox** | male | 24 | `FromZoid_Knox_01` … `24` |
| **Roxie** | female | 24 | `FromZoid_Roxie_01` … `24` |
| **Annie** | female | 24 | `FromZoid_Annie_01` … `24` |
| **Zelda** | female | 24 | `FromZoid_Zelda_01` … `24` |

**144 clips total.** One line per file. Do not batch two lines into one take.

### Audio spec (Project Zomboid)

- Container: **Ogg Vorbis** (`.ogg`)
- Mono, **44.1 kHz**, quality ~q5–q6
- Peak around **-3 dB**, no brickwall limiter pumping
- Leave **80–150 ms** silence at head and tail
- No music bed, no reverb longer than a small porch (short room is OK)
- Spoken (or sung, Miles only) at **conversation distance**, as if through a closed door / window

Place finished files in:

```
Contents/mods/FromZoid/common/media/sound/
```

Example: `FromZoid_Vlad_01.ogg`

The Lua hook will call `getEmitter():playSound("FromZoid_Vlad_01")` (name without path). If a sound script is required, use the same id as the filename stem.

### In-game assignment (for the coder, not the voice session)

- Male zombies: Vlad, Miles, or Knox
- Female zombies: Roxie, Annie, or Zelda
- **Knox only plays when the speaker is at a window** (not a door). Record him as if he can see through glass.
- Night only (and optional darkness events)

---

## Higgsfield / ElevenLabs session notes

Use the **named ElevenLabs voice** as the identity. One voice per batch. Do not mix voices in a take.

Suggested generation settings (adjust per voice):

- Stability: medium-high for Knox; lower for Zelda and Miles
- Style exaggeration: low for Annie; medium for Roxie/Vlad; higher for Miles
- Do not add a second speaker or crowd

### Batch prompt template (paste once per voice)

```
You are recording isolated night-time lines for a horror game. One take per numbered line.
The speaker is standing outside a locked house, talking to someone they know is inside.
No intro, no take numbers spoken, no “line 1”. Just the line.
Stay in character for the whole batch. Match the delivery notes for this voice.
If a line is marked SUNG, sing it; otherwise speak it.
Keep each clip under 8 seconds unless the line is a chorus (Miles sung lines may go to 12 seconds).
```

Then paste that voice’s **Delivery** paragraph and the numbered list.

---

## Vlad — eastern European drunk “vampire”

**ElevenLabs:** Vlad  
**Who:** Older man, thick Eastern European accent, wet smile, vodka on the breath. Think courtly manners that keep slipping. He believes he is being reasonable.  
**Delivery:** Close to the door. Slightly too loud, then a hush. Occasional chuckle. Never cartoon Dracula; drunk neighbor who might bite.  
**Reference vibe (do not record this exact line as #00):** “Let me in, I have vodka.”

| # | Line | Note |
| --- | --- | --- |
| 01 | Let me in, I have vodka. | Warm, generous, already unscrewing a cap |
| 02 | Come. We drink. Then we talk. | Bargain |
| 03 | Is cold like grave out here, friend. | Soft laugh after |
| 04 | I brought the good bottle. Not the cheap one. | Offended you might doubt him |
| 05 | Open a little. I pour through the crack. | Practical, slurred |
| 06 | You leave me with the night? This is rude. | Hurt pride |
| 07 | I am not stranger. I am thirsty gentleman. | Mock bow in the voice |
| 08 | The sun is dead. Now we live properly. | Sudden clarity, then fog |
| 09 | One glass. You will sleep like baby. | Too sincere |
| 10 | I can smell your heat through the wood. | Quiet, hungry |
| 11 | Do not make me wait. Waiting makes me… impolite. | Smile that is not a smile |
| 12 | I had house once. Nice house. Then morning came. | Bitter, almost sober |
| 13 | Please. My hands are shaking. | Pity play |
| 14 | You think the door is your friend. Door is just wood. | Lecturing |
| 15 | I will not break it. I have manners. Open it. | Pride |
| 16 | Share the dark with me. Is not so lonely. | Soft |
| 17 | I left my coat in another year. Let me in. | Confused drunk |
| 18 | Listen. No footsteps but mine. Safe. Safe. | Lying badly |
| 19 | You are kind person. Kind persons open doors. | Coaxing |
| 20 | If you do not open, I sit here until you rot. | Still cheerful |
| 21 | Vodka first. Blood later. Joke. Joke. | Too long a pause after “blood” |
| 22 | My village taught me: guest who knocks is guest. | Old-world |
| 23 | I see the candle. Put it out. Come to the latch. | Intimate |
| 24 | Open, little host. I brought enough for two throats. | Last of the bottle, last of the mask |

---

## Miles — joker / carnival butcher (sung choruses)

**ElevenLabs:** Miles  
**Who:** Showman. He is having a wonderful time. The joke is you.  
**Delivery:** Spoken lines are patter, grin in the voice. Lines marked **SUNG** are a nasty children’s-rhyme / carnival barker chorus — original verses only, same vicious sing-song as a piggy-pie butcher song, **not** that copyrighted lyric. Clap or stamp once is OK; no instruments.  
**Do not record** any real song chorus.

| # | Line | Note |
| --- | --- | --- |
| 01 | Knock knock, little house. Guess who brought the dessert. | Spoken, delighted |
| 02 | SUNG: Stir the pot and count to ten / lock the latch and do it again / I know a secret, you know it too / the night came early just for you. | Upbeat, cruel |
| 03 | Come on. The show’s no fun with the curtain shut. | Pouting |
| 04 | I can hear you holding your breath. That’s adorable. | Whisper then laugh |
| 05 | SUNG: Two little shutters, one little hall / three little heartbeats hiding from it all / I brought a smile, I brought a knife / open up, sugar, and get a life. | Bright |
| 06 | Don’t be shy. Shy meat goes tough. | Kitchen-friendly |
| 07 | I wrote you a song. It’s very short. It ends when you scream. | Proud |
| 08 | SUNG: Round we go around the block / tick tock tick, don’t watch the clock / if you’re in there, I’m out here / that’s the whole joke, my dear. | Skipping-rope |
| 09 | Peek through the keyhole. I already am. | Soft |
| 10 | You missed the parade. I brought it to your porch. | Grand |
| 11 | SUNG: Hush little house don’t you cry / if you don’t open I know why / I’ll wait, I’ll wait, I’ll wait some more / there’s always a hinge, there’s always a door. | Lullaby gone wrong |
| 12 | Bravo for the boards. Encore for the screaming. | Applause in the voice |
| 13 | I don’t need a ticket. You are the ticket. | Fast |
| 14 | SUNG: Knives in the drawer, pies in the sky / everybody’s hungry by and by / clap your hands, stamp your feet / the night is sweet, the night is sweet. | Crowd-work, no crowd |
| 15 | Say something. I’ll turn it into a punchline. | Eager |
| 16 | Your lights are cheating. Cheaters get a private show. | Mock-offended |
| 17 | SUNG: One for the window, two for the floor / three for the one who won’t open the door / four for the morning that never comes back / five for the laugh in the pitch-black. | Counting game |
| 18 | I’m not mad. I’m booked solid. You’re tonight. | Booking agent |
| 19 | Open up. I left my manners in the funhouse. | Giggle |
| 20 | SUNG: Dance on the porch till the boards complain / rattle the glass, remember my name / Miles at your service, Miles at your throat / that’s the last verse, that’s all she wrote. | Bow at the end |
| 21 | If you stay quiet I get louder. That’s the rule. | Helpful |
| 22 | I brought no flowers. I brought an appetite. | Charming |
| 23 | SUNG: Hide little rabbit, hide little mouse / I know every corner of this little house / when the chorus hits, you better sing / or I’ll finish the number without you in. | Crescendo |
| 24 | Last call for volunteers. That’s you. That’s always you. | Soft, close to the wood |

---

## Knox — Englishman, window only

**ElevenLabs:** Knox  
**Who:** Precise, educated, furious that you will not behave. He is looking **through glass**. He does not beg at the door; he sentences you from the window.  
**Delivery:** Received Pronunciation, clipped. No drunk. Threats like a lecture. Quiet until the last word lands.  
**Reference vibe:** “I will feed you your spleen, you uncivilized swine.”

| # | Line | Note |
| --- | --- | --- |
| 01 | I will feed you your spleen, you uncivilized swine. | Calm, then the insult |
| 02 | I can see you. Do not insult me by crouching. | Through glass |
| 03 | Draw the curtain if you like. I already have your measure. | Bored |
| 04 | This window is a disappointing fortress. | Academic |
| 05 | Come to the glass. I want you to watch your own decision. | Soft command |
| 06 | You are not clever. You are merely indoors. | Dry |
| 07 | I shall have the fingers that hold that latch. | Inventory |
| 08 | Hide under the sill. Animals do that. | Disgust |
| 09 | When this pane goes, so do your pretenses. | Matter-of-fact |
| 10 | I have all night. You have a bladder and a pulse. | Almost kind |
| 11 | Look at me. Cowards die with their eyes shut anyway. | |
| 12 | Your breathing fogs the glass. Charming. Loud. | Observational |
| 13 | I will unmake you in the order you were assembled. | Surgical |
| 14 | Do not wave. I am not your neighbor. | Sharp |
| 15 | That board will not save the meat behind it. | Practical |
| 16 | Step closer. I want the satisfaction of your face. | |
| 17 | You will open, or you will be opened. Grammar, not mercy. | Pedant |
| 18 | I can wait until your candle dies. I enjoy the dark. | |
| 19 | Speak up. I dislike mumbling through windows. | Irritated |
| 20 | I will take the tongue that will not answer. | Quiet |
| 21 | Civilization ends at your threshold. I am here to collect it. | |
| 22 | Keep staring. I am patient with slow livestock. | |
| 23 | If you sleep, I will still be in the glass. | Promise |
| 24 | Good night. Try not to dream of the morning. There isn’t one. | Almost polite |

---

## Roxie — seductive, succubus-sweet

**ElevenLabs:** Roxie  
**Who:** Warm, pretty, a little too close to the door. Compliments first, hunger second. She wants in to “warm up.”  
**Delivery:** Low, intimate, smiling. Never cartoon villain until a tiny slip. Breath on the last word.  
**Reference vibe:** “Come on, let me in. Let’s warm up together.”

| # | Line | Note |
| --- | --- | --- |
| 01 | Come on, let me in. Let’s warm up together. | Soft laugh |
| 02 | You sound tired. I could fix that. | Caring |
| 03 | I saw your light. It looks good on you. | Flatter |
| 04 | Just the latch. I’m freezing in this dress. | Small shiver |
| 05 | You don’t have to be brave. You just have to open. | |
| 06 | I bet you’re kinder than you think. Kind men open doors. | Gender-neutral: “kind people” if needed — keep as written; PZ is unisex player |
| 07 | Let me in. I’ll keep you company till the sun… whenever. | Skip the sun |
| 08 | Your house smells like safety. I miss that. | Vulnerable |
| 09 | Don’t leave me with the quiet. The quiet bites. | |
| 10 | I could whisper you to sleep. Inside. | Promise |
| 11 | You’re shaking. I can hear it. Come here. | |
| 12 | One minute. One door. Then you can decide I’m a mistake. | Bargain |
| 13 | I brought nothing but me. That’s the generous version. | Smile |
| 14 | Unlock it. I’ll do the rest slowly. | |
| 15 | You kept this place so nice. Let me see it. | Tour |
| 16 | I’m not like the knocking. I’m like a guest. | |
| 17 | Please. My teeth are chattering. That’s all. | Lie |
| 18 | If you open, I promise I won’t scream. You might. | Soft joke |
| 19 | Stay by the door. I want your voice closer. | |
| 20 | Warm room, warm hands, warm… everything. Come on. | |
| 21 | You’re allowed to want this. I already do. | |
| 22 | The night is long. We could make it shorter. | |
| 23 | I can be so sweet if you let me past the wood. | |
| 24 | Open up, honey. I’ll be gentle until I’m not. | Last word colder |

Line 06 note for recording: if the take feels gendered-wrong, use: “Kind people open doors.”

---

## Annie — lost girl

**ElevenLabs:** Annie  
**Who:** Young, not cartoon-tiny, scared, trying to be polite. She is looking for her parents. The sweetness should hurt.  
**Delivery:** Small, clear, close to tears but not sobbing every line. Occasional hope. Never adult irony.  
**Reference vibe:** “Have you seen my parents?”

| # | Line | Note |
| --- | --- | --- |
| 01 | Have you seen my parents? | Hopeful |
| 02 | I’m not supposed to be out after dark. | Confession |
| 03 | Please. I can’t find our house. This one looks like it. | |
| 04 | Mom said knock and wait. I waited. | Small break |
| 05 | I’m cold. Can I stand inside just until they come? | |
| 06 | I won’t touch anything. I promise. | Fast |
| 07 | There were people in the street. They smiled too wide. | Quiet |
| 08 | If you’re hiding, I can hide too. I’m good at it. | |
| 09 | Please don’t leave me on the porch. | |
| 10 | I have a key. It doesn’t work. Maybe yours does. | Confused |
| 11 | Dad always opens when I count to three. One… two… | Stop before three |
| 12 | I’m not a stranger. I’m Annie. They’ll tell you. | |
| 13 | The night keeps moving. I need a still room. | |
| 14 | Can you call them? I forgot the number. | |
| 15 | I’ll sit by the door. You won’t even see me. | Bargain |
| 16 | Something scratched the other house. This one still looks safe. | |
| 17 | I’m hungry. I won’t eat much. | Too honest |
| 18 | If you see a woman in a blue coat, that’s Mom. Tell her I’m here. | |
| 19 | Please. My flashlight died. | |
| 20 | I heard you walking. Living people walk like that. | Relief |
| 21 | I don’t like the singing man. Let me in before he comes back. | |
| 22 | I can sleep on the floor. I brought my own quiet. | |
| 23 | Open a little. I’ll squeeze. I’m little. | |
| 24 | If you don’t open, I’ll still wait. That’s what good girls do. | Wrong lesson |

---

## Zelda — riddles / nonsense

**ElevenLabs:** Zelda  
**Who:** Girl-voiced, not quite a child, not quite right. Nursery logic with the wiring pulled out. Sweet, then sideways.  
**Delivery:** Playful, sing-song on questions. Pause in odd places. Never explain the joke.  
**Reference vibe:** “Knock knock. Who’s there?” / “It smells nice in there. Are you cooking a pie?”

| # | Line | Note |
| --- | --- | --- |
| 01 | Knock knock. Who’s there? | Wait as if they answered |
| 02 | It smells nice in there. Are you cooking a pie? | Innocent |
| 03 | If a house has a mouth, should it chew or smile? | |
| 04 | I brought a secret. It doesn’t fit under the door. | |
| 05 | Three knocks for luck. Four knocks for later. I did five. | Giggle |
| 06 | What’s black and white and red all over the porch? | No punchline |
| 07 | Let me in and I’ll tell you how windows get teeth. | Soft |
| 08 | The moon is a key. You are a lock. I am tired of metaphors. | Sudden flat |
| 09 | Knock knock. It’s me. It’s also not. | |
| 10 | Are you counting sheep or counting doors? | |
| 11 | I lost my shadow. Can I borrow yours till morning? | |
| 12 | Hot pie, cold hands, open latch, understand? | Rhyme |
| 13 | If I say please twice, does the wood get kinder? | |
| 14 | Someone’s cooking. Someone’s breathing. Someone’s lying. | Three beats |
| 15 | Knock knock. House. House who? That’s the whole name. | |
| 16 | I’ll trade you a riddle for a hinge. | |
| 17 | Why did the girl wait all night? To see if you were real. | |
| 18 | Sugar on the sill. Salt on the step. You in the middle. | Recipe |
| 19 | Open up and I’ll stop asking who. | |
| 20 | The pie is a trick. The knock is a trick. I’m the leftover. | |
| 21 | Knock knock. Guess. No, don’t guess. Open. | |
| 22 | If you dream about me, leave the door unlocked. Fair? | |
| 23 | I know a song with no words. The chorus is your heartbeat. | |
| 24 | Knock knock. Who’s there? Zelda. Zelda who? Zelda in. | Small laugh |

---

## Recording order (suggested)

1. Annie (clearest, sets “human at the door”)
2. Roxie
3. Vlad
4. Knox (window distance: a bit more air than the others)
5. Zelda
6. Miles last (sung takes; voice may tire)

Record numbered lists in order. If a take fails, keep the same number; do not skip.

## QC checklist

- [ ] 24 files per voice, names match the table
- [ ] Miles sung lines are original (no real song lyrics)
- [ ] Knox sounds like he is at glass, not kissing the door
- [ ] No take slates (“line seven”) in the audio
- [ ] Clips play in-game without clipping when the player is 4–8 tiles inside a house

## Higgsfield follow-up

After ElevenLabs (or Higgsfield TTS) exports WAV:

1. Convert to mono `.ogg`
2. Normalize
3. Drop into `common/media/sound/`
4. Tell the FromZoid Lua pass to register `sound` scripts if 42.20 requires them for `playSound`

Do not generate video. Audio only.
