# GFX Modules Starter Kit

[ART0x1](https://www.art0x1.com/) source contracts, [GFX Module](https://www.art0x1.com/learn/gfx-modules) templates and forge testing scripts to make module development a breeze.

### Requirements

Make sure [Foundry](https://book.getfoundry.sh/getting-started/installation) is installed.

Give the [GFX Module](https://www.art0x1.com/learn/gfx-modules) docs a read to familiarise yourself with the design space and constraints.

### Running locally

Simply clone this repo and run `forge test -vvv` from the command line to log two base64 encoded tokenURIs which you can copy paste into your browser:

- tokenURI of Gallery artwork
- tokenURI of Gallery artwork + GFX Module

### Developing

Various `NOTE`s have been sprinkled into the source code and in particular the testing scripts, which should give you a sense of the workflow.

To start prototyping ideas, simply create a new directory at `packages/contracts/src/gfxModules` and add `YourGfxModule.sol` file into it.

Next update the imports and variables in `packages/contracts/test/ART0x1.sol` before running `forge test -vvv` and copy-pasting the latest tokenURI logs into your browser.

### Deploying

To deploy and test your GFX Module against ART0x1 on Sepolia, copy env.example to env.local, fill in the required environment variales and run `deployGfxModule` script from `packages/contracts` after updating the script with your contract path and name.

### Please Note

The usage of files uploaded to ethfs is not yet supported locally and relevant parts of the code have been commented out for this reason.

If you're planning on using:
- IBM Plex Mono as your font, you can simply [install it locally on your machine](https://github.com/IBM/plex/releases) for now and artworks will render correctly in your browser.
- p5.js or three.js in your GFX module, simply copy paste the minified code into your modules script tag variable.

More example contracts will be provided soon™ and running ethfs locally should also be possible.

Enjoy,

hashrunner

