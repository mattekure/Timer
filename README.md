# Timer

v1.5 - Include TurnTimer concepts where it starts/resets the timer on each actor's turn.  Added support for a localhost based URL (http://localhost:1803) instead of the default web based URL. If it's not present, the resolution of the timer will only be 4sec, which seems to be the timeout.  I made a simple node app as a host and it worked great, even at 500ms.  That file is included as delayed-response.js and can be run via Node with the command 'node delayed-response.js'.

