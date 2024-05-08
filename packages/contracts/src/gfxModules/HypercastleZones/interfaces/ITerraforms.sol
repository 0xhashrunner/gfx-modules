// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

interface ITerraforms {
    struct TokenData {
        uint tokenId;
        uint level;
        uint xCoordinate;
        uint yCoordinate;
        int elevation;
        int structureSpaceX;
        int structureSpaceY;
        int structureSpaceZ;
        string zoneName;
        string[10] zoneColors;
        string[9] characterSet;
    }

    function tokenSupplementalData(
        uint tokenId
    ) external view returns (TokenData memory);

    function tokenHeightmapIndices(
        uint tokenId
    ) external view returns (uint[32][32] memory);

    function tokenTerrainValues(
        uint tokenId
    ) external view returns (int[32][32] memory);

    function tokenToPlacement(uint) external view returns (uint);

    function seed() external view returns (uint);
}
