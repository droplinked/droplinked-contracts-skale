// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../structs/Structs.sol";

contract DroplinkedToken is ERC1155URIStorage, Ownable {
    event ManageWalletUpdated(address newManagedWallet);
    event FeeUpdated(uint256 newFee);
    error StringSizeLimit();

    address public operatorContract;
    uint256 public totalSupply;
    uint256 public fee;
    string public name = "Droplinked Collection";
    string public symbol = "DROP";
    uint256 public tokenCount;
    address public managedWallet = 0x8c906310C5F64fe338e27Bd9fEf845B286d0fc1e;
    uint256 constant MAX_STRING_LENGTH = 200;
    mapping(address => bool) public minterAddresses;
    mapping(bytes32 => uint256) public tokenIdByHash;
    mapping(uint256 => uint256) public tokenCnts;
    mapping(uint256 => Issuer) public issuers;

    constructor(address _droplinkedOperator) ERC1155("") Ownable(tx.origin) {
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

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (msg.sender != operatorContract) {
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not token owner or approved"
            );
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function mint(
        string calldata _uri,
        uint256 amount,
        address receiver,
        uint256 royalty,
        bool accepted
    ) external onlyMinter checkStringSize(_uri) returns (uint256) {
        bytes32 metadata_hash = keccak256(abi.encode(_uri));
        uint256 tokenId = tokenIdByHash[metadata_hash];
        if (tokenId == 0) {
            tokenId = tokenCount + 1;
            tokenCount++;
            tokenIdByHash[metadata_hash] = tokenId;
            issuers[tokenId].issuer = receiver;
            issuers[tokenId].royalty = royalty;
        }
        totalSupply += amount;
        tokenCnts[tokenId] += amount;
        _mint(receiver, tokenId, amount, "");
        if (minterAddresses[msg.sender]) {
            _setApprovalForAll(receiver, msg.sender, true);
        }
        if (msg.sender == operatorContract) {
            _setApprovalForAll(receiver, operatorContract, true);
            if (accepted) _setApprovalForAll(receiver, managedWallet, true);
        }
        _setURI(tokenId, _uri);
        return tokenId;
    }

    function droplinkedSafeBatchTransferFrom(
        address from,
        address[] memory to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(from, to[i], ids[i], amounts[i], "");
        }
    }
}
