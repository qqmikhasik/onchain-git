// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {VersionedBeacon} from "../src/VersionedBeacon.sol";
import {TokenV1} from "../src/TokenV1.sol";
import {TokenV2} from "../src/TokenV2.sol";
import {TokenV3} from "../src/TokenV3.sol";

contract OnchainGitTest is Test {
    VersionedBeacon public beacon;
    BeaconProxy public proxy;

    TokenV1 public implV1;
    TokenV2 public implV2;
    TokenV3 public implV3;

    address public owner = address(this);
    address public user = address(0xBEEF);
    address public treasury = address(0xFEE);

    function setUp() public {
        implV1 = new TokenV1();
        beacon = new VersionedBeacon(address(implV1), owner, "V1: Basic ERC-20 token");
        proxy = new BeaconProxy(address(beacon), abi.encodeCall(TokenV1.initialize, (owner)));

        implV2 = new TokenV2();
        implV3 = new TokenV3();
    }

    // ═══════════════ HELPERS ════════════════════════════════════

    function tokenV1() internal view returns (TokenV1) {
        return TokenV1(address(proxy));
    }

    function tokenV2() internal view returns (TokenV2) {
        return TokenV2(address(proxy));
    }

    function tokenV3() internal view returns (TokenV3) {
        return TokenV3(address(proxy));
    }

    // ═══════════════ TEST 1: Deploy and initialize ══════════════

    function test_DeployAndInitialize() public view {
        assertEq(tokenV1().name(), "OnchainGitToken");
        assertEq(tokenV1().symbol(), "OGT");
        assertEq(tokenV1().owner(), owner);
        assertEq(tokenV1().version(), "1.0.0");
    }

    // ═══════════════ TEST 2: Mint and Burn ══════════════════════

    function test_MintAndBurn() public {
        tokenV1().mint(user, 1000 ether);
        assertEq(tokenV1().balanceOf(user), 1000 ether);

        vm.prank(user);
        tokenV1().burn(300 ether);
        assertEq(tokenV1().balanceOf(user), 700 ether);
    }

    // ═══════════════ TEST 3: Version history after deploy ═══════

    function test_VersionHistoryAfterDeploy() public view {
        assertEq(beacon.getVersionCount(), 1);
        assertEq(beacon.currentVersionIndex(), 0);

        VersionedBeacon.VersionInfo memory v = beacon.getVersion(0);
        assertEq(v.implementation, address(implV1));
    }

    // ═══════════════ TEST 4: Upgrade to V2 ═════════════════════

    function test_UpgradeToV2() public {
        tokenV1().mint(user, 1000 ether);

        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");

        assertEq(beacon.getVersionCount(), 2);
        assertEq(beacon.currentVersionIndex(), 1);
        assertEq(tokenV2().version(), "2.0.0");

        tokenV2().initializeV2(100, treasury);
        assertEq(tokenV2().feePercent(), 100);
        assertEq(tokenV2().treasury(), treasury);
    }

    // ═══════════════ TEST 5: Upgrade to V3 ═════════════════════

    function test_UpgradeToV3() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");
        tokenV2().initializeV2(100, treasury);

        beacon.upgradeToWithDescription(address(implV3), "V3: Pausable");
        tokenV3().initializeV3();

        assertEq(beacon.getVersionCount(), 3);
        assertEq(tokenV3().version(), "3.0.0");

        tokenV3().pause();
        assertTrue(tokenV3().paused());

        tokenV3().unpause();
        assertFalse(tokenV3().paused());
    }

    // ═══════════════ TEST 6: Storage persistence ═══════════════

    function test_StoragePersistenceAcrossUpgrades() public {
        tokenV1().mint(user, 1000 ether);
        assertEq(tokenV1().balanceOf(user), 1000 ether);

        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");

        assertEq(tokenV2().balanceOf(user), 1000 ether);
        assertEq(tokenV2().name(), "OnchainGitToken");
        assertEq(tokenV2().owner(), owner);
    }

    // ═══════════════ TEST 7: Rollback V3 -> V1 ═════════════════

    function test_RollbackToV1() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");
        tokenV2().initializeV2(100, treasury);
        beacon.upgradeToWithDescription(address(implV3), "V3: Pausable");
        tokenV3().initializeV3();

        beacon.rollbackTo(0);

        assertEq(beacon.currentVersionIndex(), 0);
        assertEq(tokenV1().version(), "1.0.0");

        tokenV1().mint(user, 500 ether);
        assertEq(tokenV1().balanceOf(user), 500 ether);
    }

    // ═══════════════ TEST 8: Rollback preserves history ════════

    function test_RollbackPreservesHistory() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");
        beacon.upgradeToWithDescription(address(implV3), "V3: Pausable");

        assertEq(beacon.getVersionCount(), 3);

        beacon.rollbackTo(0);

        assertEq(beacon.getVersionCount(), 3);
        assertEq(beacon.currentVersionIndex(), 0);
    }

    // ═══════════════ TEST 9: Rollback + storage ═══════════════

    function test_RollbackStoragePersistence() public {
        tokenV1().mint(user, 1000 ether);

        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");
        tokenV2().initializeV2(100, treasury);

        beacon.rollbackTo(0);

        assertEq(tokenV1().balanceOf(user), 1000 ether);
        assertEq(tokenV1().owner(), owner);
    }

    // ═══════════════ TEST 10: Only owner can upgrade ═══════════

    function test_OnlyOwnerCanUpgrade() public {
        vm.prank(user);
        vm.expectRevert();
        beacon.upgradeToWithDescription(address(implV2), "V2: Unauthorized");
    }

    // ═══════════════ TEST 11: Only owner can rollback ══════════

    function test_OnlyOwnerCanRollback() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");

        vm.prank(user);
        vm.expectRevert();
        beacon.rollbackTo(0);
    }

    // ═══════════════ TEST 12: Rollback invalid index ═══════════

    function test_RollbackInvalidIndex() public {
        vm.expectRevert(abi.encodeWithSelector(VersionedBeacon.InvalidVersionIndex.selector, 999, 0));
        beacon.rollbackTo(999);
    }

    // ═══════════════ TEST 13: getVersion returns correct data ══

    function test_GetVersionReturnsCorrectData() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");
        beacon.upgradeToWithDescription(address(implV3), "V3: Pausable");

        VersionedBeacon.VersionInfo memory v0 = beacon.getVersion(0);
        assertEq(v0.implementation, address(implV1));

        VersionedBeacon.VersionInfo memory v1 = beacon.getVersion(1);
        assertEq(v1.implementation, address(implV2));

        VersionedBeacon.VersionInfo memory v2 = beacon.getVersion(2);
        assertEq(v2.implementation, address(implV3));
    }

    // ═══════════════ TEST 14: getCurrentVersion ════════════════

    function test_GetCurrentVersion() public {
        beacon.upgradeToWithDescription(address(implV2), "V2: Transfer fee");

        VersionedBeacon.VersionInfo memory current = beacon.getCurrentVersion();
        assertEq(current.implementation, address(implV2));

        beacon.rollbackTo(0);
        current = beacon.getCurrentVersion();
        assertEq(current.implementation, address(implV1));
    }
}
