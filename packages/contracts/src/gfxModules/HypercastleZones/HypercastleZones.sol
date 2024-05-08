// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {ITerraforms} from "./interfaces/ITerraforms.sol";
import {ART0x1Types} from "../../ART0x1Types.sol";

/// @author hashrunner.eth
/// @title  HypercastleZones
contract HypercastleZones {
    //
    //   ██████╗ ███████╗██╗  ██╗    ███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗
    //  ██╔════╝ ██╔════╝╚██╗██╔╝    ████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝
    //  ██║  ███╗█████╗   ╚███╔╝     ██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗  
    //  ██║   ██║██╔══╝   ██╔██╗     ██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝  
    //  ╚██████╔╝██║     ██╔╝ ██╗    ██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗
    //   ╚═════╝ ╚═╝     ╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
    //
    // 
    ITerraforms terraforms =
        ITerraforms(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);

    function runGfxModule(
        bytes[12] memory _instructions,
        uint _prn,
        uint _uint,
        string memory _string
    )
        public
        view
        returns (ART0x1Types.TokenGfx memory gfx, string memory script)
    {
        gfx.fontName = "IBM Plex Mono";
        // NOTE: Commented so we're not calling ethfs.getFile() locally where
        //  it does not exist. Can look into deploying ethfs locally next.
        gfx.fontFilename = "";
        // _fontFilename = "IBMPlexMono-Regular.woff2";
        gfx.fontSize = "12px";

        string[10] memory zoneColors = terraforms
            .tokenSupplementalData(_uint)
            .zoneColors;

        gfx.colors[0] = zoneColors[9]; // bg
        gfx.colors[1] = zoneColors[0]; // c1
        gfx.colors[2] = zoneColors[1]; // c2

        // Shoutout to yeetljuice and Terraflows
        string memory zoneColorsArray = '["';
        for (uint i; i < 8; i++) {
            zoneColorsArray = string.concat(
                zoneColorsArray,
                zoneColors[i],
                '","'
            );
        }
        zoneColorsArray = string.concat(zoneColorsArray, zoneColors[8], '"]');

        script = string(
            abi.encodePacked(
                'document.addEventListener("DOMContentLoaded",function(){let e'
                '=',
                zoneColorsArray,
                ',t=["[MONO]","[DUO]","Random"],l=document.querySelectorAll("s'
                'vg text"),a=!0,d=0,n=0,o=0,i=null,$=()=>Math.floor(Math.rando'
                'm()*e.length),g=(a,n)=>{let i,g;if("Random"===t[d])for(i=e[$('
                ')],g=e[$()];g===i;)g=e[$()];l.forEach((l,o)=>{"[MONO]"===t[d]'
                '?l.style.fill=e[a]:("[DUO]"===t[d]||"Random"===t[d])&&(l.styl'
                'e.fill=o%2==0?"Random"===t[d]?i:e[a]:"Random"===t[d]?g:e[n])}'
                '),"Random"===t[d]&&++o>=9&&h()},h=()=>{d=i?t.indexOf(i):++d%t'
                '.length,n=o=0},r=()=>{a&&("Random"!==t[d]?(g(n,(n+1)%e.length'
                '),++n===e.length&&h()):g())};document.addEventListener("keydo'
                'wn",function(e){let t=e.key.toLowerCase();if("p"===t)a=!a,con'
                'sole.log("Play:",a?"ON":"OFF");else if(["m","d","r"].includes'
                '(t)){let l={m:"[MONO]",d:"[DUO]",r:"Random"};i===l[t]?(i=null'
                ',d=-1,n=0,console.log("Mode: Default")):(i=l[t],console.log("'
                'Mode:",l[t])),h()}else if("escape"===t)i&&(i=null,d=-1,n=0,co'
                'nsole.log("Mode: Default"),h());else if("e"===t){var o=docume'
                'nt.getElementById("svg"),$=new XMLSerializer().serializeToStr'
                'ing(o),g=o.viewBox.baseVal,r=document.createElement("canvas")'
                ',f=r.getContext("2d");g?(r.width=6*g.width,r.height=6*g.heigh'
                't):(r.width=6*o.width.baseVal.value,r.height=6*o.height.baseV'
                'al.value);var c=new Blob([$],{type:"image/svg+xml;charset=utf'
                '-8"}),s=URL.createObjectURL(c),m=new Image;m.onload=function('
                '){f.clearRect(0,0,r.width,r.height),f.drawImage(m,0,0,r.width'
                ',r.height);var e=r.toDataURL("image/png"),t=document.createEl'
                'ement("a");t.href=e,t.download="download.png",document.body.a'
                'ppendChild(t),t.click(),document.body.removeChild(t),URL.revo'
                'keObjectURL(e)},m.src=s}}),r(),setInterval(r,1e3),console.log'
                '("Play: ON"),console.log("Mode: Default")});'
            )
        );
    }
}
