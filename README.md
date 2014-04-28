I built CCCPushManager as a way to send push notifications for my new
app [Letters - a game about spelling
words](https://itunes.apple.com/us/app/letters-game-about-spelling/id823334911?ls=1&mt=8). Please
check it out!

# CCCPushManager

A client reference implementation for
[PushServer](https://github.com/jazzychad/PushServer) demonstrating
how to register/update a device token, subscribe to channels,
unsubscribe from channels, and retrieve the currently subscribed
channel list.

This example uses AFNetworking internally to talk to the
PushServer. The example code is not a standalone working class
(although it could be if you have the right AFNetworking library in
your app), it is more illustrative of how one might interact with the
PushServer backend.
