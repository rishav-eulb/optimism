// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CrossDomainMessenger } from "src/universal/CrossDomainMessenger.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IOptimismMintableERC20 } from "src/universal/IOptimismMintableERC20.sol";

contract L2StandardBridge {
    CrossDomainMessenger public immutable crossDomainMessenger;

    event RewardMinted(address indexed recipient, uint256 amount);

    constructor(address _crossDomainMessenger) {
        crossDomainMessenger = CrossDomainMessenger(_crossDomainMessenger);
    }

    function finalizeBridgeERC20(
        address _localToken,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) external {
        // Ensure that the message is coming from the L1 bridge
        require(msg.sender == address(crossDomainMessenger), "Invalid sender");

        // Mint tokens on the L2 side
        IOptimismMintableERC20(_localToken).mint(_to, _amount);

        emit RewardMinted(_to, _amount);

        // Execute any additional logic specified by the user
        // (e.g., update user balances or emit custom events)
        // The _extraData parameter can be used for this purpose.
        // ...

        // Note: The gas limit is automatically determined by the crossDomainMessenger

        // You may want to implement additional security checks and validations here.

        // Optionally, you can emit an event to log the completion of the minting process
        // ...
    }

    function getUserBalance(address _token, address _user) external view returns (uint256) {
        return ERC20(_token).balanceOf(_user);
    }
}
