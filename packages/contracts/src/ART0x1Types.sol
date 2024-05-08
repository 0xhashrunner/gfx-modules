// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

library ART0x1Types {
    enum Mode {
        PRE_REVEAL,
        ORIGINAL,
        GALLERY
    }

    struct InitInstructions {
        bytes1 sym1;
        bytes1 sym2;
        uint nCol;
        uint mCol;
        string title;
    }

    struct ShapeInstructions {
        bytes1 sym;
        uint8 arr;
        int16 row;
        int16 col;
        int16 nR;
        int16 nC;
        int16[] repeatRows;
        int16[] repeatCols;
    }

    struct Gallery {
        string name;
        uint price;
        address curator;
        address[] instructions;
        address[] artists;
    }

    struct GfxModule {
        string name;
        address authorAddress;
        address moduleAddress;
        uint price;
    }

    struct TokenGfx {
        string[3] colors;
        string fontName;
        string fontFilename;
        string fontSize;
    }

    struct TokenCtx {
        uint id;
        uint prn;
        uint galleryId;
        uint moduleUint;
        address artistAddress;
        address galleryCurator;
        address moduleAuthor;
        address moduleAddress;
        bytes[12] instructions;
        TokenGfx gfx;
        Mode mode;
        string galleryName;
        string moduleName;
        string moduleString;
    }
}
