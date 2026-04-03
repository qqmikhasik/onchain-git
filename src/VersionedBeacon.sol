// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/// @title VersionedBeacon — Beacon with version history ("Onchain Git")
/// @notice Extends UpgradeableBeacon with version tracking and rollback capability
contract VersionedBeacon is UpgradeableBeacon {
    struct VersionInfo {
        address implementation;
        uint256 timestamp;
        string description;
    }

    VersionInfo[] private _versionHistory;
    uint256 public currentVersionIndex;

    event VersionAdded(uint256 indexed versionIndex, address implementation, string description);
    event RolledBack(uint256 indexed fromIndex, uint256 indexed toIndex);

    error InvalidVersionIndex(uint256 requested, uint256 maxIndex);

    constructor(
        address initialImplementation,
        address initialOwner,
        string memory description
    ) UpgradeableBeacon(initialImplementation, initialOwner) {
        _versionHistory.push(
            VersionInfo({implementation: initialImplementation, timestamp: block.timestamp, description: description})
        );
        currentVersionIndex = 0;
    }

    /// @notice Upgrade implementation and record in version history
    function upgradeToWithDescription(address newImplementation, string calldata description) external onlyOwner {
        upgradeTo(newImplementation);

        _versionHistory.push(
            VersionInfo({implementation: newImplementation, timestamp: block.timestamp, description: description})
        );

        currentVersionIndex = _versionHistory.length - 1;

        emit VersionAdded(currentVersionIndex, newImplementation, description);
    }

    /// @notice Rollback to a previous version from history
    function rollbackTo(uint256 _versionIndex) external onlyOwner {
        if (_versionIndex >= _versionHistory.length) {
            revert InvalidVersionIndex(_versionIndex, _versionHistory.length - 1);
        }

        uint256 oldIndex = currentVersionIndex;
        address target = _versionHistory[_versionIndex].implementation;

        upgradeTo(target);
        currentVersionIndex = _versionIndex;

        emit RolledBack(oldIndex, _versionIndex);
    }

    function getVersionCount() external view returns (uint256) {
        return _versionHistory.length;
    }

    function getVersion(uint256 index) external view returns (VersionInfo memory) {
        if (index >= _versionHistory.length) {
            revert InvalidVersionIndex(index, _versionHistory.length - 1);
        }
        return _versionHistory[index];
    }

    function getCurrentVersion() external view returns (VersionInfo memory) {
        return _versionHistory[currentVersionIndex];
    }

    function getAllVersions() external view returns (VersionInfo[] memory) {
        return _versionHistory;
    }
}
