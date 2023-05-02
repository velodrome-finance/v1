import { Command } from 'commander'
import { ethers } from "ethers"
import * as fs from 'fs'
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const conversionRate = 35714.2857143; // 1 ETH -> xxx VS

const program = new Command();
program
  .version('0.0.0')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a map of account addresses to eth amounts'
  )

program.parse(process.argv)

const options = program.opts()
const json = JSON.parse(fs.readFileSync(options.input, { encoding: 'utf8' }))

if (typeof json !== 'object') throw new Error('Invalid JSON')

const values: any[] = [];
for (const key in json) {
  values.push([key, ethers.utils.parseEther((parseFloat(json[key]) * conversionRate).toString())]);
}

const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

const result: any = {
  root: tree.root,
};

let totalAmount = 0;

for (const [i, v] of tree.entries()) {
  const proof = tree.getProof(i);
  result[v[0]] = {
    index: i,
    amount: v[1],
    proof: proof,
    decimalAmount: ethers.utils.formatEther(v[1]),
  }

  totalAmount += parseFloat(ethers.utils.formatEther(v[1]));
}

fs.writeFileSync("private_sale_proof.json", JSON.stringify(result));

console.log("Total sales amount: ", totalAmount);

const vsAmount = totalAmount * 0.8;
const lockedVsAmount = totalAmount * 0.2;
const maxBonusVsAmount = vsAmount * 0.3
console.log("Please transfer ", vsAmount + lockedVsAmount + maxBonusVsAmount, " VS to the merkle claim contract")
