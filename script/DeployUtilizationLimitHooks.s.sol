// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {UtilizationLimitHooks} from "../src/UtilizationLimitHooks.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * PRIVATE_KEY=$(cast wallet dk {your_account_name} | awk '{print $NF}') forge script DeployUtilizationLimitHooksScript \
 *     --rpc-url arbitrum \
 *     --broadcast \
 *     --verify \
 */
contract DeployUtilizationLimitHooksScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address implementation = address(new UtilizationLimitHooks());
        address proxy = address(new ERC1967Proxy(implementation, abi.encodeCall(UtilizationLimitHooks.initialize, ())));
        vm.stopBroadcast();

        console.log("UtilizationLimitHooks deployed at: %s", proxy);
        console.log("Implementation: %s", implementation);
    }
}
