// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "src/PythAggregatorV3.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {console2 as console} from "forge-std/console2.sol";

/**
 * @title PythAdapterFactory
 * @notice Factory contract for deploying new PythAggregatorV3 instances
 * @dev This factory allows for easy deployment of new price feed adapters
 */
contract PythAdapterFactory is AccessControl {
    // Role definitions
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Events
    event AdapterDeployed(address indexed adapter, address indexed asset, bytes32 indexed priceId, string description);

    // State variables
    address public immutable pythPriceFeedsContract;
    mapping(bytes32 => address) public feedIdToAdapter;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller must be admin");
        _;
    }

    modifier onlyAdminOrDeployer() {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(DEPLOYER_ROLE, msg.sender)
                || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must be admin or deployer"
        );
        _;
    }

    /**
     * @notice Constructor sets the Pyth price feeds contract address and initializes roles
     * @param _pythPriceFeedsContract The address of the Pyth price feeds contract
     */
    constructor(
        address _pythPriceFeedsContract,
        address[] memory assets,
        bytes32[] memory priceIds,
        string[] memory descriptions
    ) {
        require(_pythPriceFeedsContract != address(0), "Invalid Pyth contract");
        pythPriceFeedsContract = _pythPriceFeedsContract;

        // Set up role admin
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Deploy initial adapters
        batchDeployPythAdapters(priceIds, assets, descriptions);
    }

    /**
     * @notice Deploys a new PythAggregatorV3 instance for a given price feed
     * @param priceId The Pyth price feed ID
     * @param description A description of the price feed being deployed
     * @return adapter The address of the newly deployed adapter
     */
    function deployPythAdapter(bytes32 priceId, address asset, string memory description)
        public
        onlyAdminOrDeployer
        returns (address adapter)
    {
        require(feedIdToAdapter[priceId] == address(0), "Adapter already exists");

        // Deploy new adapter
        PythAggregatorV3 newAdapter = new PythAggregatorV3(pythPriceFeedsContract, priceId, description);

        // Store the adapter address
        adapter = address(newAdapter);
        feedIdToAdapter[priceId] = adapter;

        newAdapter.latestAnswer();
        newAdapter.decimals();

        // Emit deployment event
        emit AdapterDeployed(adapter, asset, priceId, description);
    }

    /**
     * @notice Batch deploys multiple PythAggregatorV3 instances
     * @param priceIds Array of Pyth price feed IDs
     * @param descriptions Array of descriptions for each price feed
     * @return adapters Array of deployed adapter addresses
     */
    function batchDeployPythAdapters(bytes32[] memory priceIds, address[] memory assets, string[] memory descriptions)
        public
        onlyAdminOrDeployer
        returns (address[] memory adapters)
    {
        require(priceIds.length == descriptions.length, "Arrays length mismatch");

        adapters = new address[](priceIds.length);

        console.log("Deploying %d adapters", priceIds.length);

        for (uint256 i = 0; i < priceIds.length; i++) {
            adapters[i] = deployPythAdapter(priceIds[i], assets[i], descriptions[i]);
        }
    }

    /**
     * @notice Checks if an adapter exists for a given price feed ID
     * @param priceId The Pyth price feed ID to check
     * @return exists Whether the adapter exists
     * @return adapter The adapter address (zero address if it doesn't exist)
     */
    function adapterExists(bytes32 priceId) external view returns (bool exists, address adapter) {
        adapter = feedIdToAdapter[priceId];
        exists = adapter != address(0);
    }
}
