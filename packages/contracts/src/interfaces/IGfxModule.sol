// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {ART0x1Types} from "../ART0x1Types.sol";

interface IGfxModule {
    function runGfxModule(
        bytes[12] memory _instructions,
        uint _prn,
        uint _uint,
        string memory _string
    )
        external
        view
        returns (ART0x1Types.TokenGfx memory gfx, string memory script);
}
