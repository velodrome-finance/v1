import { task } from 'hardhat/config'

// SAMPLE command
// npx hardhat create-lock-for --network arbitrumOne --token 0xC33f7f83CbB021846Cb9c58f2d8E3df428dbC8C1 --contract 0x10Df81252069C1095F541FAca61646cb9Ae76703 --recipient 0x069e85D4F1010DD961897dC8C095FBB5FF297434 --amount 1 --duration 4
task('create-lock-for', 'Creates lock for a recipient address')
  .addParam("token", "The flow token address")
  .addParam("contract", "The Voting Escrow's contract address")
  .addParam("recipient", "The recipient's address")
  .addParam("amount", "The amount to lock (in MILLION)")
  .addParam("duration", "The lock duration")
  .setAction(async (
    taskArguments,
    { ethers }
  ) => {
    // Get signers
    const [signer] = await ethers.getSigners()

    // Get task arguments
    const { token, contract: veContract, recipient, amount: amountInMillion, duration: durationInYear } = taskArguments;

    // Validate task arguments
    if (!ethers.utils.isAddress(token)) {
      throw new Error("Recipient address is not valid")
    }

    if (!ethers.utils.isAddress(veContract)) {
      throw new Error("Voting Escrow contract address is not valid")
    }

    if (!ethers.utils.isAddress(recipient)) {
      throw new Error("Recipient address is not valid")
    }

    // Formatting amount
    const TOKEN_DECIMALS = ethers.BigNumber.from('10').pow(
      ethers.BigNumber.from('18')
    );
    const MILLION = ethers.BigNumber.from('10').pow(
      ethers.BigNumber.from('6')
    );
    const amount = ethers.BigNumber.from(amountInMillion)
      .mul(MILLION)
      .mul(TOKEN_DECIMALS);

    // Formatting duration
    const duration = Number(durationInYear) * 365 * 86400;

    // Get contract
    const flow = await ethers.getContractAt("Flow", token, signer)
    const escrow = await ethers.getContractAt("VotingEscrow", veContract, signer);

    const approveTx = await (await flow.approve(veContract, amount)).wait();
    console.log(approveTx);
    const createLockForTx = await (await escrow.create_lock_for(amount, duration, recipient)).wait();
    console.log(createLockForTx);
  });