// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title OracleMonitor
 * @notice Monitors oracle status from Aave v3 and Fraxlend deployments
 * @dev Provides status reporting for all assets/pairs dynamically
 */
contract OracleMonitor is AccessControl {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Structs
    struct OracleStatus {
        address asset;
        string source; // "aave" or "fraxlend"
        bool isHealthy;
        uint256 lastUpdateTime;
        int256 latestPrice;
        uint8 decimals;
        string status;
    }

    // State variables
    address public aaveAddressesProvider;
    address public fraxlendRegistry;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller must be admin");
        _;
    }

    constructor(address _aaveAddressesProvider, address _fraxlendRegistry) {
        require(_aaveAddressesProvider != address(0), "Invalid Aave provider");
        require(_fraxlendRegistry != address(0), "Invalid Fraxlend registry");

        aaveAddressesProvider = _aaveAddressesProvider;
        fraxlendRegistry = _fraxlendRegistry;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Get status for all assets from Aave and Fraxlend
     * @return statuses Array of OracleStatus structs
     */
    function getAssetStatuses() external view returns (OracleStatus[] memory statuses) {
        // Get Aave assets
        OracleStatus[] memory aaveStatuses = _getAaveAssetStatuses();

        // Get Fraxlend assets
        OracleStatus[] memory fraxlendStatuses = _getFraxlendAssetStatuses();

        // Combine arrays
        uint256 totalLength = aaveStatuses.length + fraxlendStatuses.length;
        statuses = new OracleStatus[](totalLength);

        // Copy Aave statuses
        for (uint256 i = 0; i < aaveStatuses.length; i++) {
            statuses[i] = aaveStatuses[i];
        }

        // Copy Fraxlend statuses
        for (uint256 i = 0; i < fraxlendStatuses.length; i++) {
            statuses[aaveStatuses.length + i] = fraxlendStatuses[i];
        }
    }

    /**
     * @notice Get status for all Aave assets
     * @return statuses Array of OracleStatus structs
     */
    function _getAaveAssetStatuses() internal view returns (OracleStatus[] memory statuses) {
        try IPoolAddressesProvider(aaveAddressesProvider).getPool() returns (address pool) {
            try IAavePool(pool).getReservesList() returns (address[] memory reserves) {
                statuses = new OracleStatus[](reserves.length);

                address oracle = IPoolAddressesProvider(aaveAddressesProvider).getPriceOracle();

                for (uint256 i = 0; i < reserves.length; i++) {
                    address asset = reserves[i];

                    OracleStatus memory status = OracleStatus({
                        asset: asset,
                        source: "aave",
                        isHealthy: false,
                        lastUpdateTime: 0,
                        latestPrice: 0,
                        decimals: 8,
                        status: "UNKNOWN"
                    });

                    try IAaveOracle(oracle).getAssetPrice(asset) returns (uint256 price) {
                        status.latestPrice = int256(price);
                        status.isHealthy = price > 0;
                        status.lastUpdateTime = block.timestamp;
                        status.status = price > 0 ? "HEALTHY" : "UNHEALTHY";
                    } catch {
                        status.status = "ERROR";
                    }

                    statuses[i] = status;
                }
            } catch {
                statuses = new OracleStatus[](0);
            }
        } catch {
            statuses = new OracleStatus[](0);
        }
    }

    /**
     * @notice Get status for all Fraxlend assets
     * @return statuses Array of OracleStatus structs
     */
    function _getFraxlendAssetStatuses() internal view returns (OracleStatus[] memory statuses) {
        try IFraxlendRegistry(fraxlendRegistry).getAllPairs() returns (address[] memory pairs) {
            statuses = new OracleStatus[](pairs.length);

            for (uint256 i = 0; i < pairs.length; i++) {
                address pair = pairs[i];

                try IFraxlendPair(pair).asset() returns (address asset) {
                    try IFraxlendPair(pair).oracle() returns (address oracle) {
                        OracleStatus memory status = OracleStatus({
                            asset: asset,
                            source: "fraxlend",
                            isHealthy: false,
                            lastUpdateTime: 0,
                            latestPrice: 0,
                            decimals: 0,
                            status: "UNKNOWN"
                        });

                        try IFraxlendOracle(oracle).getPrice() returns (uint256 price) {
                            try IFraxlendOracle(oracle).decimals() returns (uint8 decimals) {
                                status.latestPrice = int256(price);
                                status.decimals = decimals;
                                status.isHealthy = price > 0;
                                status.lastUpdateTime = block.timestamp;
                                status.status = price > 0 ? "HEALTHY" : "UNHEALTHY";
                            } catch {
                                status.status = "ERROR";
                            }
                        } catch {
                            status.status = "ERROR";
                        }

                        statuses[i] = status;
                    } catch {
                        // Skip this pair if oracle call fails
                        statuses[i] = OracleStatus({
                            asset: asset,
                            source: "fraxlend",
                            isHealthy: false,
                            lastUpdateTime: 0,
                            latestPrice: 0,
                            decimals: 0,
                            status: "ERROR"
                        });
                    }
                } catch {
                    // Skip this pair if asset call fails
                    statuses[i] = OracleStatus({
                        asset: address(0),
                        source: "fraxlend",
                        isHealthy: false,
                        lastUpdateTime: 0,
                        latestPrice: 0,
                        decimals: 0,
                        status: "ERROR"
                    });
                }
            }
        } catch {
            statuses = new OracleStatus[](0);
        }
    }

    /**
     * @notice Get status for a specific asset (searches both Aave and Fraxlend)
     * @param asset Asset address
     * @return status OracleStatus struct
     */
    function getAssetStatus(address asset) external view returns (OracleStatus memory status) {
        // Check Aave first
        try IPoolAddressesProvider(aaveAddressesProvider).getPool() returns (address pool) {
            try IAavePool(pool).getReservesList() returns (address[] memory reserves) {
                for (uint256 i = 0; i < reserves.length; i++) {
                    if (reserves[i] == asset) {
                        return _getAaveAssetStatus(asset);
                    }
                }
            } catch {}
        } catch {}

        // Check Fraxlend
        try IFraxlendRegistry(fraxlendRegistry).getAllPairs() returns (address[] memory pairs) {
            for (uint256 i = 0; i < pairs.length; i++) {
                try IFraxlendPair(pairs[i]).asset() returns (address pairAsset) {
                    if (pairAsset == asset) {
                        return _getFraxlendAssetStatus(pairs[i], asset);
                    }
                } catch {}
            }
        } catch {}

        revert("Asset not found in Aave or Fraxlend");
    }

    /**
     * @notice Get Aave asset status
     * @param asset Asset address
     * @return status OracleStatus struct
     */
    function _getAaveAssetStatus(address asset) internal view returns (OracleStatus memory status) {
        address oracle = IPoolAddressesProvider(aaveAddressesProvider).getPriceOracle();

        status = OracleStatus({
            asset: asset,
            source: "aave",
            isHealthy: false,
            lastUpdateTime: 0,
            latestPrice: 0,
            decimals: 8,
            status: "UNKNOWN"
        });

        try IAaveOracle(oracle).getAssetPrice(asset) returns (uint256 price) {
            status.latestPrice = int256(price);
            status.isHealthy = price > 0;
            status.lastUpdateTime = block.timestamp;
            status.status = price > 0 ? "HEALTHY" : "UNHEALTHY";
        } catch {
            status.status = "ERROR";
        }
    }

    /**
     * @notice Get Fraxlend asset status
     * @param pair Pair address
     * @param asset Asset address
     * @return status OracleStatus struct
     */
    function _getFraxlendAssetStatus(address pair, address asset) internal view returns (OracleStatus memory status) {
        try IFraxlendPair(pair).oracle() returns (address oracle) {
            status = OracleStatus({
                asset: asset,
                source: "fraxlend",
                isHealthy: false,
                lastUpdateTime: 0,
                latestPrice: 0,
                decimals: 0,
                status: "UNKNOWN"
            });

            try IFraxlendOracle(oracle).getPrice() returns (uint256 price) {
                try IFraxlendOracle(oracle).decimals() returns (uint8 decimals) {
                    status.latestPrice = int256(price);
                    status.decimals = decimals;
                    status.isHealthy = price > 0;
                    status.lastUpdateTime = block.timestamp;
                    status.status = price > 0 ? "HEALTHY" : "UNHEALTHY";
                } catch {
                    status.status = "ERROR";
                }
            } catch {
                status.status = "ERROR";
            }
        } catch {
            status = OracleStatus({
                asset: asset,
                source: "fraxlend",
                isHealthy: false,
                lastUpdateTime: 0,
                latestPrice: 0,
                decimals: 0,
                status: "ERROR"
            });
        }
    }

    /**
     * @notice Update Aave addresses provider
     * @param _aaveAddressesProvider New Aave addresses provider
     */
    function setAaveAddressesProvider(address _aaveAddressesProvider) external onlyAdmin {
        require(_aaveAddressesProvider != address(0), "Invalid address");
        aaveAddressesProvider = _aaveAddressesProvider;
    }

    /**
     * @notice Update Fraxlend registry
     * @param _fraxlendRegistry New Fraxlend registry
     */
    function setFraxlendRegistry(address _fraxlendRegistry) external onlyAdmin {
        require(_fraxlendRegistry != address(0), "Invalid address");
        fraxlendRegistry = _fraxlendRegistry;
    }
}

// Aave v3 interfaces
interface IPoolAddressesProvider {
    function getPriceOracle() external view returns (address);
    function getPool() external view returns (address);
}

interface IAavePool {
    function getReservesList() external view returns (address[] memory);
}

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

// Fraxlend interfaces
interface IFraxlendRegistry {
    function getPair(address asset, address collateral) external view returns (address pair);
    function getAllPairs() external view returns (address[] memory);
}

interface IFraxlendPair {
    function oracle() external view returns (address);
    function asset() external view returns (address);
    function collateral() external view returns (address);
}

interface IFraxlendOracle {
    function getPrice() external view returns (uint256);
    function decimals() external view returns (uint8);
}
