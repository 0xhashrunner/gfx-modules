// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../src/ERC721Base.sol";
import {ART0x1} from "../src/ART0x1.sol";
import {ART0x1Program} from "../src/ART0x1Program.sol";
import {HypercastleZones} from "../src/gfxModules/HypercastleZones/HypercastleZones.sol";

// NOTE: import your GFX Module
import {PresetHexploit} from "../src/gfxModules/PresetHexploit/PresetHexploit.sol";

contract ART0x1Test is Test {
    // ------------------------------------------------------------------------
    // STORAGE
    // ------------------------------------------------------------------------
    ART0x1 private _nftContract;
    ART0x1Program private _programContract;
    HypercastleZones private _hypercastleZonesContract;
    
    // NOTE: define GFX Module storage variable
    PresetHexploit private _presetHexploitContract;

    address private _owner =
        vm.addr(uint256(keccak256(abi.encodePacked("_owner"))));

    address private _minter =
        vm.addr(uint256(keccak256(abi.encodePacked("_minter"))));

    address private _curator =
        vm.addr(uint256(keccak256(abi.encodePacked("_curator"))));

    address private _artist =
        vm.addr(uint256(keccak256(abi.encodePacked("_artist"))));

    address private _moduleDev =
        vm.addr(uint256(keccak256(abi.encodePacked("_moduleDev"))));

    // ------------------------------------------------------------------------
    // SETUP
    // ------------------------------------------------------------------------

    function setUp() public {
        // deploy contract
        _nftContract = new ART0x1();
        _nftContract.transferOwnership(_owner);

        // deploy program
        _programContract = new ART0x1Program();
        _programContract.transferOwnership(_owner);

        // deploy Hypercastle Zones GFX Module locally
        _hypercastleZonesContract = new HypercastleZones();

        // NOTE: deploy your GFX Module locally
        _presetHexploitContract = new PresetHexploit();

        // give _owner and _minter some eth
        vm.deal(_owner, 100 ether);
        vm.deal(_minter, 100 ether);

        // set program address
        address programContractAddress = address(_programContract);
        vm.prank(_owner);
        _nftContract.addProgramAddress(programContractAddress);

        // _owner sets preRevealInstructions
        string[12] memory preRevealInstructions = [
            // solhint-disable-next-line
            "sym1 . nCol 2 sym2 \" mCol 1 title ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-*/=.,'()$",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        ];
        vm.prank(_owner);
        _nftContract.setPreRevealInstructions(preRevealInstructions);

        // _owner creates gallery
        vm.prank(_owner);
        _nftContract.assignGalleryCurator(0, _owner);

        assertEq(_nftContract.galleryToCurator(0), _owner);

        address[] memory artistToInvite = new address[](1);

        artistToInvite[0] = _owner;

        vm.prank(_owner);
        _nftContract.inviteGalleryArtists(0, artistToInvite);

        assertEq(
            _nftContract.isArtistInvitedToGallery(0, artistToInvite[0]),
            true
        );

        // _owner adds a genesis artwork
        string[12] memory galleryInstructions = [
            "sym1 T nCol 1 sym2   mCol   title A BLOCK CHANGE BY HASHRUNNER",
            "1 sym H arr 2 row 0 col 0 nR 10 nC 21 r1 40 c1 21 r2 0 c2 42 r3 40 c3 63 r4 0 c4 84",
            "1 sym = arr 2 row 10 col 0 nR 10 nC 21 r1 30 c1 21 r2 10 c2 42 r3 30 c3 63 r4 10 c4 84",
            "1 sym - arr 2 row 20 col 0 nR 10 nC 105",
            "1 sym - arr 1 row 40 col 0 nR 10 nC 21 r1 0 c1 21 r2 40 c2 42 r3 0 c3 63 r4 40 c4 84",
            "0 sym   arr 1 row 0 col 20 nR 50 nC 1 r1 0 c1 42 r2 0 c2 62 r3 0 c3 83 r4 0 c4 104",
            "0 sym   arr 2 row 0 col 20 nR 50 nC 1 r1 0 c1 42 r2 0 c2 62 r3 0 c3 83 r4 0 c4 104",
            "",
            "",
            "",
            "",
            ""
        ];

        vm.prank(_owner);
        _nftContract.addGalleryItem(0, galleryInstructions);

        // _owner reveals genesis gallery
        vm.prank(_owner);
        _nftContract.revealGallery(0, "Genesis", 0);
        assertEq(_nftContract.isGalleryRevealed(0), true);

        // _owner mints an nft
        vm.prank(_owner);
        _nftContract.mintAdmin(1);

        // _owner toggles early
        assertEq(_nftContract.earlyMintActive(), false);
        vm.prank(_owner);
        _nftContract.toggleEarly();
        assertEq(_nftContract.earlyMintActive(), true);

        // _owner toggles public
        assertEq(_nftContract.publicMintActive(), false);
        vm.prank(_owner);
        _nftContract.togglePublic();
        assertEq(_nftContract.publicMintActive(), true);
    }

    function testAddProgram() public {
        address programContractAddress = address(_programContract);
        assertEq(_nftContract.programAddresses(0), programContractAddress);
    }

    function testMint() public {
        assertEq(_nftContract.balanceOf(_minter), 0);
        vm.prank(_minter);
        _nftContract.mint{value: 0.068 ether}(1);
        assertEq(_nftContract.balanceOf(_minter), 1);
    }

    // ------------------------------------------------------------------------
    // GALLERY TOKENURI
    // ------------------------------------------------------------------------

    function testGetGalleryTokenURI() public {
        string memory tokenURI = _nftContract.tokenURI(1);
        emit log(" ");
        emit log("Gallery Artwork:");
        emit log(" ");
        emit log(tokenURI);
    }

    // ------------------------------------------------------------------------
    // GFX MODULES
    // ------------------------------------------------------------------------

    function testListGFXModule() public {
        vm.prank(_moduleDev);
        // Hypercastle Zones needs to be listed as first module
        _nftContract.listGfxModule(
            "Hypercastle Zones",
            address(_hypercastleZonesContract),
            0.036 ether
        );

        assertEq(
            _nftContract.gfxModuleAddresses(0),
            address(_hypercastleZonesContract)
        );

        // NOTE: list your gfx module
        _nftContract.listGfxModule(
            "PRESET #HEXPLOIT",
            address(_presetHexploitContract),
            0 ether
        );

        assertEq(
            _nftContract.gfxModuleAddresses(1),
            address(_presetHexploitContract)
        );
    }

    function testGetGalleryWithModuleTokenURI() public {
        // list the gfx module
        testListGFXModule();

        // run the gfx module on a token
        vm.prank(_owner);
        // NOTE: change gfx module inputs here
        _nftContract.setTokenGfxModule(
            1,
            address(_presetHexploitContract),
            3,
            ""
        );

        string memory tokenURI = _nftContract.tokenURI(1);
        emit log(" ");
        emit log("Gallery Artwork + GFX Module:");
        emit log(" ");
        emit log(tokenURI);
    }
}
