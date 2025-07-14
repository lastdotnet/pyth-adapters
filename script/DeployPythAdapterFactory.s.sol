// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/PythAdapterFactory.sol";
import {console} from "forge-std/console.sol";

contract DeployPythAdapterFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the address for your ecosystem from:
        // https://docs.pyth.network/price-feeds/contract-addresses/evm
        address pythPriceFeedsContract = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;

        // Optional: Deploy some initial adapters
        bytes32[] memory priceIds = new bytes32[](14);
        address[] memory assets = new address[](14);
        string[] memory descriptions = new string[](14);

        // Example price feeds
        priceIds[0] = 0x4279e31cc369bbcc2faf022b382b080e32a8e689ff20fbc530d2a603eb6cd98b; // WHYPE/USD
        priceIds[1] = 0x9e3cadc2a8a0ebfd765b34d5ee5de77a4add3114672fc0b8d3ad09ac56940069; // LHYPE/USD
        priceIds[2] = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43; // UBTC/USD
        priceIds[3] = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; // UETH/USD
        priceIds[4] = 0xe10593860e9ee1c204e4f9569e877502f098dd1a4d84cc5bad06f23f77dcbfe2; // USDXL/USD
        priceIds[5] = 0xe0154bf4dfbcf835fad3428c0d8c1078b83f687e4d6afafb827f7f9af70ec326; // PURR/USD
        priceIds[6] = 0x61db931fcfd322223fb84dc4bfc9c6481bd5610a31403782bc396df213e3ce12; // HFUN/USD
        priceIds[7] = 0x6ec879b1e9963de5ee97e9c8710b742d6228252a5e2ca12d4ae81d7fe5ee8c5d; // USDe/USD
        priceIds[8] = 0xe35aebd2d35795acaa2b0e59f3b498510e8ef334986d151d1502adb9e26234f7; // mHYPE/HYPE
        priceIds[9] = 0x7f2e9a7365eb634c543e9ca72683a9cf778cdc16ee5b8bca73abe6d08c1410d5; // feUSD/USD
        priceIds[10] = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b; // USDT0/USD
        priceIds[11] = 0xcef5ad3be493afef85e77267cb0c07d048f3d54055409a34782996607e48cf0a; // cmETH/mETH RR
        priceIds[12] = 0xee279eeb2fec830e3f535ad4d6524eb35eb1c6890cb1afc0b64554d08c88727e; // mETH/ETH RR
        priceIds[13] = 0x983b7cabc6fab548e15a5b05500da9b99c1682107b3e2ff289344116c10ac02c; // WHYPE/USD

        assets[0] = 0x5555555555555555555555555555555555555555;
        assets[1] = 0x5748ae796AE46A4F1348a1693de4b50560485562;
        assets[2] = 0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463;
        assets[3] = 0xBe6727B535545C67d5cAa73dEa54865B92CF7907;
        assets[4] = 0xca79db4B49f608eF54a5CB813FbEd3a6387bC645;
        assets[5] = 0x9b498C3c8A0b8CD8BA1D9851d40D186F1872b44E;
        assets[6] = 0xa320D9f65ec992EfF38622c63627856382Db726c;
        assets[7] = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
        assets[8] = 0x0000000000000000000000000000000000000000;
        assets[9] = 0x02c6a2fA58cC01A18B8D9E00eA48d65E4dF26c70;
        assets[10] = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
        assets[11] = 0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA; // cmETH
        assets[12] = 0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA; // cmETH
        assets[13] = 0xfD739d4e423301CE9385c1fb8850539D657C296D; // KHYPE

        descriptions[0] = "WHYPE/USD Oracle";
        descriptions[1] = "LHYPE/USD Oracle";
        descriptions[2] = "UBTC/USD Oracle";
        descriptions[3] = "UETH/USD Oracle";
        descriptions[4] = "USDXL/USD Oracle";
        descriptions[5] = "PURR/USD Oracle";
        descriptions[6] = "HFUN/USD Oracle";
        descriptions[7] = "USDe/USD Oracle";
        descriptions[8] = "mHYPE/HYPE Oracle";
        descriptions[9] = "feUSD/USD Oracle";
        descriptions[10] = "USDT/USD Oracle";
        descriptions[11] = "cmETH/mETH RR Oracle";
        descriptions[12] = "mETH/ETH RR Oracle";
        descriptions[13] = "KHYPE/HYPE RR Oracle";

        // Deploy the factory
        new PythAdapterFactory(pythPriceFeedsContract, assets, priceIds, descriptions);

        vm.stopBroadcast();
    }
}
