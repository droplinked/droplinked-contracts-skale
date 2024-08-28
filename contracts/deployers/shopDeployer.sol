// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IDIP1.sol";
import "../tokens/DropERC1155.sol";
import "../base/IDropShop.sol";

/**
 * @title DropShopDeployer
 * @dev Contract for deploying and managing drop shops and NFT contracts.
 */
contract DropShopDeployer is Initializable, AccessControlUpgradeable {
    event ShopDeployed(address shop, address nftContract);
    event DroplinkedFeeUpdated(uint256 newFee);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ALLOW_DEPLOYMENT_ROLE =
        keccak256("ALLOW_DEPLOYMENT_ROLE");

    IDropShop[] public shopAddresses;
    address[] public nftContracts;
    mapping(address => address[]) public shopOwners;
    mapping(address => address[]) public nftOwners;
    uint256 public droplinkedFee;
    address public droplinkedWallet;
    uint public shopCount;

    function initialize(
        address _droplinkedWallet,
        uint256 _droplinkedFee,
        address manager
    ) public initializer {
        __AccessControl_init();

        // Grant MANAGER_ROLE to the deployer (initial admin)
        _grantRole(MANAGER_ROLE, msg.sender);
        // Grant MANAGER_ROLE to the specified manager
        _grantRole(MANAGER_ROLE, manager);
        // Set MANAGER_ROLE as the admin of ALLOW_DEPLOYMENT_ROLE
        _setRoleAdmin(ALLOW_DEPLOYMENT_ROLE, MANAGER_ROLE);

        droplinkedWallet = _droplinkedWallet;
        droplinkedFee = _droplinkedFee;
    }

    function setDroplinkedFee(uint256 newFee) external onlyRole(MANAGER_ROLE) {
        droplinkedFee = newFee;
        emit DroplinkedFeeUpdated(newFee);
    }

    function deployShop(
        bytes memory bytecode,
        bytes32 salt
    )
        external
        onlyRole(ALLOW_DEPLOYMENT_ROLE)
        returns (address shop, address nftContract)
    {
        address deployedShop;
        IDropShop _shop;
        assembly {
            deployedShop := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
            if iszero(extcodesize(deployedShop)) {
                revert(0, 0)
            }
        }
        _shop = IDropShop(deployedShop);
        DroplinkedToken token = new DroplinkedToken(address(this));
        shopOwners[msg.sender].push(deployedShop);
        nftOwners[msg.sender].push(address(token));
        nftContracts.push(address(token));
        shopAddresses.push(_shop);
        token.setMinter(deployedShop, true);
        ++shopCount;
        emit ShopDeployed(deployedShop, address(token));

        // Renounce the ALLOW_DEPLOYMENT_ROLE after deployment
        renounceRole(ALLOW_DEPLOYMENT_ROLE, msg.sender);

        return (deployedShop, address(token));
    }

    function getDroplinkedFee() external view returns (uint256) {
        return droplinkedFee;
    }
}
