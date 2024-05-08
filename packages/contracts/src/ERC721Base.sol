// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @author frolic.eth (with modifications from hashrunner.eth)
/// @title  ERC721 base contract
abstract contract ERC721Base is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    uint public immutable price;
    uint public immutable maxSupply;

    mapping(uint => uint) public tokenToPRN;

    bool public operatorFilteringEnabled;

    event Initialized();

    // ------------------------------------------------------------------------
    // INITIALISE
    // ------------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        uint _price,
        uint _maxSupply
    ) Ownable(msg.sender) ERC721A(_name, _symbol) {
        price = _price;
        maxSupply = _maxSupply;
        _setDefaultRoyalty(msg.sender, 200);
        emit Initialized();
    }

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }

    function totalMinted() public view returns (uint) {
        return _totalMinted();
    }

    // ------------------------------------------------------------------------
    // CONDITIONS
    // ------------------------------------------------------------------------

    error MintLimitExceeded(uint limit);
    error MintSupplyExceeded(uint supply);
    error WrongPayment();

    modifier withinMintLimit(uint limit, uint numToBeMinted) {
        if (_numberMinted(_msgSender()) + numToBeMinted > limit) {
            revert MintLimitExceeded(limit);
        }
        _;
    }

    modifier withinSupply(
        uint supply,
        uint numMinted,
        uint numToBeMinted
    ) {
        if (numMinted + numToBeMinted > supply) {
            revert MintSupplyExceeded(supply);
        }
        _;
    }

    modifier withinMaxSupply(uint numToBeMinted) {
        if (_totalMinted() + numToBeMinted > maxSupply) {
            revert MintSupplyExceeded(maxSupply);
        }
        _;
    }

    modifier hasExactPayment(uint numToBeMinted) {
        if (msg.value != price * numToBeMinted) {
            revert WrongPayment();
        }
        _;
    }

    // ------------------------------------------------------------------------
    // MINTING
    // ------------------------------------------------------------------------

    function _mintMany(address to, uint numToBeMinted) internal {
        _mintMany(to, numToBeMinted, "");
    }

    function _mintMany(
        address to,
        uint numToBeMinted,
        bytes memory data
    ) internal withinMaxSupply(numToBeMinted) {
        uint batchSize = 10;
        uint currentTotalMinted = totalMinted();

        for (uint i = 0; i < numToBeMinted; i += batchSize) {
            uint mintAmount = (i + batchSize > numToBeMinted)
                ? numToBeMinted - i
                : batchSize;
            _safeMint(to, mintAmount, data);

            for (uint j = 0; j < mintAmount; ++j) {
                uint tokenId = currentTotalMinted + i + j;
                tokenToPRN[tokenId] = uint(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            to,
                            block.timestamp,
                            block.prevrandao,
                            j
                        )
                    )
                );
            }
        }
    }

    // ------------------------------------------------------------------------
    // ROYALTIES
    // ------------------------------------------------------------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // ------------------------------------------------------------------------
    // ADMIN
    // ------------------------------------------------------------------------

    function withdrawAll() external nonReentrant {
        require(address(this).balance > 0, "ART0x1: zero balance.");
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "ART0x1: failed to withdraw.");
    }

    function withdrawAllERC20(IERC20 token) external nonReentrant {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    // Can be run any time after mint to optimize gas for future transfers
    function normalizeOwnership(uint startTokenId, uint quantity) external {
        for (uint i = 0; i < quantity; i++) {
            _initializeOwnershipAt(startTokenId + i);
        }
    }
}
