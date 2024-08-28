// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../structs/Structs.sol";

contract DroplinkedToken721 is ERC721URIStorage, Ownable {
    event ManageWalletUpdated(address newManagedWallet);
    event FeeUpdated(uint256 newFee);
    error StringSizeLimit();

    address public operatorContract;
    uint256 public totalSupply;
    uint256 public fee;
    uint256 public tokenCnt;
    address public managedWallet = 0x8c906310C5F64fe338e27Bd9fEf845B286d0fc1e;
    uint256 constant MAX_STRING_LENGTH = 200;

    mapping(address => bool) public minterAddresses;
    mapping(bytes32 => uint256) public tokenIdByHash;
    mapping(uint256 => uint256) public tokenCnts;
    mapping(uint256 => Issuer) public issuers;

    constructor(
        address _droplinkedOperator
    ) Ownable(tx.origin) ERC721("DropCollection", "DRP") {
        fee = 100;
        operatorContract = _droplinkedOperator;
        minterAddresses[operatorContract] = true;
    }

    modifier onlyOperator() {
        require(
            msg.sender == operatorContract,
            "Only the operator can call this contract"
        );
        _;
    }

    modifier checkStringSize(string memory input) {
        if (bytes(input).length > MAX_STRING_LENGTH) revert StringSizeLimit();
        _;
    }

    modifier onlyMinter() {
        require(
            minterAddresses[msg.sender],
            "Only Minters can call Mint Function"
        );
        _;
    }

    function changeOperator(
        address _newOperatorContract
    ) external onlyOperator {
        operatorContract = _newOperatorContract;
    }

    function setMinter(address _minter, bool _state) external onlyOperator {
        minterAddresses[_minter] = _state;
    }

    function setManagedWallet(address _newManagedWallet) external onlyOwner {
        managedWallet = _newManagedWallet;
        emit ManageWalletUpdated(_newManagedWallet);
    }

    function setFee(uint256 _fee) external onlyOperator {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory
    ) public virtual override(ERC721, IERC721) {
        if (msg.sender != operatorContract) {
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC721: caller is not token owner or approved"
            );
        }
        _safeTransfer(from, to, id);
    }

    function mint(
        string calldata _uri,
        address receiver,
        uint256 royalty,
        bool accepted
    ) external onlyMinter checkStringSize(_uri) returns (uint256) {
        bytes32 metadata_hash = keccak256(abi.encode(_uri));
        uint256 tokenId = tokenIdByHash[metadata_hash];
        if (tokenId == 0) {
            tokenId = tokenCnt + 1;
            tokenCnt++;
            tokenIdByHash[metadata_hash] = tokenId;
            issuers[tokenId].issuer = receiver;
            issuers[tokenId].royalty = royalty;
        }
        totalSupply += 1;
        tokenCnts[tokenId] += 1;
        _mint(receiver, tokenId);
        if (minterAddresses[msg.sender]) {
            _setApprovalForAll(receiver, msg.sender, true);
        }
        if (msg.sender == operatorContract) {
            _setApprovalForAll(receiver, operatorContract, true);
            if (accepted) _setApprovalForAll(receiver, managedWallet, true);
        }
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function droplinkedSafeBatchTransferFrom(
        address from,
        address[] memory to,
        uint256[] memory ids
    ) external {
        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(from, to[i], ids[i], "");
        }
    }
}
