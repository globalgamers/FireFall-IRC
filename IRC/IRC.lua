--==============================================================================================
-- Arkii
-- A simple IRC client, well simple for now, MUHaHaha...
-- It's not so cold now so I didn't have to wear mittens :>
--==============================================================================================

require "string";
require "table";
require "lib/lib_Slash";
require "./lib/ui";

--=====================
--		Constants    --
--=====================
local ADDONNAME = "IRC";
local WEBFRAME = Component.GetFrame("web");
local FRAME = Component.GetFrame("Main");

local LINEHEIGHT = 18;
local WINDOWWIDTH = 390;
local WINDOWHEIGTH = 244;

--=====================
--		Varables     --
--=====================
local slashy = {};
local maXChatLines = 1;
local chatLines = {};

local ircServer = "irc.freenode.net";
local ircChan = "#yayifications";
local ircNick = "";
local ircAutoJoin = true;

local primaryRelay = "176.31.170.161:8181";
local secondaryRelay = "ffirc.eu01.aws.af.cm";
local activeIRCRelay = "";

local ircChatmsgColor = "#5CFFFF";
local ircServermsgColor = "#A42FFF";
local ircClientmsgColor = "#0EFF9C";
local ircMsgBgColor = "#000000";
local ircMsgBgAlpha = 0.5;

local ircMsgFadeTime = 15;

--=====================
--		   UI        --
--=====================
require "lib/lib_InterfaceOptions"
InterfaceOptions.AddMovableFrame({
	frame = FRAME,
	label = "IRC Chat",
	scalable = true,
})

-- Chan prefs
InterfaceOptions.StartGroup({label="Channel Preferences", checkbox=true, id="Channel Preferences", default=true});

InterfaceOptions.AddTextInput({id="IRCSERVER", label="Default IRC Server:", default=ircServer, maxlen=128, whitespace=false});
UIHELPER.AddUICallback("IRCSERVER", function(args) ircServer = args; end);

InterfaceOptions.AddTextInput({id="IRCCHANNEL", label="Default IRC Channel:", default=ircChan, maxlen=128});
UIHELPER.AddUICallback("IRCCHANNEL", function(args) ircChan = args; end);

InterfaceOptions.AddTextInput({id="IRCNICK", label="Default IRC Nick:", default=ircNick, maxlen=128});
UIHELPER.AddUICallback("IRCNICK", function(args) ircNick = args; end);

InterfaceOptions.AddCheckBox({id="IRCAUTOJOIN", label="Auto Join Channel:", tooltip="If checked you will automaticly connect to the given irce server and channel. Can spam Connect/disconnects if you relaod the ui :/", default=ircAutoJoin});
UIHELPER.AddUICallback("IRCAUTOJOIN", function(args) ircAutoJoin = args; end);

InterfaceOptions.StopGroup();

-- Style
InterfaceOptions.StartGroup({label="Style", checkbox=true, id="Style", default=true});

InterfaceOptions.AddSlider({id="IRCWINDOWWIDTH", label="IRC Chat Window width:", default=WINDOWWIDTH, min=150, max=700, inc=1});
UIHELPER.AddUICallback("IRCWINDOWWIDTH", function(args) WINDOWWIDTH = args; UpdateWindowSize(); end);

InterfaceOptions.AddSlider({id="IRCWINDOWHEIGHT", label="IRC Chat Window height:", default=WINDOWHEIGTH, min=150, max=700, inc=1});
UIHELPER.AddUICallback("IRCWINDOWHEIGHT", function(args) WINDOWHEIGTH = args; UpdateWindowSize(); end);

InterfaceOptions.AddColorPicker({id="IRCCHATMSGCOLOR", label="Chat message Color:", default={alpha=1, tint=ircChatmsgColor}});
UIHELPER.AddUICallback("IRCCHATMSGCOLOR", function(args) ircChatmsgColor = args.tint; end);

InterfaceOptions.AddColorPicker({id="IRCSERVERMSGCOLOR", label="Server message Color:", default={alpha=1, tint=ircServermsgColor}});
UIHELPER.AddUICallback("IRCSERVERMSGCOLOR", function(args) ircServermsgColor = args.tint; end);

InterfaceOptions.AddColorPicker({id="IRCCLIENTMSGCOLOR", label="Client message Color:", default={alpha=1, tint=ircClientmsgColor}});
UIHELPER.AddUICallback("IRCCLIENTMSGCOLOR", function(args) ircClientmsgColor = args.tint; end);

InterfaceOptions.AddColorPicker({id="IRCMSGBGCOLOR", label="Message background color:", default={alpha=1, tint=ircMsgBgColor}});
UIHELPER.AddUICallback("IRCMSGBGCOLOR", function(args) ircMsgBgColor = args.tint; end);

InterfaceOptions.AddSlider({id="IRCMSGBGALPHA", label="Message background alpha:", default=ircMsgBgAlpha, min=0.1, max=1.0, inc=0.1, multi=100});
UIHELPER.AddUICallback("IRCMSGBGALPHA", function(args) ircMsgBgAlpha = args; end);

