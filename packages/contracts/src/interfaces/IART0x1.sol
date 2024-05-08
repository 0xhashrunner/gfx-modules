// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {ART0x1Types} from "../ART0x1Types.sol";

interface IART0x1 {
    function tokenHTML(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory);

    function tokenSVG(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory);

    function tokenURI(
        ART0x1Types.TokenCtx memory _tokenCtx
    ) external view returns (string memory);
}
