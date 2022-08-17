let week = 1;
const emission = 99;
const tail_emission = 2;
const target_base = 100; // 2% per week target emission
const tail_base = 1000; // 0.2% per week target emission
let weekly = 15000000;
const lock = 86400 * 7 * 52 * 4;
let balanceOfContract = 0;
let veSupply = 140000000;
let totalSupply = 400000000;
let lockrate = 0.5;
let actualCirc = totalSupply - balanceOfContract - veSupply;

// calculate circulating supply as total token supply - locked supply
function circulating_supply() {
  return totalSupply - veSupply;
}

// emission calculation is 1% of available supply to mint adjusted by circulating / total supply
function calculate_emission() {
  return weekly * (emission / target_base);
}

// weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
function weekly_emission() {
  return Math.max(calculate_emission(), circulating_emission());
}

function circulating_emission() {
  return circulating_supply() * (tail_emission / tail_base);
}

function calculate_growth(minted) {
  return (
    minted *
    (veSupply / totalSupply) *
    (veSupply / totalSupply) *
    (veSupply / totalSupply) *
    0.5
  );
}
let data = [];

while (week < 900) {
  weekly = weekly_emission();
  _growth = calculate_growth(weekly);
  _required = weekly + _growth;
  _balanceOf = balanceOfContract;
  if (_balanceOf < _required) {
    totalSupply += _required;
  } else {
    balanceOfContract -= _required;
  }
  //adjust for ve balance
  veSupply += _growth + weekly * lockrate;
  emissionRate = weekly / totalSupply;
  actualCirc = totalSupply - balanceOfContract - veSupply;
  data.push([
    "week",
    week,
    "totalWeeklyEmissions",
    _required,
    "LPemissions",
    weekly,
    "veLockerRebase",
    _growth,
    "veSupply",
    veSupply,
    "locked",
    veSupply / totalSupply,
    "totalSupply",
    totalSupply,
    "actual circ",
    actualCirc + veSupply,
  ]);
  console.log(
    "week: ",
    week,
    " minted: ",
    weekly,
    " weekly: ",
    weekly,
    " totalSupply: ",
    totalSupply
  );
  week++;
}
