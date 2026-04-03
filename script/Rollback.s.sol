// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VersionedBeacon} from "../src/VersionedBeacon.sol";

contract RollbackScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address beaconAddress = vm.envAddress("BEACON_ADDRESS");
        uint256 targetVersion = vm.envUint("TARGET_VERSION");

        vm.startBroadcast(deployerPrivateKey);

        VersionedBeacon beacon = VersionedBeacon(beaconAddress);

        console.log("Current version index:", beacon.currentVersionIndex());
        console.log("Rolling back to version:", targetVersion);

        beacon.rollbackTo(targetVersion);

        console.log("Rollback successful. New version index:", beacon.currentVersionIndex());

        vm.stopBroadcast();
    }
}
