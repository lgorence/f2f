# f2f
f2f (face2face) is a basic video chat application built using Flutter and WebRTC. It uses a fork of the flutter-webrtc plugin, available [here](https://github.com/lgorence/flutter-webrtc).

## Is there a public instance available?
Not at the moment. I did have it hosted on my home network, but this was only for testing with friends and family. It doesn't take much to host (because the only requirements are a web server and a simple WebSocket signaling server), so if anyone were to set it up, it could easily be done on a $5/month DigitalOcean droplet.

## How would I set one up?
Install Dart, copy the signaling server script over, run that. Then you'll need to find the URLs in the Flutter source code that refer to where to connect to the signal server (left as an exercise to the reader). Build for web and deploy to the web server of your choice with HTTPS (you'll need this, as far as I know, most if not all web browsers require HTTPS on non-localhost hosts).
