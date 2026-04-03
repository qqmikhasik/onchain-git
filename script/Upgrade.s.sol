// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VersionedBeacon} from "../src/VersionedBeacon.sol";
import {TokenV2} from "../src/TokenV2.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address beaconAddress = vm.envAddress("BEACON_ADDRESS");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        TokenV2 implV2 = new TokenV2();
        console.log("TokenV2 implementation:", address(implV2));

        VersionedBeacon beacon = VersionedBeacon(beaconAddress);
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee (1%)");
        console.log("Upgraded to V2. Version count:", beacon.getVersionCount());

        TokenV2(proxyAddress).initializeV2(100, treasury);
        console.log("V2 initialized with fee: 1%, treasury:", treasury);

        vm.stopBroadcast();
    }
}
