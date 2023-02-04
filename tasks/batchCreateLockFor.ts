import { task } from 'hardhat/config'
import fs from "fs";
import csv from "csv-parser";
const path = require("path");
const createCsvWriter = require('csv-writer').createObjectCsvWriter;

// SAMPLE command
// npx hardhat batch-create-lock-for --network arbitrumOne --token 0xC33f7f83CbB021846Cb9c58f2d8E3df428dbC8C1 --contract 0x10Df81252069C1095F541FAca61646cb9Ae76703
type LockDetails = {
  recipient: string,
  amountInMillion: string,
  durationInYear: string
}

const createLockDetailsList: LockDetails[] = []
const filePath = path.join(__dirname, "sample_partners.csv");
fs.createReadStream(filePath)
  .pipe(csv())
  .on('data', (data: LockDetails) => createLockDetailsList.push(data))
  .on('end', () => {
    console.log(createLockDetailsList.length);
  });

task('batch-create-lock-for', 'Creates lock for a recipient address')
  .addParam("token", "The flow token address")
  .addParam("contract", "The Voting Escrow's contract address")
  .setAction(async (
    taskArguments,
    { ethers }
  ) => {
    // Get signers
    const [signer] = await ethers.getSigners()

    // Get task arguments
    const { token, contract: veContract } = taskArguments;

    // Validate task arguments
    if (!ethers.utils.isAddress(token)) {
      throw new Error("Recipient address is not valid")
    }

    if (!ethers.utils.isAddress(veContract)) {
      throw new Error("Voting Escrow contract address is not valid")
    }

    // Get contract
    const flow = await ethers.getContractAt("Flow", token, signer)
    const escrow = await ethers.getContractAt("VotingEscrow", veContract, signer);

    // Approve VE escrow
    const approveTx = await (await flow.approve(veContract, ethers.constants.MaxUint256)).wait();
    console.log(approveTx);

    // Constants
    const TOKEN_DECIMALS = ethers.BigNumber.from('10').pow(
      ethers.BigNumber.from('18')
    );
    const MILLION = ethers.BigNumber.from('10').pow(
      ethers.BigNumber.from('6')
    );

    const succcessfulTxCsvWriter = createCsvWriter({
      path: path.join(__dirname, "log", "successful.csv"),
      header: [
        { id: 'recipient', title: 'recipient' },
        { id: 'txHash', title: 'txHash' },
      ]
    });

    const failedLockCsvWriter = createCsvWriter({
      path: path.join(__dirname, "log", "failed.csv"),
      header: [
        { id: 'recipient', title: 'recipient' },
        { id: 'amountInMillion', title: 'amountInMillion' },
        { id: 'durationInYear', title: 'durationInYear' }
      ]
    });

    let successful = 0;
    let failed = 0;

    for (let d of createLockDetailsList) {
      const { recipient, amountInMillion, durationInYear } = d
      console.log(recipient, amountInMillion, durationInYear);

      if (!ethers.utils.isAddress(d.recipient)) {
        throw new Error("Recipient address is not valid")
      }

      // Formatting amount
      const amount = ethers.BigNumber.from(amountInMillion)
        .mul(MILLION)
        .mul(TOKEN_DECIMALS);

      // Formatting duration
      const duration = Number(durationInYear) * 365 * 86400;

      console.log(`Creating Lock of ${amountInMillion} million for ${recipient} for ${durationInYear} years`)

      try {
        const createLockForTx = await (await escrow.create_lock_for(amount, duration, recipient)).wait();
        await succcessfulTxCsvWriter.writeRecords([
          {
            recipient,
            txHash: createLockForTx.transactionHash
          }
        ])
        successful += 1;
        console.log(`Successful for ${recipient}`);
      } catch (e) {
        failed += 1;
        await failedLockCsvWriter.writeRecords(d);
        console.log(`Failed for ${recipient}`);
      }
    }

    console.log(`Number of successful locks: ${successful}`);
    console.log(`Number of failed locks: ${failed}`);
  });