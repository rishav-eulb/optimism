// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CrossDomainMessenger } from "./CrossDomainMessenger.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract L1StandardBridge {
    CrossDomainMessenger public immutable crossDomainMessenger;
    mapping(address => mapping(address => uint256)) private deposits;

    event TokensLocked(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint32 chainId
    );

    constructor(address _crossDomainMessenger) {
        crossDomainMessenger = CrossDomainMessenger(_crossDomainMessenger);
    }

    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external {
        ERC20 localToken = ERC20(_localToken);
        uint256 allowance = localToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");
        localToken.transferFrom(msg.sender, address(this), _amount);

        deposits[_localToken][_remoteToken] += _amount;

        emit TokensLocked(msg.sender, _localToken, _amount, _remoteToken);
        crossDomainMessenger.sendMessage(
            _remoteToken,
            abi.encodeWithSignature(
                "finalizeBridgeERC20(address,address,address,uint256,bytes)",
                _localToken,
                _to,
                _amount,
                _extraData
            ),
            _minGasLimit
        );
    }

    function getDeposit(address _localToken, address _remoteToken) external view returns (uint256) {
        return deposits[_localToken][_remoteToken];
    }

    function withdraw(address _token, address _to, uint256 _amount) external {
        ERC20 token = ERC20(_token);
        require(deposits[_token][_token] >= _amount, "Insufficient balance");

        deposits[_token][_token] -= _amount;
        token.transfer(_to, _amount);
    }
}
