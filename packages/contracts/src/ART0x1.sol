// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import "sstore2/contracts/SSTORE2.sol";
import {IERC721} from "openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IART0x1} from "./interfaces/IART0x1.sol";
import {ART0x1Types} from "./ART0x1Types.sol";
import {ERC721Base} from "./ERC721Base.sol";

/// @author hashrunner.eth
/// @title  ART0x1
contract ART0x1 is ERC721Base {
    //
    //   █████╗ ██████╗ ████████╗ ██████╗ ██╗  ██╗ ██╗
    //  ██╔══██╗██╔══██╗╚══██╔══╝██╔═████╗╚██╗██╔╝███║
    //  ███████║██████╔╝   ██║   ██║██╔██║ ╚███╔╝ ╚██║
    //  ██╔══██║██╔══██╗   ██║   ████╔╝██║ ██╔██╗  ██║
    //  ██║  ██║██║  ██║   ██║   ╚██████╔╝██╔╝ ██╗ ██║
    //  ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═╝
    //
    // ------------------------------------------------------------------------
    // STORAGE
    // ------------------------------------------------------------------------

    // CONFIGURATION ----------------------------------------------------------

    address[] public programAddresses;

    mapping(uint => uint) public tokenToProgramAddress;

    // MINTING ----------------------------------------------------------------

    bool public earlyMintActive;

    bool public publicMintActive;

    // INSTRUCTIONS -----------------------------------------------------------

    address public preRevealInstructions;

    mapping(uint => address) public tokenInstructions;

    // GALLERIES --------------------------------------------------------------

    mapping(uint => ART0x1Types.Gallery) public galleries;

    mapping(uint => address) public galleryToCurator;

    mapping(uint => mapping(address => bool)) public isArtistInvitedToGallery;

    mapping(uint => bool) public isGalleryRevealed;

    mapping(uint => uint) public tokenToGalleryId;

    mapping(uint => uint[]) public tokenToVisitedGalleries;

    bool public isGalleryCurationPermissionless;

    // GFX MODULES ------------------------------------------------------------

    address[] public gfxModuleAddresses;

    mapping(address => ART0x1Types.GfxModule) public gfxModules;

    mapping(uint => address) public tokenToGfxModuleAddress;

    mapping(uint => uint) public tokenToGfxModuleUint;

    mapping(uint => string) public tokenToGfxModuleString;

    mapping(uint => address[]) public tokenToExecutedGfxModules;

    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    // CONSTRUCTOR
    // ------------------------------------------------------------------------

    constructor() ERC721Base("ART0x1", "ART0X1", 0.068 ether, 1024) {}

    // ------------------------------------------------------------------------
    // CONFIGURATION
    // ------------------------------------------------------------------------

    function addProgramAddress(address _newAddress) public onlyOwner {
        programAddresses.push(_newAddress);
    }

    function setTokenProgramAddress(
        uint[] memory _tokenIds,
        uint _index
    ) public {
        require(
            _index < programAddresses.length,
            "ART0x1: no program at _index."
        );

        for (uint i; i < _tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(_tokenIds[i]),
                "ART0x1: one or more tokens are not yours."
            );
            tokenToProgramAddress[_tokenIds[i]] = _index;
        }
    }

    // ------------------------------------------------------------------------
    // MINTING
    // ------------------------------------------------------------------------

    function toggleEarly() public onlyOwner {
        require(
            programAddresses.length > 0 && preRevealInstructions != address(0),
            "ART0x1: program not configured."
        );
        earlyMintActive = !earlyMintActive;
    }

    function togglePublic() public onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function mintAdmin(
        uint _numToBeMinted
    ) external onlyOwner withinMintLimit(6, _numToBeMinted) nonReentrant {
        require(
            programAddresses.length > 0 && preRevealInstructions != address(0),
            "ART0x1: program not configured."
        );
        _mintMany(_msgSender(), _numToBeMinted);
    }

    function mintEarly(
        uint _numToBeMinted
    )
        external
        payable
        hasExactPayment(_numToBeMinted)
        withinMintLimit(3, _numToBeMinted)
        nonReentrant
    {
        require(earlyMintActive, "ART0x1: cannot mint yet.");
        require(
            IERC721(0x4E1f41613c9084FdB9E34E11fAE9412427480e56).balanceOf(
                msg.sender
            ) > 0,
            "ART0x1: need Terraforms to mint early."
        );
        _mintMany(_msgSender(), _numToBeMinted);
    }

    function mint(
        uint _numToBeMinted
    )
        external
        payable
        hasExactPayment(_numToBeMinted)
        withinMintLimit(3, _numToBeMinted)
        nonReentrant
    {
        require(publicMintActive, "ART0x1: public cannot mint yet.");
        _mintMany(_msgSender(), _numToBeMinted);
    }

    // ------------------------------------------------------------------------
    // INSTRUCTIONS
    // ------------------------------------------------------------------------

    function setPreRevealInstructions(
        string[12] memory _instructions
    ) public onlyOwner {
        preRevealInstructions = storeInstructions(_instructions);
    }

    function setTokenInstructions(
        uint _tokenId,
        string[12] memory _instructions
    ) public {
        require(_exists(_tokenId), "ART0x1: token does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "ART0x1: not your token.");
        require(
            isGalleryRevealed[0] == true,
            "ART0x1: cannot set instructions until after genesis reveal."
        );

        tokenInstructions[_tokenId] = storeInstructions(_instructions);
    }

    function getTokenInstructions(
        uint _tokenId
    ) public view returns (string[12] memory) {
        require(_exists(_tokenId), "ART0x1: token does not exist.");
        require(
            tokenInstructions[_tokenId] != address(0),
            "ART0x1: token instructions not set."
        );

        bytes memory instr = SSTORE2.read(tokenInstructions[_tokenId]);
        bytes[12] memory byteStrings = abi.decode(instr, (bytes[12]));
        string[12] memory result;

        for (uint i = 0; i < byteStrings.length; ) {
            result[i] = string(byteStrings[i]);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function clearTokenInstructions(uint[] memory _tokenIds) public {
        for (uint i = 0; i < _tokenIds.length; ) {
            uint tokenId = _tokenIds[i];

            require(_exists(tokenId), "ART0x1: token does not exist.");
            require(ownerOf(tokenId) == msg.sender, "ART0x1: not your token.");

            tokenInstructions[tokenId] = address(0);

            unchecked {
                ++i;
            }
        }
    }

    // ------------------------------------------------------------------------
    // GALLERIES
    // ------------------------------------------------------------------------

    function assignGalleryCurator(
        uint _galleryIndex,
        address _curatorAddress
    ) public {
        if (!isGalleryCurationPermissionless) {
            require(
                owner() == msg.sender,
                "ART0x1: only owner can assign gallery curators."
            );
        }
        require(
            galleryToCurator[_galleryIndex] == address(0),
            "ART0x1: _galleryIndex is taken."
        );

        galleryToCurator[_galleryIndex] = _curatorAddress;
    }

    function inviteGalleryArtists(
        uint _galleryIndex,
        address[] memory _artistAddressList
    ) public {
        require(
            galleryToCurator[_galleryIndex] == msg.sender,
            "ART0x1: only curator of _galleryIndex can invite artists."
        );

        uint len = _artistAddressList.length;
        for (uint i = 0; i < len; ) {
            isArtistInvitedToGallery[_galleryIndex][
                _artistAddressList[i]
            ] = true;

            unchecked {
                i++;
            }
        }
    }

    function addGalleryItem(
        uint _galleryIndex,
        string[12] memory _instructions
    ) public {
        require(
            isArtistInvitedToGallery[_galleryIndex][msg.sender],
            "ART0x1: only invited artists can add to gallery"
        );

        address data = storeInstructions(_instructions);
        galleries[_galleryIndex].instructions.push(data);
        galleries[_galleryIndex].artists.push(msg.sender);
    }

    function addGalleryItems(
        uint _galleryIndex,
        string[12][] memory _instructionsList
    ) public {
        require(
            !isGalleryRevealed[_galleryIndex],
            "ART0x1: gallery already revealed, cannot add instructions."
        );

        for (uint i = 0; i < _instructionsList.length; i++) {
            require(
                isArtistInvitedToGallery[_galleryIndex][msg.sender],
                "ART0x1: only invited artists can add to gallery"
            );
        }

        uint len = _instructionsList.length;
        for (uint i = 0; i < len; ) {
            addGalleryItem(_galleryIndex, _instructionsList[i]);
            unchecked {
                i++;
            }
        }
    }

    function revealGallery(
        uint _galleryIndex,
        string memory _name,
        uint _price
    ) public {
        require(
            galleryToCurator[_galleryIndex] == msg.sender,
            "ART0x1: only gallery curator can reveal."
        );

        require(
            (!isGalleryRevealed[_galleryIndex]),
            "ART0x1: gallery at _galleryIndex already revealed."
        );

        uint instructionsLength = galleries[_galleryIndex].instructions.length;

        require(
            instructionsLength != 0,
            "ART0x1: gallery at _galleryIndex is empty."
        );

        galleries[_galleryIndex].name = _name;
        galleries[_galleryIndex].price = _price;
        galleries[_galleryIndex].curator = msg.sender;

        // Shuffle instructions and artists using Fisher-Yates algorithm
        address[] storage instructions = galleries[_galleryIndex].instructions;
        address[] storage artists = galleries[_galleryIndex].artists;

        for (uint i = instructionsLength - 1; i > 0; i--) {
            uint j = uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        blockhash(block.number - 1),
                        i
                    )
                )
            ) % (i + 1);

            // Shuffle instructions
            address tempInstruction = instructions[i];
            instructions[i] = instructions[j];
            instructions[j] = tempInstruction;

            // Shuffle artists
            address tempArtist = artists[i];
            artists[i] = artists[j];
            artists[j] = tempArtist;
        }

        // Set revealed
        isGalleryRevealed[_galleryIndex] = true;
    }

    function setTokenGallery(
        uint _tokenId,
        uint _galleryIndex
    ) public payable nonReentrant {
        require(
            isGalleryRevealed[0],
            "ART0x1: cannot set new gallery before genesis reveal."
        );

        require(
            galleries[_galleryIndex].instructions.length > 0 &&
                isGalleryRevealed[_galleryIndex],
            "ART0x1: gallery does not exist or is not yet revealed."
        );

        require(_exists(_tokenId), "ART0x1: token does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "ART0x1: not your token.");

        bool previouslyVisited = false;
        for (uint i = 0; i < tokenToVisitedGalleries[_tokenId].length; ) {
            if (tokenToVisitedGalleries[_tokenId][i] == _galleryIndex) {
                previouslyVisited = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        // Check msg.value on first visit
        uint galleryPrice = galleries[_galleryIndex].price;
        if (!previouslyVisited) {
            require(msg.value >= galleryPrice, "ART0x1: insufficient payment.");
        }

        tokenToGalleryId[_tokenId] = _galleryIndex;
        tokenInstructions[_tokenId] = address(0);

        // Add to the visited gallery if it hasn't been visited before
        if (!previouslyVisited) {
            tokenToVisitedGalleries[_tokenId].push(_galleryIndex);
        }

        // Refund excess payment if any
        if (msg.value > galleryPrice) {
            payable(msg.sender).transfer(msg.value - galleryPrice);
        }

        // Transfer payment to the curator of the gallery minus 2% fee
        if (galleryPrice > 0 && !previouslyVisited) {
            uint fee = (galleryPrice * 2) / 100;
            uint amountToCurator = galleryPrice - fee;
            address curatorAddress = galleries[_galleryIndex].curator;
            payable(curatorAddress).transfer(amountToCurator);
        }
    }

    // ------------------------------------------------------------------------
    // GFX MODULES
    // ------------------------------------------------------------------------

    function listGfxModule(
        string memory _name,
        address _moduleAddress,
        uint _price
    ) public {
        require(
            gfxModules[_moduleAddress].moduleAddress == address(0),
            "Module already listed for this address"
        );

        ART0x1Types.GfxModule memory newModule = ART0x1Types.GfxModule(
            _name,
            msg.sender,
            _moduleAddress,
            _price
        );

        gfxModuleAddresses.push(_moduleAddress);
        gfxModules[_moduleAddress] = newModule;
    }

    function getGfxModuleByIndex(
        uint _index
    ) public view returns (ART0x1Types.GfxModule memory) {
        require(
            _index < gfxModuleAddresses.length,
            "ART0x1: gfx module does not exist."
        );

        address moduleAddress = gfxModuleAddresses[_index];
        return gfxModules[moduleAddress];
    }

    function getGfxModules()
        public
        view
        returns (ART0x1Types.GfxModule[] memory)
    {
        ART0x1Types.GfxModule[] memory modules = new ART0x1Types.GfxModule[](
            gfxModuleAddresses.length
        );
        for (uint i = 0; i < gfxModuleAddresses.length; i++) {
            modules[i] = gfxModules[gfxModuleAddresses[i]];
        }
        return modules;
    }

    function setTokenGfxModule(
        uint _tokenId,
        address _gfxModuleAddress,
        uint _uint,
        string memory _string
    ) public payable nonReentrant {
        require(_exists(_tokenId), "ART0x1: token does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "ART0x1: not your token.");
        require(
            gfxModules[_gfxModuleAddress].moduleAddress != address(0),
            "ART0x1: gfx module does not exist."
        );
        require(
            isGalleryRevealed[0],
            "ART0x1: cannot set modules until after genesis gallery reveal."
        );

        // If module is HypercastleZones, require ownership of specified
        // terraforms token
        if (gfxModuleAddresses[0] == _gfxModuleAddress) {
            require(
                IERC721(0x4E1f41613c9084FdB9E34E11fAE9412427480e56).ownerOf(
                    _uint
                ) == msg.sender,
                "ART0x1: not your terraforms token."
            );
        }

        // Determine if the module has been previously executed
        bool previouslyExecuted = false;
        for (uint i = 0; i < tokenToExecutedGfxModules[_tokenId].length; ) {
            if (tokenToExecutedGfxModules[_tokenId][i] == _gfxModuleAddress) {
                previouslyExecuted = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        // Check msg.value on first execution
        uint modulePrice = gfxModules[_gfxModuleAddress].price;
        if (!previouslyExecuted) {
            require(msg.value >= modulePrice, "ART0x1: insufficient payment.");
        }

        // Update token to gfx module mapping
        tokenToGfxModuleAddress[_tokenId] = _gfxModuleAddress;
        tokenToGfxModuleUint[_tokenId] = _uint;
        tokenToGfxModuleString[_tokenId] = _string;

        // Add to the executed gfx modules if it hasn't been added before
        if (!previouslyExecuted) {
            tokenToExecutedGfxModules[_tokenId].push(_gfxModuleAddress);
        }

        // Refund excess payment if any
        if (msg.value > modulePrice) {
            payable(msg.sender).transfer(msg.value - modulePrice);
        }

        // Transfer payment to the author of the gfx module minus 2% fee
        if (modulePrice > 0 && !previouslyExecuted) {
            uint fee = (modulePrice * 2) / 100;
            uint amountToAuthor = modulePrice - fee;
            address authorAddress = gfxModules[_gfxModuleAddress].authorAddress;
            payable(authorAddress).transfer(amountToAuthor);
        }
    }

    function resetTokenGfxModule(uint[] memory _tokenIds) public {
        for (uint i = 0; i < _tokenIds.length; ) {
            uint tokenId = _tokenIds[i];

            require(_exists(tokenId), "ART0x1: token does not exist.");
            require(ownerOf(tokenId) == msg.sender, "ART0x1: not your token.");

            tokenToGfxModuleAddress[tokenId] = address(0);
            tokenToGfxModuleUint[tokenId] = 0;
            tokenToGfxModuleString[tokenId] = "";

            unchecked {
                ++i;
            }
        }
    }

    // ------------------------------------------------------------------------
    // TOKEN DATA
    // ------------------------------------------------------------------------

    function tokenHTML(uint _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ART0x1: token does not exist.");

        return getTokenProgram(_tokenId).tokenHTML(getTokenContext(_tokenId));
    }

    function tokenSVG(uint _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ART0x1: token does not exist.");

        return getTokenProgram(_tokenId).tokenSVG(getTokenContext(_tokenId));
    }

    function tokenURI(
        uint _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "ART0x1: token does not exist.");

        return getTokenProgram(_tokenId).tokenURI(getTokenContext(_tokenId));
    }

    // ------------------------------------------------------------------------
    // UTILS
    // ------------------------------------------------------------------------

    function getTokenProgram(uint _tokenId) private view returns (IART0x1) {
        return IART0x1(programAddresses[tokenToProgramAddress[_tokenId]]);
    }

    function getTokenContext(
        uint _tokenId
    ) internal view returns (ART0x1Types.TokenCtx memory tokenCtx) {
        tokenCtx.id = _tokenId;
        tokenCtx.prn = tokenToPRN[_tokenId];
        tokenCtx.galleryId = tokenToGalleryId[_tokenId];

        ART0x1Types.Gallery memory gallery = galleries[tokenCtx.galleryId];

        // Artwork
        if (!isGalleryRevealed[0]) {
            // Pre-Reveal
            tokenCtx.instructions = abi.decode(
                SSTORE2.read(preRevealInstructions),
                (bytes[12])
            );
            tokenCtx.mode = ART0x1Types.Mode.PRE_REVEAL;
        } else {
            address instructionsAddress = tokenInstructions[_tokenId];
            uint galleryItemCount = gallery.instructions.length;

            if (instructionsAddress != address(0)) {
                // Original
                tokenCtx.instructions = abi.decode(
                    SSTORE2.read(instructionsAddress),
                    (bytes[12])
                );
                tokenCtx.mode = ART0x1Types.Mode.ORIGINAL;
                tokenCtx.artistAddress = ownerOf(_tokenId);
            } else {
                // Gallery
                tokenCtx.instructions = abi.decode(
                    SSTORE2.read(
                        gallery.instructions[tokenCtx.prn % galleryItemCount]
                    ),
                    (bytes[12])
                );
                tokenCtx.mode = ART0x1Types.Mode.GALLERY;
                tokenCtx.artistAddress = gallery.artists[
                    tokenCtx.prn % galleryItemCount
                ];
                tokenCtx.galleryName = gallery.name;
                tokenCtx.galleryCurator = galleryToCurator[tokenCtx.galleryId];
            }
        }

        // Preset GFX
        (
            tokenCtx.gfx.colors,
            tokenCtx.gfx.fontName,
            tokenCtx.gfx.fontFilename,
            tokenCtx.gfx.fontSize
        ) = getTokenPresetGfx(tokenCtx.prn);

        // GFX Module
        address gfxModuleAddress = tokenToGfxModuleAddress[_tokenId];
        ART0x1Types.GfxModule memory gfxModule = gfxModules[gfxModuleAddress];
        tokenCtx.moduleName = gfxModule.name;
        tokenCtx.moduleAuthor = gfxModule.authorAddress;
        tokenCtx.moduleAddress = gfxModuleAddress;
        tokenCtx.moduleUint = tokenToGfxModuleUint[_tokenId];
        tokenCtx.moduleString = tokenToGfxModuleString[_tokenId];
    }

    function getTokenPresetGfx(
        uint _prn
    )
        internal
        pure
        returns (
            string[3] memory _colors,
            string memory _fontName,
            string memory _fontFilename,
            string memory _fontSize
        )
    {
        string[12] memory presetColorsOpts = [
            // bg
            "#f4f4f4",
            "#262626",
            "#8d8d8d29",
            "#161616",
            // c1
            "#161616",
            "#c6c6c6",
            "#6f6f6f",
            "#8d8d8d",
            // c2
            "#161616",
            "#c6c6c6",
            "#6f6f6f",
            "#8d8d8d"
        ];

        uint colorId = _prn % 4;
        _colors[0] = presetColorsOpts[colorId];
        _colors[1] = presetColorsOpts[4 + colorId];
        _colors[2] = presetColorsOpts[8 + colorId];
        _fontName = "IBM Plex Mono";
        // NOTE: Commented so we're not calling ethfs.getFile locally
        _fontFilename = "";
        // _fontFilename = "IBMPlexMono-Regular.woff2";
        _fontSize = "12px";
    }

    function storeInstructions(
        string[12] memory _instructions
    ) internal returns (address) {
        bytes[12] memory bytesInstructions;
        for (uint i = 0; i < _instructions.length; ) {
            bytesInstructions[i] = bytes(_instructions[i]);
            unchecked {
                ++i;
            }
        }
        return SSTORE2.write(abi.encode(bytesInstructions));
    }
}
