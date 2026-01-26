// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BlueVault
 * @notice Main vault contract where users deposit tokens to earn yield
 * @dev Users receive vault shares (receipt tokens) representing their deposit
 */
contract BlueVault is ERC20, ReentrancyGuard, Ownable {
    IERC20 public immutable asset; // The token users deposit (e.g., USDC)
    IStrategy public strategy; // Active yield strategy

    uint256 public constant PERFORMANCE_FEE = 1000; // 10% (basis points)
    uint256 public constant FEE_DENOMINATOR = 10000;

    uint256 public totalDeposits; // Total assets deposited
    uint256 public lastHarvestTimestamp;

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event Harvested(uint256 profit, uint256 fee);
    event StrategyUpdated(address indexed newStrategy);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        asset = IERC20(_asset);
        lastHarvestTimestamp = block.timestamp;
    }

    /**
     * @notice Deposit assets into the vault
     * @param _amount Amount of tokens to deposit
     * @return shares Amount of vault shares minted
     */
    function deposit(
        uint256 _amount
    ) external nonReentrant returns (uint256 shares) {
        require(_amount > 0, "Cannot deposit 0");

        // Calculate shares to mint
        shares = totalSupply() == 0
            ? _amount
            : (_amount * totalSupply()) / totalAssets();

        // Transfer tokens from user
        asset.transferFrom(msg.sender, address(this), _amount);

        // Mint vault shares to user
        _mint(msg.sender, shares);
        totalDeposits += _amount;

        // If strategy exists, deploy funds
        if (address(strategy) != address(0)) {
            asset.approve(address(strategy), _amount);
            strategy.deposit(_amount);
        }

        emit Deposited(msg.sender, _amount, shares);
    }

    /**
     * @notice Withdraw assets from the vault
     * @param _shares Amount of vault shares to burn
     * @return assets Amount of tokens withdrawn
     */
    function withdraw(
        uint256 _shares
    ) external nonReentrant returns (uint256 assets) {
        require(_shares > 0, "Cannot withdraw 0");
        require(balanceOf(msg.sender) >= _shares, "Insufficient shares");

        // Calculate asset amount based on shares
        assets = (_shares * totalAssets()) / totalSupply();

        // Withdraw from strategy if needed
        if (address(strategy) != address(0)) {
            uint256 vaultBalance = asset.balanceOf(address(this));
            if (vaultBalance < assets) {
                strategy.withdraw(assets - vaultBalance);
            }
        }

        // Burn shares and transfer assets
        _burn(msg.sender, _shares);
        totalDeposits -= assets;
        asset.transfer(msg.sender, assets);

        emit Withdrawn(msg.sender, assets, _shares);
    }

    /**
     * @notice Get total assets under management (in vault + in strategy)
     */
    function totalAssets() public view returns (uint256) {
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 strategyBalance = address(strategy) != address(0)
            ? strategy.balanceOf()
            : 0;
        return vaultBalance + strategyBalance;
    }

    /**
     * @notice Harvest profits from strategy and compound
     */
    function harvest() external {
        require(address(strategy) != address(0), "No strategy set");

        uint256 beforeBalance = totalAssets();
        strategy.harvest();
        uint256 afterBalance = totalAssets();

        if (afterBalance > beforeBalance) {
            uint256 profit = afterBalance - beforeBalance;
            uint256 fee = (profit * PERFORMANCE_FEE) / FEE_DENOMINATOR;

            // Take performance fee
            if (fee > 0) {
                asset.transfer(owner(), fee);
            }

            lastHarvestTimestamp = block.timestamp;
            emit Harvested(profit, fee);
        }
    }

    /**
     * @notice Set or update the active strategy (owner only)
     */
    function setStrategy(address _strategy) external onlyOwner {
        // Withdraw all from old strategy if exists
        if (address(strategy) != address(0)) {
            strategy.withdrawAll();
        }

        strategy = IStrategy(_strategy);

        // Deploy funds to new strategy
        if (_strategy != address(0)) {
            uint256 balance = asset.balanceOf(address(this));
            if (balance > 0) {
                asset.approve(_strategy, balance);
                strategy.deposit(balance);
            }
        }

        emit StrategyUpdated(_strategy);
    }

    /**
     * @notice Calculate shares for a given asset amount
     */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return
            totalSupply() == 0
                ? assets
                : (assets * totalSupply()) / totalAssets();
    }

    /**
     * @notice Calculate assets for a given share amount
     */
    function previewWithdraw(uint256 shares) external view returns (uint256) {
        return (shares * totalAssets()) / totalSupply();
    }
}

