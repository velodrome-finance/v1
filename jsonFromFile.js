// get json from exported.json file and convert to object

const fs = require('fs')

const jsonFromFile = () => {
  const data = fs.readFileSync('./exported.json')
  return JSON.parse(data)
}

// console.log(jsonFromFile())

// remove abi from the object

const removeAbi = obj => {
  const newObj = {}
  Object.keys(obj.contracts).forEach(key => {
    newObj[key] = obj.contracts[key].address
  })
  return newObj
}

const final = removeAbi(jsonFromFile())
console.log(final)
