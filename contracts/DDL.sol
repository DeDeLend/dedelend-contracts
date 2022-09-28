// SPDX-License-Identifier: RANDOM_TEXT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IHegicOperationalTreasury.sol";
import "./IHegicStrategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPoolDDL.sol";

contract DDL is Ownable {
    using SafeERC20 for IERC20;

    uint256 public LTV;
    uint256 public LTV_DECIMALS = 10**4;

    IERC721 public collateralToken;
    IHegicOperationalTreasury public operationalPool;
    IERC20 public USDC;

    uint256 public interestRate = 19025875190258754083880960;
    uint256 public INTEREST_RATE_DECIMALS = 10**30;

    uint256 public minBorrowLimit;
    uint256 public COLLATERAL_DECIMALS;

    uint256 public PriorLiqPriceCoef;

    IPoolDDL public pool;

    struct BorrowedByOption {
        uint256 borrowed;
        uint256 newBorrowTimestamp;
    }
    struct optionInfo {
        address strategyAddress;
        uint256 amount;
        uint256 strike;
        uint256 expiration;
        bool isLong;
    }
    struct CollateralInfo {
        address owner;
        optionInfo strategy;
    }

    enum HegicStrategyType {
        Invalid,
        Long,
        Short
    }

    mapping(uint256 => CollateralInfo) public collateralInfo;
    mapping(uint256 => BorrowedByOption) public borrowedByOption;
    mapping(address => HegicStrategyType) public strategyType;

    event Borrow(
        address indexed user,
        uint256 indexed optionID,
        uint256 amount,
        address strategy,
        uint256 timestamp
    );
    event Repay(address indexed user, uint256 indexed optionID, uint256 amount);
    event Liquidate(
        address indexed user,
        uint256 indexed optionID,
        uint256 amount,
        uint256 poolProfit,
        uint256 liqFee
    );
    event Unlock(address indexed user, uint256 indexed optionID);
    event ForcedExercise(
        address indexed user,
        uint256 indexed optionID,
        uint256 amount,
        uint256 poolProfit,
        uint256 liqFee
    );
    event ExerciseByPriorLiqPrice(
        address indexed user,
        uint256 indexed optionID,
        uint256 userReturn,
        uint256 poolReturn,
        uint256 liqFee
    );

    constructor(
        address[4] memory _arrLongHegicStrategy,
        address[4] memory _arrShortHegicStrategy,
        IERC721 _collateralToken,
        IHegicOperationalTreasury _operationalPool,
        IERC20 _USDC,
        uint256 _minBorrowLimit,
        uint256 _ltv,
        uint256 _COLLATERAL_DECIMALS,
        uint256 _PriorLiqPriceCoef
    ) {
        for (uint256 i = 0; i < _arrLongHegicStrategy.length; i++) {
            strategyType[_arrLongHegicStrategy[i]] = HegicStrategyType.Long;
        }
        for (uint256 i = 0; i < _arrShortHegicStrategy.length; i++) {
            strategyType[_arrShortHegicStrategy[i]] = HegicStrategyType.Short;
        }
        collateralToken = _collateralToken;
        operationalPool = _operationalPool;
        USDC = _USDC;
        minBorrowLimit = _minBorrowLimit;
        LTV = _ltv;
        COLLATERAL_DECIMALS = 10**_COLLATERAL_DECIMALS;
        PriorLiqPriceCoef = _PriorLiqPriceCoef;
    }

    function setLTV(uint256 value) external onlyOwner {
        require(value <= 8000, "invalid value");
        LTV = value;
    }

    function setInterestRate(uint256 value) external onlyOwner {
        interestRate = value;
    }

    function setInterestRateDecimals(uint256 value) external onlyOwner {
        INTEREST_RATE_DECIMALS = value;
    }

    function setMinBorrowLimit(uint256 value) external onlyOwner {
        minBorrowLimit = value;
    }

    function setPool(address value) external onlyOwner {
        pool = IPoolDDL(value);
    }

    function lockOption(uint256 id) external {
        require(pool.openDeDeLend(), "pauseDeDeLend");
        (
            IHegicOperationalTreasury.LockedLiquidityState state,
            address strategy,
            ,
            ,
            uint32 expiration
        ) = operationalPool.lockedLiquidity(id);
        require(block.timestamp <= uint256(expiration) - 60*60, "too late");
        (uint128 amount, uint128 strike) = IHegicStrategy(strategy)
            .strategyData(id);
        require(
            state == IHegicOperationalTreasury.LockedLiquidityState.Locked,
            "option is active"
        );
        require(collateralToken.ownerOf(id) == msg.sender, "you not owner");
        require(
            strategyType[strategy] != HegicStrategyType.Invalid,
            "strategy not supported"
        );
        collateralToken.transferFrom(msg.sender, address(this), id);
        bool isLong = strategyType[strategy] == HegicStrategyType.Long ? true: false;
        collateralInfo[id] = CollateralInfo(
            msg.sender,
            optionInfo(
                strategy,
                uint256(amount),
                uint256(strike),
                uint256(expiration),
                isLong
            )
        );
    }

    function maxBorrowLimit(uint256 id) public view returns (uint256) {
        return (profitByOption(id) / LTV_DECIMALS) * LTV;
    }

    function borrow(uint256 id, uint256 amount) external {
        require(pool.openDeDeLend(), "pauseDeDeLend");
        BorrowedByOption storage data = borrowedByOption[id];
        uint256 maxLimit = maxBorrowLimit(id);
        (
            IHegicOperationalTreasury.LockedLiquidityState state,
            ,
            ,
            ,

        ) = operationalPool.lockedLiquidity(id);
        uint256 totalBalance = pool.getTotalBalance(); 
        require(amount >= minBorrowLimit, "amount less minBorrowLimit");
        require(amount + data.borrowed <= maxLimit, "amount + data.borrowed less maxLimit");
        require(state == IHegicOperationalTreasury.LockedLiquidityState.Locked, "invalid state");
        require(msg.sender == collateralInfo[id].owner, "you are not the owner");
        require(amount <= totalBalance, "there is not enough money in the pool");
        require(block.timestamp <= collateralInfo[id].strategy.expiration - 60*60, "too late");
        if (collateralInfo[id].strategy.isLong) {
            require(currentPrice(id) > priorLiqPrice(id), "the price is too low");
        } else {
            require(currentPrice(id) < priorLiqPrice(id), "the price is too high");
        }
        uint256 upcomingFee = calculateUpcomingFee(id);
        borrowedByOption[id] = BorrowedByOption(
            amount + data.borrowed + upcomingFee,
            block.timestamp
        );
        pool.addTotalLocked(amount + upcomingFee);
        pool.send(collateralInfo[id].owner, amount);
        emit Borrow(
            msg.sender,
            id,
            amount,
            collateralInfo[id].strategy.strategyAddress,
            block.timestamp
        );
    }

    function liquidate(uint256 id) external {
        require(loanState(id), "invalid price");
        BorrowedByOption storage data = borrowedByOption[id];
        uint256 profit = profitByOption(id);
        exerciseOption(id);
        uint256 diff = 0;
        pool.subTotalLocked(data.borrowed);
        if (profit > data.borrowed) {
            diff = profit - data.borrowed;
            USDC.transfer(address(pool), data.borrowed+diff*90/100);
            USDC.transfer(msg.sender, diff*10/100);
        } else {
            USDC.transfer(address(pool), profit);
        }
        emit Liquidate(
            collateralInfo[id].owner,
            id,
            data.borrowed,
            diff*90/100,
            diff*10/100
        );
    }

    function forcedExercise(uint256 id) external {
        require(
            block.timestamp > collateralInfo[id].strategy.expiration - 30 * 60
        );
        BorrowedByOption storage data = borrowedByOption[id];
        uint256 profit = profitByOption(id);
        exerciseOption(id);
        uint256 diff = 0;
        pool.subTotalLocked(data.borrowed);
        if (profit > data.borrowed) {
            diff = profit - data.borrowed;
            USDC.transfer(address(pool), data.borrowed+diff*90/100);
            USDC.transfer(msg.sender, diff*10/100);
        } else {
            USDC.transfer(address(pool), profit);
        }
        emit ForcedExercise(
            collateralInfo[id].owner,
            id,
            data.borrowed,
            diff*90/100,
            diff*10/100
        );
    }

    function exerciseByPriorLiqPrice(uint256 id) external {
        require(loanStateByPriorLiqPrice(id), "invalid price");
        BorrowedByOption storage data = borrowedByOption[id];
        uint256 profit = profitByOption(id);
        exerciseOption(id);
        pool.subTotalLocked(data.borrowed);
        USDC.transfer(address(pool), data.borrowed);
        USDC.transfer(collateralInfo[id].owner, profit - (data.borrowed + data.borrowed*10/100));
        USDC.transfer(msg.sender, data.borrowed*10/100);
        emit ExerciseByPriorLiqPrice(
            collateralInfo[id].owner,
            id,
            profit - (data.borrowed + data.borrowed*10/100),
            data.borrowed,
            data.borrowed*10/100
        );
    }

    function calculateUpcomingFee(uint256 id)
        public
        view
        returns (uint256 upcomingFee)
    {
        BorrowedByOption storage data = borrowedByOption[id];
        uint256 periodInMinutes = (block.timestamp - data.newBorrowTimestamp) /
            60;
        upcomingFee =
            ((data.borrowed / 100) * (periodInMinutes * interestRate)) /
            INTEREST_RATE_DECIMALS;
    }

    function repay(uint256 id, uint256 amount) external {
        require(borrowedByOption[id].borrowed > 0, "option redeemed");
        uint256 upcomingFee = calculateUpcomingFee(id);
        require(
            amount <= borrowedByOption[id].borrowed + upcomingFee,
            "too much amount"
        );
        require(msg.sender == collateralInfo[id].owner);
        uint256 newBorrow = borrowedByOption[id].borrowed +
            upcomingFee -
            amount;
        pool.subTotalLocked(amount - upcomingFee);
        borrowedByOption[id] = BorrowedByOption(
            newBorrow,
            block.timestamp
        );
        USDC.transferFrom(collateralInfo[id].owner, address(this), amount);
        USDC.transfer(address(pool), amount);
        emit Repay(msg.sender, id, amount);
    }

    function unlock(uint256 id) external {
        require(borrowedByOption[id].borrowed == 0, "option is blocked");
        collateralToken.transferFrom(
            address(this),
            collateralInfo[id].owner,
            id
        );
        emit Unlock(msg.sender, id);
    }

    function loanState(uint256 id) public view returns (bool) {
        CollateralInfo storage collateral = collateralInfo[id];
        if (collateral.strategy.isLong) {
            return currentPrice(id) <= liqPrice(id);
        } else {
            return currentPrice(id) >= liqPrice(id);
        }
    }

    function loanStateByPriorLiqPrice(uint256 id) public view returns (bool) {
        CollateralInfo storage collateral = collateralInfo[id];
        if (collateral.strategy.isLong) {
            return currentPrice(id) <= priorLiqPrice(id);
        } else {
            return currentPrice(id) >= priorLiqPrice(id);
        }
    }

    function currentPrice(uint256 id) public view returns (uint256 price) {
        CollateralInfo storage data = collateralInfo[id];
        (, int256 latestPrice, , , ) = IHegicStrategy(
            data.strategy.strategyAddress
        ).priceProvider().latestRoundData();
        price = uint256(latestPrice);
    }

    function priorLiqPrice(uint256 id) public view returns (uint256 price) {
        (
            ,
            address strategy,
            ,
            ,
        ) = operationalPool.lockedLiquidity(id);
        (, uint128 strike) = IHegicStrategy(strategy).strategyData(id);
        if (collateralInfo[id].strategy.isLong) {
            return uint256(strike)*(100+PriorLiqPriceCoef)/100; 
        } 
        return uint256(strike)*(100-PriorLiqPriceCoef)/100;
    }
    function liqPrice(uint256 id) public view returns (uint256 price) {
        BorrowedByOption storage optionData = borrowedByOption[id];
        CollateralInfo storage data = collateralInfo[id];
        (
            ,
            address strategy,
            ,
            ,
        ) = operationalPool.lockedLiquidity(id);
        (uint128 amount, uint128 strike) = IHegicStrategy(strategy)
        .strategyData(id);
        if (data.strategy.isLong) {
            return uint256(strike) + (optionData.borrowed*COLLATERAL_DECIMALS)/(uint256(amount))*120;
        }
        return uint256(strike) - (optionData.borrowed*COLLATERAL_DECIMALS)/(uint256(amount))*120;
    }

    function currentLiqPrice(uint256 id) public view returns (uint256 price) {
        CollateralInfo storage data = collateralInfo[id];
        if (data.strategy.isLong){
            if (priorLiqPrice(id) > liqPrice(id)) {
                return priorLiqPrice(id);
            }
            return liqPrice(id);
        }
        if (priorLiqPrice(id) < liqPrice(id)) {
            return priorLiqPrice(id);
        }
        return liqPrice(id);
    }

    function profitByOption(uint256 id) public view returns (uint256 profit) {
        (,address strategy,,,) = operationalPool.lockedLiquidity(id);
        return IHegicStrategy(strategy).profitOf(id);
    }

    function exerciseOption(uint256 id) private {
        CollateralInfo storage data = collateralInfo[id];
        return IHegicStrategy(data.strategy.strategyAddress).exercise(id);
    }
}
