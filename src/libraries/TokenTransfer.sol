// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "../interfaces/IERC20.sol";

error TransferFailed();

library TokenTransfer {
    function safeTransfer(address token, address to, uint256 amount) internal {
        if (amount == 0) return;
        if (token.code.length == 0) revert TransferFailed();
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        if (amount == 0) return;
        if (token.code.length == 0) revert TransferFailed();
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }
}
