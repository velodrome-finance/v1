pragma solidity 0.8.13;

import "solmate/test/utils/DSTestPlus.sol";

import "utils/TestVotingToken.sol";
import "utils/TestGovernance.sol";
import "utils/TestL2Governance.sol";

contract OnChainVoteTest is DSTestPlus {
  TestVotingERC20 vt;
  TestGovernance gov;
  TestL2Governance gov2;

  function setUp() public {
    vt = new TestVotingERC20("coin", "SYM");
    gov = new TestGovernance(vt);
    gov2 = new TestL2Governance(vt);
    hevm.roll(block.number + 1);
  }

  function testVote() public {
    assertEq(vt.owner(), address(this));
    assertEq(gov.version(), "1");
    assertEq(gov.name(), "TestGovernor");
    assertEq(gov.votingPeriod(), 7);
    assertEq(gov.quorum(0), 0);
  }

  function testL2Gov() public {
    assertEq(gov2.version(), "1");
    assertEq(gov2.name(), "TestL2Governor");
    assertEq(gov2.votingPeriod(), 7);
    assertEq(gov2.quorum(0), 0);
  }

  function testProposal() public {
    vt.mint(address(this), 5);
    vt.mint(address(gov), 100);

    // let's vote to move 100 token here..
    address dest = address(1);

    address[] memory targets = new address[](1);
    targets[0] = address(vt);
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    bytes[] memory calldatas = new bytes[](1);
    bytes memory data = abi.encodeCall(vt.transfer, (dest, 100));
    calldatas[0] = data;
    string memory description = "no description";

    uint256 proposal_id = gov.propose(targets, values, calldatas, description);

    // delegate vote power before proposal goes live
    vt.delegate(address(this));
    // 1 more until active
    hevm.roll(block.number + 2);

    gov.castVote(
      proposal_id,
      uint8(GovernorCountingSimple.VoteType.For) // 1
    );

    assertEq(uint8(gov.state(proposal_id)), 1); // 1 = active
    hevm.roll(block.number + 7); // voting period over?
    assertEq(uint8(gov.state(proposal_id)), 4); // 3 = defeated, 4 = succeeded

    uint256 executed_proposal_id = gov.execute(
      targets,
      values,
      calldatas,
      keccak256(bytes(description))
    );
    assertEq(executed_proposal_id, proposal_id);

    uint256 dest_bal = vt.balanceOf(dest);
    assertEq(dest_bal, 100);
  }

  function testL2Proposal() public {
    vt.mint(address(this), 5);
    vt.mint(address(gov2), 100);

    // let's vote to move 100 token here..
    address dest = address(1);

    address[] memory targets = new address[](1);
    targets[0] = address(vt);
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    bytes[] memory calldatas = new bytes[](1);
    bytes memory data = abi.encodeCall(vt.transfer, (dest, 100));
    calldatas[0] = data;
    string memory description = "no description";

    uint256 proposal_id = gov2.propose(targets, values, calldatas, description);

    // delegate vote power before proposal goes live
    vt.delegate(address(this));
    // 1 more until active
    hevm.warp(block.timestamp + 2);
    hevm.roll(block.number + 1);

    gov2.castVote(
      proposal_id,
      uint8(GovernorCountingSimple.VoteType.For) // 1
    );

    hevm.warp(block.timestamp + 7);
    hevm.roll(block.number + 1); // voting period over?
    assertEq(uint8(gov2.state(proposal_id)), 4); // 3 = defeated, 4 = succeeded

    uint256 executed_proposal_id = gov2.execute(
      targets,
      values,
      calldatas,
      keccak256(bytes(description))
    );
    assertEq(executed_proposal_id, proposal_id);

    uint256 dest_bal = vt.balanceOf(dest);
    assertEq(dest_bal, 100);
  }
}
