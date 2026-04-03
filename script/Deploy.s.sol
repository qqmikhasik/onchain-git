// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {VersionedBeacon} from "../src/VersionedBeacon.sol";
import {TokenV1} from "../src/TokenV1.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        TokenV1 implV1 = new TokenV1();
        console.log("TokenV1 implementation:", address(implV1));

        VersionedBeacon beacon = new VersionedBeacon(address(implV1), deployer, "V1: Basic ERC-20 token");
        console.log("VersionedBeacon:", address(beacon));

        BeaconProxy proxy = new BeaconProxy(address(beacon), abi.encodeCall(TokenV1.initialize, (deployer)));
        console.log("BeaconProxy (token):", address(proxy));

        vm.stopBroadcast();
    }
}
