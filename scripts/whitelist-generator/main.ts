import { Command } from 'commander'
import * as fs from 'fs'
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const program = new Command();
program
  .version('0.0.0')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a map of account addresses to string balances'
  )

program.parse(process.argv)

const options = program.opts()
const json = JSON.parse(fs.readFileSync(options.input, { encoding: 'utf8' }))

if (typeof json !== 'object') throw new Error('Invalid JSON')

const values: any[] = [];
for (const key in json) {
  values.push([key, json[key]]);
}

const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

const result: any = {
  root: tree.root,
};

for (const [i, v] of tree.entries()) {
  const proof = tree.getProof(i);
  result[v[0]] = {
    index: i,
    amount: v[1],
    proof: proof
  }
}

fs.writeFileSync("proof.json", JSON.stringify(result));
