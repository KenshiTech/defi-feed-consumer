// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

contract DeFiFeedConsumerTest {
    constructor() {}

    struct Quote {
        uint256 price;
        uint256 blockNumber;
    }

    function getTokenPriceByAverage(
        Quote[] memory quotes,
        uint256 maxBlocks,
        uint256 currBlock,
        uint256 maxQuoteCount
    ) external pure returns (uint256) {
        filterExpiredQuotes(quotes, currBlock - maxBlocks);
        sortQuotes(quotes, true);

        uint256 sum = 0;
        uint256 start = quotes.length > maxQuoteCount
            ? quotes.length - maxQuoteCount
            : 0;

        for (uint256 i = start; i < quotes.length; i++) {
            sum += quotes[i].price;
        }

        return sum / (quotes.length - start);
    }

    function getTokenPriceByPercentile(
        Quote[] memory quotes,
        uint256 percent,
        uint256 maxBlocks,
        uint256 currBlock,
        uint256 maxQuoteCount
    ) external pure returns (uint256) {
        filterExpiredQuotes(quotes, currBlock - maxBlocks);
        sortQuotes(quotes, false);

        uint256 start = quotes.length > maxQuoteCount
            ? quotes.length - maxQuoteCount
            : 0;

        uint256 index = start + ((quotes.length - start) * percent) / 100;

        return quotes[index].price;
    }

    function filterExpiredQuotes(Quote[] memory quotes, uint256 fromBlock)
        internal
        pure
    {
        for (uint256 i = 0; i < quotes.length; i++) {
            if (quotes[i].blockNumber <= fromBlock) {
                quotes[i] = quotes[quotes.length - 1];
                //quotes.pop();
                assembly {
                    mstore(quotes, sub(mload(quotes), 1))
                }
            }
        }
    }

    function sortQuotes(Quote[] memory quotes, bool byBlockNumber)
        internal
        pure
    {
        quickSortQuotes(
            quotes,
            int256(0),
            int256(quotes.length - 1),
            byBlockNumber
        );
    }

    function quickSortQuotes(
        Quote[] memory quotes,
        int256 left,
        int256 right,
        bool byBlockNumber
    ) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) {
            return;
        }

        Quote memory pivot = quotes[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (
                quickSortGetValue(quotes[uint256(i)], byBlockNumber) <
                quickSortGetValue(pivot, byBlockNumber)
            ) {
                i++;
            }

            while (
                quickSortGetValue(pivot, byBlockNumber) <
                quickSortGetValue(quotes[uint256(j)], byBlockNumber)
            ) {
                j--;
            }

            if (i <= j) {
                Quote memory temp = quotes[uint256(i)];
                quotes[uint256(i)] = quotes[uint256(j)];
                quotes[uint256(j)] = temp;
                i++;
                j--;
            }
        }

        if (left < j) {
            quickSortQuotes(quotes, left, j, byBlockNumber);
        }

        if (i < right) {
            quickSortQuotes(quotes, i, right, byBlockNumber);
        }
    }

    function quickSortGetValue(Quote memory quote, bool byBlockNumber)
        internal
        pure
        returns (uint256)
    {
        return byBlockNumber ? quote.blockNumber : quote.price;
    }
}