InterfaceOptions.AddSlider({id="IRCMSGFADE", label="Time to message fade:", default=ircMsgFadeTime, min=1, max=60, inc=1});
UIHELPER.AddUICallback("IRCMSGFADE", function(args) ircMsgFadeTime = args; end);

InterfaceOptions.StopGroup();

-- Relay Servers
InterfaceOptions.StartGroup({label="Relay Servers", checkbox=true, id="Relay Servers", default=true});

InterfaceOptions.AddTextInput({id="IRCRELAY1", label="Primary IRC Relay Server:", default=primaryRelay, maxlen=128, whitespace=false});
UIHELPER.AddUICallback("IRCRELAY1", function(args) primaryRelay = args; end);

InterfaceOptions.AddTextInput({id="IRCRELAY2", label="Secondary IRC Relay Server:", default=secondaryRelay, maxlen=128, whitespace=false});
UIHELPER.AddUICallback("IRCRELAY2", function(args) secondaryRelay = args; end);

InterfaceOptions.StopGroup();

--=====================
--		Events       --
--=====================
function OnComponentLoad()
	InterfaceOptions.SetCallbackFunc(function(id, val)
			OnMessage({type=id, data=val})
		end, ADDONNAME);
	
	maXChatLines = WINDOWHEIGTH/LINEHEIGHT;
	
	-- Set up webby framy
	WEBFRAME:SetUrlFilters("*");
	WEBFRAME:AddWebCallback("onTopic", onTopic);
	WEBFRAME:AddWebCallback("onJoin", onJoin);
	WEBFRAME:AddWebCallback("onPart", onPart);
	WEBFRAME:AddWebCallback("onMessage", onIRCMessage);
	
	-- Chat commands
	LIB_SLASH.BindCallback({slash_list="web", description="Show the web thingy", func=slashy.SlashCallback});
	LIB_SLASH.BindCallback({slash_list="irc", description="Say something in the current irc channel", func=slashy.IRC_Say});
	LIB_SLASH.BindCallback({slash_list="ircconnect, irc_connect", description="Connect to a irc server and channel. Usage: /ircconnect server channel", func=slashy.IRC_Connect});
	LIB_SLASH.BindCallback({slash_list="ircdisconnect, irc_disconnect, ircleave", description="Disconnect from the current server and channel", func=slashy.IRC_Disconnect});
	-- LIB_SLASH.BindCallback({slash_list="ircraw", description="Send a raw command to the server, like /ircraw +o Arkii", func=slashy.IRC_Raw});
	
	FRAME:Show(true);
	FRAME:SetParam("alpha", 1.0);
	
	CheckRelayPrimary();
end

slashy.SlashCallback = function()
       Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text="Good Job!"});
	   WEBFRAME:Show(true);
	   Component.SetInputMode("cursor");
end

function OnMessage(args)
	UIHELPER.CheckCallbacks(args);
end

function WebUI_OnNavigationFinished()
	if (ircAutoJoin) then
		IRCConnect(ircServer, ircChan, ircNick);
	end
end

--=====================
--		Functions    --
--=====================
-- Check the relay servers
function CheckRelayPrimary()
	if not HTTP.IsRequestPending() then
		if not (HTTP.IssueRequest(primaryRelay, "GET", nil, RelayPingPrimaryCB)) then
			IRCClientMsg("Error connecting to primary relay server, don't worry I have a back up plan ^^");
			HTTP.IssueRequest(secondaryRelay, "GET", nil, RelayPingSecondaryCB);
		end
	end
end

function RelayPingPrimaryCB(response, errorMsg)
	if (errorMsg.status == 200) then
		activeIRCRelay = primaryRelay;
		LoadWebPage();
	else
		IRCClientMsg("Error connecting to primary relay server, don't worry I have a back up plan ^^");
		if not HTTP.IsRequestPending() then
			if not(HTTP.IssueRequest(secondaryRelay, "GET", nil, RelayPingSecondaryCB)) then
				IRCClientMsg("Aww crpies, my backup plan failed ;(, both relays seem to be down, try again later or find new relays");
			end
		end
	end
end

function RelayPingSecondaryCB(response, errorMsg)
	if (errorMsg.status == 200) then
		IRCClientMsg("AH HA! See my backup plan worked, (as I knew it would >,>), Anyway you might need to check your primary relay if this happens alot :/");
		activeIRCRelay = secondaryRelay;
		LoadWebPage();
	else
		IRCClientMsg("Aww crpies, my back up plan failed ;(, both relays seem to be down, try again later or find new relays");
	end
end

-- Load the script from the active relay
function LoadWebPage()
	activeIRCRelay = string.gsub(activeIRCRelay, "http://", "");
	activeIRCRelay = string.gsub(activeIRCRelay, "www.", "");
	WEBFRAME:AddWebValue('RelayHost', activeIRCRelay);
	WEBFRAME:LoadUrl("http://"..activeIRCRelay);
end

function UpdateWindowSize()
	InterfaceOptions.ChangeFrameHeight(FRAME, WINDOWHEIGTH);
	InterfaceOptions.ChangeFrameWidth(FRAME, WINDOWWIDTH);
	maXChatLines = WINDOWHEIGTH/LINEHEIGHT;
	IRC_MoveMsgs();
