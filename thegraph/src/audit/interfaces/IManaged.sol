// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IManaged {
    function controller() external view returns (address);
}
