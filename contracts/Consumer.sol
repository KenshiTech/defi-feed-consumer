// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

interface DeFiFeed {
    struct Route {
        address token;
        address pair;
    }

    function priceOf(address token) external view returns (uint256);

    function priceFromCustomRoute(address token, Route[] memory route)
        external
        view
        returns (uint256);
}

contract DeFiFeedConsumer {
    struct Quote {
        uint256 price;
        uint256 blockNumber;
    }

    mapping(address => Quote[]) private _quotes;
    address private _defiFeedAddress;

    constructor() {}

    function filterExpiredQuotes(address token, uint256 fromBlock) internal {
        for (uint256 i = 0; i < _quotes[token].length; i++) {
            if (_quotes[token][i].blockNumber <= fromBlock) {
                _quotes[token][i] = _quotes[token][_quotes[token].length - 1];
                _quotes[token].pop();
            }
        }
    }

    function setDeFiFeedAddress(address addr) internal {
        _defiFeedAddress = addr;
    }

    /**
     * @dev Get current price of `token`
     *
     * In most cases you should use one of the other functions,
     * use this if you need to implement your own custom logic on
     * top of the raw price data.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `token` must be supported by the Kenshi DeFi feed oracle.
     */
    function getTokenPrice(address token) internal view returns (uint256) {
        return DeFiFeed(_defiFeedAddress).priceOf(token);
    }

    /**
     * @dev Get current price of `token`, following `route`.
     *
     * In most cases you should use one of the other functions,
     * use this if you need to implement your own custom logic on
     * top of the raw price data.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `route` should be a valid DEX route
     */
    function getTokenPrice(address token, DeFiFeed.Route[] memory route)
        internal
        view
        returns (uint256)
    {
        return DeFiFeed(_defiFeedAddress).priceFromCustomRoute(token, route);
    }

    function readTokenPriceIntoCache(address token) internal {
        uint256 price = getTokenPrice(token);
        _quotes[token].push(Quote(price, block.number));
    }

    function readTokenPriceIntoCache(
        address token,
        DeFiFeed.Route[] memory route
    ) internal {
        uint256 price = getTokenPrice(token, route);
        _quotes[token].push(Quote(price, block.number));
    }

    /**
     * @dev Get `percent`th percentile of `token` prie, querying back
     * `maxBlocks`. Percentile is calculated from `maxQuoteCount` samples.
     *
     * This function gets the price of the `token` from the Kenshi
     * DeFi Feed oracle, stores it in the samples array, and returns
     * the `percent`th percentile of the samples.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `token` must be supported by the Kenshi DeFi feed oracle.
     * - `percent` must be between 0 and 100
     * - `maxBlock` should be bigger than 0
     * - `maxQuoteCount` should be bigger than 0
     */
    function getTokenPriceByPercentile(
        address token,
        uint256 percent,
        uint256 maxBlocks,
        uint256 maxQuoteCount
    ) internal returns (uint256) {
        readTokenPriceIntoCache(token);
        return
            _getTokenPriceByPercentile(
                token,
                percent,
                maxBlocks,
                maxQuoteCount
            );
    }

    /**
     * @dev Get `percent`th percentile of `token` prie, querying back
     * `maxBlocks`, following `route`. Percentile is calculated from
     * `maxQuoteCount` samples.
     *
     * This function gets the price of the `token` from the Kenshi
     * DeFi Feed oracle, stores it in the samples array, and returns
     * the `percent`th percentile of the samples.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `percent` must be between 0 and 100
     * - `maxBlock` should be bigger than 0
     * - `maxQuoteCount` should be bigger than 0
     * - `route` should be avalid DEX route
     */
    function getTokenPriceByPercentile(
        address token,
        uint256 percent,
        uint256 maxBlocks,
        uint256 maxQuoteCount,
        DeFiFeed.Route[] memory route
    ) internal returns (uint256) {
        readTokenPriceIntoCache(token, route);
        return
            _getTokenPriceByPercentile(
                token,
                percent,
                maxBlocks,
                maxQuoteCount
            );
    }

    function _getTokenPriceByPercentile(
        address token,
        uint256 percent,
        uint256 maxBlocks,
        uint256 maxQuoteCount
    ) internal returns (uint256) {
        filterExpiredQuotes(token, block.number - maxBlocks);
        sortQuotes(token, false);

        uint256 start = _quotes[token].length > maxQuoteCount
            ? _quotes[token].length - maxQuoteCount
            : 0;

        uint256 index = start +
            ((_quotes[token].length - start) * percent) /
            100;

        return _quotes[token][index].price;
    }

    /**
     * @dev Get average price of `token`, querying back `maxBlocks`.
     * Average is calculated from `maxQuoteCount` samples.
     *
     * This function gets the price of the `token` from the Kenshi
     * DeFi Feed oracle, stores it in the samples array, and returns
     * the average of the samples.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `token` must be supported by the Kenshi DeFi feed oracle.
     * - `maxBlock` should be bigger than 0
     * - `maxQuoteCount` should be bigger than 0
     */
    function getTokenPriceByAverage(
        address token,
        uint256 maxBlocks,
        uint256 maxQuoteCount
    ) internal returns (uint256) {
        readTokenPriceIntoCache(token);
        return _getTokenPriceByAverage(token, maxBlocks, maxQuoteCount);
    }

    /**
     * @dev Get average price of `token`, querying back `maxBlocks`,
     * following `route`. Average is calculated from `maxQuoteCount` samples.
     *
     * This function gets the price of the `token` from the Kenshi
     * DeFi Feed oracle, stores it in the samples array, and returns
     * the average of the samples.
     *
     * NOTE: The returned price has 18 decimal places.
     *
     * Requirements:
     *
     * - `maxBlock` should be bigger than 0
     * - `maxQuoteCount` should be bigger than 0
     * - `route` should be a valid DEX route
     */
    function getTokenPriceByAverage(
        address token,
        uint256 maxBlocks,
        uint256 maxQuoteCount,
        DeFiFeed.Route[] memory route
    ) internal returns (uint256) {
        readTokenPriceIntoCache(token, route);
        return _getTokenPriceByAverage(token, maxBlocks, maxQuoteCount);
    }

    function _getTokenPriceByAverage(
        address token,
        uint256 maxBlocks,
        uint256 maxQuoteCount
    ) internal returns (uint256) {
        filterExpiredQuotes(token, block.number - maxBlocks);
        sortQuotes(token, true);

        uint256 sum = 0;
        uint256 start = _quotes[token].length > maxQuoteCount
            ? _quotes[token].length - maxQuoteCount
            : 0;

        for (uint256 i = start; i < _quotes[token].length; i++) {
            sum += _quotes[token][i].price;
        }

        return sum / (_quotes[token].length - start);
    }

    function sortQuotes(address token, bool byBlockNumber) internal {
        quickSortQuotes(
            token,
            int256(0),
            int256(_quotes[token].length - 1),
            byBlockNumber
        );
    }

    function quickSortQuotes(
        address token,
        int256 left,
        int256 right,
        bool byBlockNumber
    ) internal {
        int256 i = left;
        int256 j = right;

        if (i == j) {
            return;
        }

        Quote memory pivot = _quotes[token][uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (
                quickSortGetValue(_quotes[token][uint256(i)], byBlockNumber) <
                quickSortGetValue(pivot, byBlockNumber)
            ) {
                i++;
            }

            while (
                quickSortGetValue(pivot, byBlockNumber) <
                quickSortGetValue(_quotes[token][uint256(j)], byBlockNumber)
            ) {
                j--;
            }

            if (i <= j) {
                Quote memory temp = _quotes[token][uint256(i)];
                _quotes[token][uint256(i)] = _quotes[token][uint256(j)];
                _quotes[token][uint256(j)] = temp;
                i++;
                j--;
            }
        }

        if (left < j) {
            quickSortQuotes(token, left, j, byBlockNumber);
        }

        if (i < right) {
            quickSortQuotes(token, i, right, byBlockNumber);
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
