// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IMooniswapDeployer.sol";
import "./libraries/UniERC20.sol";
import "./Mooniswap.sol";
import "./governance/MooniswapFactoryGovernance.sol";


contract MooniswapFactory is MooniswapFactoryGovernance {
    using UniERC20 for IERC20;

    event Deployed(
        address indexed mooniswap,
        address indexed token1,
        address indexed token2
    );

    IMooniswapDeployer public immutable mooniswapDeployer;
    address public immutable poolOwner;
    Mooniswap[] public allPools;
    mapping(Mooniswap => bool) public isPool;
    mapping(IERC20 => mapping(IERC20 => Mooniswap)) public pools;

    constructor (address _poolOwner, IMooniswapDeployer _mooniswapDeployer, address _governanceMothership) public MooniswapFactoryGovernance(_governanceMothership) {
        poolOwner = _poolOwner;
        mooniswapDeployer = _mooniswapDeployer;
    }

    function getAllPools() external view returns(Mooniswap[] memory) {
        return allPools;
    }

    function deploy(IERC20 tokenA, IERC20 tokenB) public returns(Mooniswap pool) {
        require(tokenA != tokenB, "Factory: not support same tokens");
        require(pools[tokenA][tokenB] == Mooniswap(0), "Factory: pool already exists");

        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);

        string memory symbol1 = token1.uniSymbol();
        string memory symbol2 = token2.uniSymbol();

        pool = mooniswapDeployer.deploy(
            token1,
            token2,
            string(abi.encodePacked("Mooniswap V2 (", symbol1, "-", symbol2, ")")),
            string(abi.encodePacked("MOON-V2-", symbol1, "-", symbol2)),
            poolOwner
        );

        pools[token1][token2] = pool;
        pools[token2][token1] = pool;
        allPools.push(pool);
        isPool[pool] = true;

        emit Deployed(
            address(pool),
            address(token1),
            address(token2)
        );
    }

    function sortTokens(IERC20 tokenA, IERC20 tokenB) public pure returns(IERC20, IERC20) {
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        }
        return (tokenB, tokenA);
    }
}
