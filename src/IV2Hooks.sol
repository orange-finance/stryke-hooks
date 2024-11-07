// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IV2Hooks {
    function onPositionUse(bytes calldata _data) external;

    function onPositionUnUse(bytes calldata _data) external;
}
