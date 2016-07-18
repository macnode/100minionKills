#!/bin/bash

clear

########################################
####  the100.io Minion Kills v2.6   ####
#### Scrapes member list from group ####
####  Calls Bungie API to get grim  ####
#### 	  the100:  /u/L0r3          ####
####      Reddit:  /u/L0r3_Titan    ####
####      Twitter: @L0r3_Titan      ####
########################################

#### ENEMY ARRAY ####
grimCard="\
201090,Acolyte \
207100,Captain \
205150,Centurion \
205140,Colossus \
601076,Crota \
207130,Dreg \
203120,Goblin \
203150,Harpy \
203130,Hobgoblin \
203160,Hydra \
201110,Knight \
205120,Legionary \
201140,Ogre \
205130,Phalanx \
201130,Thrall \
203140,Minotaur \
207140,Servitor \
207150,Shank \
205110,Psion \
207120,Vandal \
201120,Wizard \
205010,TheCabal \
207010,TheFallen \
201010,TheHive \
203010,TheVex"

# 2016-06-21 Shank
# 2016-06-28 Servitor
# 2016-07-06 Vandal
# 2016-07-11 Thrall

#701180,TheTaken (different processor needed to extract grim)

#### READ grimCard INTO ARRAY VARIABLE, COUNT # OF OBJECTS IN ARRAY, PICK RANDOM ####
IFS=' '
grimObject=($grimCard)
grimCardCount=${#grimObject[*]}
currentCard=`echo ${grimObject[$((RANDOM%grimCardCount))]}`

#### MANUAL OVERRIDE IF YOU WANT TO PROCESS SPECIFIC ENEMY ####
currentCard='201130,Thrall'

#### INCLUDE FILE WITH YOUR BUNGIE API KEY ####
source ${BASH_SOURCE[0]/%minionKills.sh/apiKey.sh}
source ${BASH_SOURCE[0]/%minionKills.sh/hundredMembers.sh}

#### SEPRATE GRIM CARD ID AND NAME ####
grimID=`echo $currentCard | sed 's/,.*[^,]*//'`
grimName=`echo $currentCard | rev | sed 's/,.*[^,]*//' | rev`

#### CALL FUNCTION TO SCRAPE THE100 MEMBERS ####
hundredMembers

#### XBOX OR PSN ####
selectedAccountType='1'

#### SOURCE OF USERS TO PROCESS (this is produced by scraper) ####
playerList="/tmp/100_usersClean.txt"

#### FUNCTION TO SEND USERNAME TO BUNGIE TO GET MEMBER ID ####
funcMemID ()
{
sleep 1
getUser=`curl -s -X GET \
-H "Content-Type: application/json" -H "Accept: application/xml" -H "$authKey" \
"https://www.bungie.net/Platform/Destiny/SearchDestinyPlayer/$selectedAccountType/$player/"`
memID=`echo "$getUser" | grep -o 'membershipId.*' | cut -c 16- | sed 's/displayName.*[^displayName]*//' | rev | cut -c 4- | rev`
}

#### FUNCTION TO GET ALL THE DATA FROM A SPECIFIC GRIM CARD ("statNumber":1)  ####
funcGetGrimData ()
{
sleep 1
grimMinion=`curl -s -X GET \
-H "Content-Type: application/json" -H "Accept: application/xml" -H "$authKey" \
"https://www.bungie.net/Platform/Destiny/Vanguard/Grimoire/1/$memID/?single=$grimID"`
grimStatOne=`echo "$grimMinion" | grep -o 'statNumber":1.*' | sed 's/displayValue.*[^displayValue]*//' | rev | cut -c 5- | sed 's/eulav.*[^eulav]*//' | rev | cut -c 3-`
}

#### LOOP THOUGH LIST OF MEMBERS, RUN FUNCTIONS TO GET BUNGIE GRIM DATA ####
let groupKills='0'
let playerCnt='0'
while read 'player'; do
	funcMemID
	funcGetGrimData
	let groupKills=groupKills+$grimStatOne
	echo "$player: $grimStatOne $grimName kills (group $the100group: $groupKills)"
	let playerCnt=playerCnt+1
	grimArr[$playerCnt]="$grimStatOne,$player"
done < "$playerList"

#### SORT SCORES HIGHEST TO LOWEST ####
function arrSort 
{ for i in ${grimArr[@]}; do echo "$i"; done | sort -n -r -s ; }
echo
grimScoresSort=( $(arrSort) )
printf '%s\n' "${grimScoresSort[@]}"

echo
echo "Group $the100group: $groupKills $grimName kills"
echo

exit