end

-- IRC Callbacks
function onTopic(nick, topic)
	IRCServerMsg(nick .. " Changed the topic to: ".. topic);
	IRCShowAllMsgs();
end

function onJoin(nick)
	IRCServerMsg(nick .. " Has joined the channel :D");
	IRCShowAllMsgs();
end

function onPart(nick)
	IRCServerMsg(nick .. " Has left the channel ;(");
	IRCShowAllMsgs();
end

function onIRCMessage(from, chan, msg)
	IRCChatMsg(from, msg);
	IRCShowAllMsgs();
end

-- Slash commands
slashy.IRC_Say = function(args)
	if (args[1] ~= nil) then
		WEBFRAME:CallWebFunc('IRC_Say', args.text);
		IRCChatMsg(ircNick, args.text);
	end
	
	IRCShowAllMsgs();
end

slashy.IRC_Connect  = function(args)
	if (args.text) then
		IRCConnect(args[1], args[2], ircNick);
	end
end

slashy.IRC_Disconnect  = function()
	WEBFRAME:CallWebFunc('IRC_Disconnect', nil);
	IRCClientMsg("You have been disconnected :/");
end

slashy.IRC_Raw  = function()
	WEBFRAME:CallWebFunc('IRC_Raw', nil);
end

--=====================
--	   IRC Window    --
--=====================
-- A simple Message from a user
function IRCChatMsg(from, msg)
	IRCAddMsg("<"..from..">", msg, ircChatmsgColor);
end

-- A IRC Server msg
function IRCServerMsg(msg)
	IRCAddMsg("-!-", msg, ircServermsgColor);
end

-- A message fome the client, me :P
function IRCClientMsg(msg)
	IRCAddMsg("=>", msg, ircClientmsgColor);
end

-- Connect to an IRC Server
function IRCConnect(ircServer, ircChan, ircNick)
	if (ircServer == nil or ircChan == nil or ircNick == nil) then
		IRCClientMsg("Error :/ Please check make sure you enter a server channel and nick");
	else
		IRCClientMsg("Connecting to ".. ircChan.." on ".. ircServer);
		local nick = ircNick;
		
		-- If no nick was set default to their ingame anme :)
		if (nick == "") then
			nick = Player.GetInfo();
		end
		
		WEBFRAME:CallWebFunc('IRC_Connect', ircServer, ircChan, nick);
	end
end

function IRCAddMsg(tag, msg, color)
	local LINE = {}
	LINE.GROUP = Component.CreateWidget("IRCline", FRAME);
	LINE.PLATE = LINE.GROUP:GetChild("plate");
	LINE.TEXT = LINE.GROUP:GetChild("text");
	LINE.PLATE:SetParam("tint", ircMsgBgColor);
	LINE.GROUP:SetParam("alpha", ircMsgBgAlpha);
	LINE.GROUP:Show(true);
	LINE.GROUP:SetParam("alpha", 1.0);
	local txt = tag .. " " .. msg;
	LINE.TEXT:SetText(txt);
	LINE.NUMLINES = GetNumLines(txt, 8, WINDOWWIDTH);
	LINE.LINEHEIGTH = (LINE.NUMLINES * LINEHEIGHT);
	LINE.GROUP:SetDims("left:0; width:100%; top:".. (WINDOWHEIGTH - LINE.LINEHEIGTH) .."; height:"..LINE.LINEHEIGTH);
	LINE.TEXT:SetTextColor(color);
	LINE.GROUP:ParamTo("alpha", 0, 5, ircMsgFadeTime);
	
	table.insert(chatLines, 1, LINE);
	
	-- Move all the other lines up
	IRC_MoveMsgs();
	
	-- Remove old msgs
	if (#chatLines >= maXChatLines) then
		local rl = chatLines[#chatLines];
		Component.RemoveWidget(rl.GROUP);
		table.remove(chatLines, #chatLines)
	end
end

-- Show all the messages again
function IRCShowAllMsgs()
	for i = 1, #chatLines do
		chatLines[i].GROUP:SetParam("alpha", 1.0);
		chatLines[i].GROUP:ParamTo("alpha", 0, 5, ircMsgFadeTime);
	end
end

-- Move the chat lines to adjust for window resize or the addition of a new msg
function IRC_MoveMsgs()
	local totalLineHeight = 0;
	for i = 1, #chatLines do
		totalLineHeight = totalLineHeight + chatLines[i].LINEHEIGTH;
		chatLines[i].GROUP:MoveTo("left:0; width:100%; top:".. (WINDOWHEIGTH - totalLineHeight) .."; height:".. chatLines[i].LINEHEIGTH .."", 0.01, 0, "linear");
	end
end

-- Returns the number of lines needed to fit the given text
function GetNumLines(txt, charWidth, areaWidth)
	local totalWidth = string.len(txt) * charWidth;
	local numLines = totalWidth / areaWidth;
	return math.floor(numLines) + 1;
end
