pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/factories/BribeFactory.sol";
import "contracts/factories/GaugeFactory.sol";
import "contracts/factories/PairFactory.sol";
import "contracts/redeem/MerkleClaim.sol";
import "contracts/redeem/RedemptionReceiver.sol";
import "contracts/redeem/RedemptionSender.sol";
import "contracts/InternalBribe.sol";
import "contracts/ExternalBribe.sol";
import "contracts/Gauge.sol";
import "contracts/Minter.sol";
import "contracts/Pair.sol";
import "contracts/PairFees.sol";
import "contracts/RewardsDistributor.sol";
import "contracts/Router.sol";
import "contracts/Velo.sol";
import "contracts/VelodromeLibrary.sol";
import "contracts/Voter.sol";
import "contracts/VeArtProxy.sol";
import "contracts/VotingEscrow.sol";
import "utils/TestOwner.sol";
import "utils/TestStakingRewards.sol";
import "utils/TestToken.sol";
import "utils/TestVoter.sol";
import "utils/TestVotingEscrow.sol";
import "utils/TestWETH.sol";

abstract contract BaseTest is Test, TestOwner {
    uint256 constant USDC_1 = 1e6;
    uint256 constant USDC_100K = 1e11; // 1e5 = 100K tokens with 6 decimals
    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals
    uint256 constant TOKEN_100M = 1e26; // 1e8 = 100M tokens with 18 decimals
    uint256 constant TOKEN_10B = 1e28; // 1e10 = 10B tokens with 18 decimals
    uint256 constant PAIR_1 = 1e9;

    TestOwner owner;
    TestOwner owner2;
    TestOwner owner3;
    address[] owners;
    MockERC20 USDC;
    MockERC20 FRAX;
    MockERC20 DAI;
    TestWETH WETH; // Mock WETH token
    Velo VELO;
    MockERC20 WEVE;
    MockERC20 LR; // late reward
    TestToken stake; // MockERC20 with claimFees() function that returns (0,0)
    PairFactory factory;
    Router router;
    VelodromeLibrary lib;
    Pair pair;
    Pair pair2;
    Pair pair3;

    function deployOwners() public {
        owner = TestOwner(address(this));
        owner2 = new TestOwner();
        owner3 = new TestOwner();
        owners = new address[](3);
        owners[0] = address(owner);
        owners[1] = address(owner2);
        owners[2] = address(owner3);
    }

    function deployCoins() public {
        USDC = new MockERC20("USDC", "USDC", 6);
        FRAX = new MockERC20("FRAX", "FRAX", 18);
        DAI = new MockERC20("DAI", "DAI", 18);
        VELO = new Velo();
        WEVE = new MockERC20("WEVE", "WEVE", 18);
        LR = new MockERC20("LR", "LR", 18);
        WETH = new TestWETH();
        stake = new TestToken("stake", "stake", 18, address(owner));
    }

    function mintStables() public {
        for (uint256 i = 0; i < owners.length; i++) {
            USDC.mint(owners[i], 1e12 * USDC_1);
            FRAX.mint(owners[i], 1e12 * TOKEN_1);
            DAI.mint(owners[i], 1e12 * TOKEN_1);
        }
    }

    function mintVelo(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _amounts.length; i++) {
            VELO.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintLR(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            LR.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintStake(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            stake.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintWETH(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            WETH.mint(_accounts[i], _amounts[i]);
        }
    }

    function dealETH(address [] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            vm.deal(_accounts[i], _amounts[i]);
        }
    }

    function deployPairFactoryAndRouter() public {
        factory = new PairFactory();
        assertEq(factory.allPairsLength(), 0);
        factory.setFee(true, 1); // set fee back to 0.01% for old tests
        factory.setFee(false, 1);
        router = new Router(address(factory), address(WETH));
        assertEq(router.factory(), address(factory));
        lib = new VelodromeLibrary(address(router));
    }

    function deployPairWithOwner(address _owner) public {
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(USDC), address(router), USDC_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(USDC), true, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(USDC), address(router), USDC_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(USDC), false, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(DAI), address(router), TOKEN_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(DAI), true, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);

        assertEq(factory.allPairsLength(), 3);

        address create2address = router.pairFor(address(FRAX), address(USDC), true);
        address address1 = factory.getPair(address(FRAX), address(USDC), true);
        pair = Pair(address1);
        address address2 = factory.getPair(address(FRAX), address(USDC), false);
        pair2 = Pair(address2);
        address address3 = factory.getPair(address(FRAX), address(DAI), true);
        pair3 = Pair(address3);
        assertEq(address(pair), create2address);
        assertGt(lib.getAmountOut(USDC_1, address(USDC), address(FRAX), true), 0);
    }

    function mintPairFraxUsdcWithOwner(address _owner) public {
        TestOwner(_owner).transfer(address(USDC), address(pair), USDC_1);
        TestOwner(_owner).transfer(address(FRAX), address(pair), TOKEN_1);
        TestOwner(_owner).mint(address(pair), _owner);
    }

    receive() external payable {}
}
