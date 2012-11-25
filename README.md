::FireFall IRC::
====================

An ingame IRC client for FireFall.

More info in this thread here :) http://www.firefallthegame.com/community/threads/addon-ingame-irc.65422/

###::FireFall Addon::
====================

###::Relay Server::
====================
###Dependencies:
The relay server is written for Node.js so it has a few dependacy that you will need to install. Thank fully it shouldn't hurt too badly :P
* 	Node.js.
* 	Socket.io.
* 	node-irc 

###Installation:
Use one of these metiods to install Node.js and npm: https://gist.github.com/579814

Then just navagate to the directory where you want to locate the server and run this script curl https://raw.github.com/ArkyChan/FireFall-IRC/master/IRCRelay/get.sh | sh
That script should install the dependacys and grab the latest version of the server, now you jsut have to lauch the server.

Like so:
node app.js 8181

8181 is the port, change to your liken.

Annnd done :)
