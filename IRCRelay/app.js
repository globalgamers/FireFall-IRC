var app = require('http').createServer(handler)
  , io = require('socket.io').listen(app, { log: false })
  , fs = require('fs');
  
 var irc = require('irc');
 
 var port = 80;
 if (process.argv[2])
	port = process.argv[2];
 
console.log("==================================================");
console.log("--       FireFall IRC Relay Server        Arkii --");
console.log("==================================================");
console.log("Server Started Listening on port: " + port + " Nao :D");

app.listen(port);

//==================================================
// HTTP Requests
//==================================================
function handler (req, res) 
{
  fs.readFile(__dirname + '/irc.html',
  function (err, data) 
  {
    if (err) {
      res.writeHead(500);
      return res.end('Error test.html');
    }

    res.writeHead(200);
    res.end(data);
  });
}

var activeConnections = 0;
//==================================================
// Web Sockets
//==================================================
io.sockets.on('connection', function (socket) 
{
	  console.log("Client Connected");
	  activeConnections++;
	  console.log("Connected Clients: " + activeConnections);
	  
	  var ircClient = false;
	  var channel;
	  
	  // Connect to a channel in a server with the given nick
	  socket.on('ircConnect', function (data) 
	  {
		if (ircClient != false)
			ircClient.disconnect("cya ^^");
			
		ircClient = IRC_Connect(socket, data.host, data.chan, data.nick);
			
		channel = data.chan;
	  });
	  
	  // Send a message to the irc server
	  socket.on('say', function (data) 
	  {
		if (ircClient)
		{
			var msg = new String(data);
			var cmdEnd = msg.indexOf(" ");
			if (cmdEnd == -1)
			{
				cmdEnd = msg.length;
			}
			var command = msg.substr(0, cmdEnd);
			msg = msg.substr(msg.indexOf(" ")+1, msg.length);
			
			if (command == "/me")
				ircClient.action(channel, msg);
			else if (command == "/names")
			{
				ircClient.send("NAMES", channel);
				console.log(msg);
			}
			else
				ircClient.say(channel, data);
		}
	  });
	  
	  // Send a raw command to the irc server
	  socket.on('ircRaw', function (data) 
	  {
		
	  });
	  
	  // Disconnect
	  socket.on('disconnect', function (data) 
	  {
		console.log("Client Disonnected");
		activeConnections--;
		console.log("Connected Clients: " + activeConnections);
	  
		if (ircClient)
			ircClient.disconnect("cya ^^");
	  });
	  
	  socket.on('ircDisconnect', function (data) 
	  {
		if (ircClient)
			ircClient.disconnect("cya ^^");
	  });
	  
	  // Leave the channel
	  socket.on('part', function (data) 
	  {
		if (ircClient)
			ircClient.part(channel);
	  });
  
});

//==================================================
// IRC Client
//==================================================
function IRC_Connect(socket, host, chan, user)
{
	var client = new irc.Client(host, user, {channels: [chan], userName: 'FireFallIRC', realName: 'FireFall ingame IRC',autoRejoin: true, floodProtection: true, floodProtectionDelay: 1000,});
	
	// A new message in the channel
	client.addListener('message', 
	function (from, to, message) 
	{
		socket.emit('onMessage', {"from": from, "to": to, "msg": message});
	});
	
	client.addListener('pm', 
	function (nick, text, message) 
	{
		socket.emit('onPM', {"nick": from, "text": text, "msg": message});
	});
	
	client.addListener('names', 
	function (channel, nicks) 
	{
		socket.emit('onNames', {"channel": channel, "nicks": nicks});
	});
	
	client.addListener('nick', 
	function (oldnick, newnick, channels, message) 
	{
		socket.emit('onNick', {"oldnick": oldnick, "newnick": newnick, "channel": channels});
	});
	
	/*client.addListener('raw', 
	function (message) 
	{
		console.log("Raw Message");
		console.log(message);
	});*/
	
	client.addListener('ctcp-privmsg', 
	function (from, to, text) 
	{
		console.log(text.substr(0, 6)+"|");
		if (text.indexOf("ACTION") > -1)
		{
			socket.emit('onMEAction', {"nick": from, "text": text.substr(7, text.length)});
			console.log(text.substr(7, text.length));
		}
	});
	
	// New topic
	client.addListener('topic', 
	function (channel, topic, nick, message) 
	{
		socket.emit('onTopic', {"channel": channel, "topic": topic, "nick": nick});
	});
	
	// A user has joined :D big dango family
	client.addListener('join'+chan, 
	function (nick, message) 
	{
		socket.emit('onJoin', {"nick": nick, "msg": message});
	});
	
	// Aww some one left ;(
	client.addListener('part', 
	function (channel, nick, reason, message) 
	{
		socket.emit('onPart', {"channel": channel, "nick": nick, "reason": reason, "message": message});
	});
	
	// Oh noes an error D:
	client.addListener('error', 
	function(message) 
	{
		console.log('IRC Error: ', message);
	});
	
	return client;
}