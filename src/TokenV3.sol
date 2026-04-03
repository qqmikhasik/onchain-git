// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/// @title TokenV3 — ERC-20 with transfer fee + pausable (version 3)
contract TokenV3 is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    // ═══════════════ NAMESPACED STORAGE (reuse V2) ══════════════

    /// @custom:storage-location erc7201:onchain-git.token.v2
    struct TokenV2Storage {
        uint256 feePercent;
        address treasury;
    }

    // Same storage location as TokenV2 — shared namespace
    bytes32 private constant STORAGE_LOCATION_V2 =
        0x3b4cfa64fed027cfcfe60b9d5955ffd2567e63963f7337663f4a45b508ee6f00;

    function _getTokenV2Storage() private pure returns (TokenV2Storage storage $) {
        assembly {
            $.slot := STORAGE_LOCATION_V2
        }
    }

    // ═══════════════ INITIALIZATION ══════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("OnchainGitToken", "OGT");
        __Ownable_init(initialOwner);
    }

    function initializeV2(uint256 feePercent_, address treasury_) public reinitializer(2) {
        TokenV2Storage storage $ = _getTokenV2Storage();
        $.feePercent = feePercent_;
        $.treasury = treasury_;
    }

    function initializeV3() public reinitializer(3) {
        __Pausable_init();
    }

    // ═══════════════ PAUSE ══════════════════════════════════════

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ═══════════════ TRANSFER WITH FEE + PAUSE ══════════════════

    function _update(address from, address to, uint256 value) internal virtual override {
        _requireNotPaused();

        TokenV2Storage storage $ = _getTokenV2Storage();

        if (from != address(0) && to != address(0) && $.feePercent > 0) {
            uint256 fee = (value * $.feePercent) / 10000;
            super._update(from, $.treasury, fee);
            super._update(from, to, value - fee);
        } else {
            super._update(from, to, value);
        }
    }

    // ═══════════════ STANDARD FUNCTIONS ══════════════════════════

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function feePercent() external view returns (uint256) {
        return _getTokenV2Storage().feePercent;
    }

    function treasury() external view returns (address) {
        return _getTokenV2Storage().treasury;
    }

    function version() external pure virtual returns (string memory) {
        return "3.0.0";
    }
}
