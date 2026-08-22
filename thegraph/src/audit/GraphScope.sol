// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice In-scope contract addresses from Immunefi (see notes/scope.md)
library GraphScope {
    // Ethereum Mainnet
    address internal constant L1_STAKING = 0xF55041E37E12cD407ad00CE2910B8269B01263b9;
    address internal constant GRAPH_TOKEN = 0xc944E90C64B2c07662A292be6244BDf05Cda44a7;
    address internal constant L1_GNS = 0xaDcA0dd4729c8BA3aCf3E99F3A9f471EF37b6825;
    address internal constant REWARDS_MANAGER_L1 = 0x9Ac758AB77733b4150A901ebd659cbF8cB93ED66;
    address internal constant DISPUTE_MANAGER_L1 = 0x97307b963662cCA2f7eD50e38dCC555dfFc4FB0b;
    address internal constant CURATION_L1 = 0x8FE00a685Bcb3B2cc296ff6FfEaB10acA4CE1538;
    address internal constant BILLING_CONNECTOR = 0x8017B9AF3F199CC6b08A48DA3859410F20bbea72;
    address internal constant L1_GRAPH_TOKEN_GATEWAY = 0x01cDC91B0A9bA741903aA3699BF4CE31d6C5cC06;
    address internal constant GOVERNOR = 0x74Db79268e63302d3FC69FB5a7627F7454a41732;
    address internal constant ARBITRUM_INBOX = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address internal constant BRIDGE_ESCROW = 0x36aFF7001294daE4C2ED4fDEfC478a00De77F090;

    // Arbitrum One (billing + bridge counterpart + Phase 5 targets)
    address internal constant L2_BILLING = 0x1B07D3344188908Fb6DEcEac381f3eE63C48477a;
    address internal constant L2_GRAPH_TOKEN_GATEWAY = 0x65E1a5e8946e7E87d9774f5288f41c30a99fD302;
    address internal constant SUBGRAPH_SERVICE = 0xb2Bb92d0DE618878E438b55D5846cfecD9301105;
    address internal constant DISPUTE_MANAGER_L2 = 0x0Ab2B043138352413Bb02e67E626a70320E3BD46;
    address internal constant ALLOCATION_EXCHANGE = 0x993F00C98D1678371a7b261Ed0E0D4b6F42d9aEE;
    address internal constant GRAPH_TALLY_COLLECTOR = 0x8f69F5C07477Ac46FBc491B1E6D91E2bb0111A9e;
    address internal constant GRAPH_PAYMENTS = 0x7Aae8ae011927BC36Cb4d0d3e81f2E6E30daE06D;
    address internal constant PAYMENTS_ESCROW = 0xf6Fcc27aAf1fcD8B254498c9794451d82afC673E;

    // Arbitrum One
    address internal constant REWARDS_MANAGER_L2 = 0x971B9d3d0Ae3ECa029CAB5eA1fB0F72c85e6a525;
    address internal constant HORIZON_STAKING = 0x00669A4CF01450B64E8A2A20E9b1FCB71E61eF03;
    address internal constant L2_CURATION = 0x22d78fb4bc72e191C765807f8891B5e1785C8014;
    address internal constant SERVICE_REGISTRY = 0x072884c745c0A23144753335776c99BE22588f8A;
    address internal constant EPOCH_MANAGER = 0x5A843145c43d328B9bB7a4401d94918f131bB281;

    /// @dev Pin a block only when using an archive RPC (optional)
    uint256 internal constant MAINNET_FORK_BLOCK = 0;
    uint256 internal constant ARBITRUM_FORK_BLOCK = 0;
}