/**
 * @title IStrategy
 * @notice Interface that all strategies must implement
 */
interface IStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function harvest() external;
    function balanceOf() external view returns (uint256);
}

/**
 * @title AaveStrategy
 * @notice Example strategy that deposits tokens into Aave lending pool
 */
contract AaveStrategy is IStrategy, Ownable {
    IERC20 public immutable asset;
    address public immutable vault;

    // Aave V3 interfaces (simplified)
    IPool public aavePool;
    IERC20 public aToken; // Receipt token from Aave

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault can call");
        _;
    }

    constructor(
        address _asset,
        address _vault,
        address _aavePool,
        address _aToken
    ) Ownable(msg.sender) {
        asset = IERC20(_asset);
        vault = _vault;
        aavePool = IPool(_aavePool);
        aToken = IERC20(_aToken);
    }

    /**
     * @notice Deposit tokens into Aave
     */
    function deposit(uint256 amount) external override onlyVault {
        asset.transferFrom(vault, address(this), amount);
        asset.approve(address(aavePool), amount);
        aavePool.supply(address(asset), amount, address(this), 0);
    }

    /**
     * @notice Withdraw tokens from Aave
     */
    function withdraw(uint256 amount) external override onlyVault {
        aavePool.withdraw(address(asset), amount, vault);
    }

    /**
     * @notice Withdraw all tokens from Aave
     */
    function withdrawAll() external override onlyVault {
        uint256 balance = balanceOf();
        if (balance > 0) {
            aavePool.withdraw(address(asset), balance, vault);
        }
    }

    /**
     * @notice Harvest yield (for Aave, yield accumulates automatically in aTokens)
     * @dev No action needed for Aave as interest accrues in real-time
     */
    function harvest() external override {
        // Aave automatically compounds, so nothing to do here
        // Other protocols might require claiming rewards
    }

    /**
     * @notice Get current balance in strategy
     */
    function balanceOf() public view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }
}

/**
 * @title IPool
 * @notice Simplified Aave V3 Pool interface
 */
interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

/**
 * @title CompoundStrategy
 * @notice Example strategy for Compound/Moonwell (similar interface)
 */
contract CompoundStrategy is IStrategy, Ownable {
    IERC20 public immutable asset;
    address public immutable vault;
    ICToken public cToken; // Compound's receipt token

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault can call");
        _;
    }

    constructor(
        address _asset,
        address _vault,
        address _cToken
    ) Ownable(msg.sender) {
        asset = IERC20(_asset);
        vault = _vault;
        cToken = ICToken(_cToken);
    }

    function deposit(uint256 amount) external override onlyVault {
        asset.transferFrom(vault, address(this), amount);
        asset.approve(address(cToken), amount);
        require(cToken.mint(amount) == 0, "Mint failed");
    }

    function withdraw(uint256 amount) external override onlyVault {
        require(cToken.redeemUnderlying(amount) == 0, "Redeem failed");
        asset.transfer(vault, amount);
    }

    function withdrawAll() external override onlyVault {
        uint256 balance = cToken.balanceOf(address(this));
        if (balance > 0) {
            require(cToken.redeem(balance) == 0, "Redeem failed");
            asset.transfer(vault, asset.balanceOf(address(this)));
        }
    }

    function harvest() external override {
        // Compound automatically compounds
    }

    function balanceOf() public view override returns (uint256) {
        return
            (cToken.balanceOf(address(this)) * cToken.exchangeRateStored()) /
            1e18;
    }
}

/**
 * @title ICToken
 * @notice Simplified Compound/Moonwell cToken interface
 */
interface ICToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
}
