# Acedia

`Acedia` is a mod for the game `Killing Floor` that aims to provide powerful means to configure and customize every aspect of gameplay, while affecting game as little as possible for the chosen changes. Ideally, when server admin disables every single feature of `Acedia` it would do nothing at all.

The project is in it's early stage and right now is focused on fixing a baggage of bugs and exploits that base `Killing Floor` game has. Currently it functions as a server-side only mutator that doesn't break server's whitelist status.

## Installation

1. Drop `Acedia` files into `System\` directory of your server.
2. Add `Acedia.StartUp` to the list of server actors in your `KillingFloor.ini`.
**Do not** manually add `Acedia.Acedia` mutator.
3. [Optionally] Pick which features to use by changing `autoEnabled` setting for each of them.
