// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../structs/Structs.sol";

interface IShopPayment {
    function purchaseProduct(
        uint256 id,
        bool isAffiliate,
        uint256 amount
    ) external payable;

    function purchaseProductFor(
        address receiver,
        uint256 id,
        bool isAffiliate,
        uint256 amount
    ) external payable;

    function getProduct(
        uint256 productId
    ) external view returns (Product memory);
    function getProductViaAffiliateId(
        uint256 affiliateId
    ) external view returns (Product memory);
}

/**
 * @title Droplinked Payment Proxy
 * @dev This contract provides a payment proxy system with chainlink price feeds for purchasing products.
 * It supports handling purchases with different payment methods and affiliate tracking.
 */
contract DroplinkedPaymentProxy is Ownable {
    /// @dev Error for reporting outdated price data.
    error oldPrice(uint256 priceTimestamp, uint256 currentTimestamp);

    event ProductPurchased(string memo);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Converts the given value to the native price using the provided ratio.
     * @param value The value to convert.
     * @param ratio The conversion ratio.
     * @return The converted value.
     */
    function toNativePrice(uint value, uint ratio) private pure returns (uint) {
        return (1e24 * value) / ratio;
    }

    /**
     * @dev Handles the transfer of value-based debts (TBD) to the specified recipients.
     * @param tbdValues The values to transfer.
     * @param tbdReceivers The recipients of the values.
     * @param ratio The price ratio for conversion if needed.
     * @param currency The currency in which the values are denominated.
     * @return The total value transferred.
     */
    function transferTBDValues(
        uint[] memory tbdValues,
        address[] memory tbdReceivers,
        uint ratio,
        address currency
    ) private returns (uint) {
        uint currentValue = 0;
        for (uint i = 0; i < tbdReceivers.length; i++) {
            uint value = currency == address(0)
                ? toNativePrice(tbdValues[i], ratio)
                : tbdValues[i];
            if (currency == address(1)) value = tbdValues[i];
            currentValue += value;
            if (currency != address(0) && currency != address(1)) {
                require(
                    IERC20(currency).transferFrom(
                        msg.sender,
                        tbdReceivers[i],
                        value
                    ),
                    "transferFrom failed"
                );
            } else {
                payable(tbdReceivers[i]).transfer(value);
            }
        }
        return currentValue;
    }

    /**
     * @dev Processes a batch of purchases, transferring the required funds and making the product purchase calls.
     * @param tbdValues Values of products to be transferred.
     * @param tbdReceivers Receivers of the payments.
     * @param cartItems List of items being purchased.
     * @param currency The currency used for the purchase.
     */
    function droplinkedPurchase(
        uint[] memory tbdValues,
        address[] memory tbdReceivers,
        PurchaseData[] memory cartItems,
        address currency,
        string memory memo
    ) public payable {
        uint ratio = 0;
        if (currency == address(0)) {
            revert("Native currency is not supported on skale");
        }
        transferTBDValues(tbdValues, tbdReceivers, ratio, currency);
        // note: we can't have multiple products with different payment methods in the same purchase!
        for (uint i = 0; i < cartItems.length; i++) {
            uint id = cartItems[i].id;
            bool isAffiliate = cartItems[i].isAffiliate;
            uint amount = cartItems[i].amount;
            address shopAddress = cartItems[i].shopAddress;
            IShopPayment cartItemShop = IShopPayment(shopAddress);
            Product memory product;
            if (isAffiliate) {
                product = cartItemShop.getProductViaAffiliateId(id);
            } else {
                product = cartItemShop.getProduct(id);
            }
            uint finalPrice = calculateFinalPrice(
                product.paymentInfo.price,
                amount,
                currency,
                ratio
            );
            transferPayment(finalPrice, currency, shopAddress);
            purchaseProduct(
                finalPrice,
                id,
                isAffiliate,
                amount,
                shopAddress,
                currency
            );
        }
        emit ProductPurchased(memo);
    }

    function calculateFinalPrice(
        uint price,
        uint amount,
        address currency,
        uint ratio
    ) private pure returns (uint) {
        uint finalPrice = price * amount;
        if (currency == address(0)) {
            finalPrice = toNativePrice(finalPrice, ratio);
        }
        return finalPrice;
    }

    function transferPayment(
        uint finalPrice,
        address currency,
        address shopAddress
    ) private {
        if (currency != address(0) && currency != address(1)) {
            require(
                IERC20(currency).transferFrom(
                    msg.sender,
                    address(this),
                    finalPrice
                ),
                "transfer failed"
            );
            IERC20(currency).approve(shopAddress, finalPrice);
        }
    }

    function purchaseProduct(
        uint finalPrice,
        uint id,
        bool isAffiliate,
        uint amount,
        address shopAddress,
        address currency
    ) private {
        if (currency == address(0) || currency == address(1)) {
            IShopPayment(shopAddress).purchaseProductFor{value: finalPrice}(
                msg.sender,
                id,
                isAffiliate,
                amount
            );
        } else {
            IShopPayment(shopAddress).purchaseProductFor(
                msg.sender,
                id,
                isAffiliate,
                amount
            );
        }
    }
}
