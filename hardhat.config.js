require('@nomiclabs/hardhat-waffle');
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0"
      },
      {
        version: "0.8.1"
      }
    ]
  }
  // networks: {
  //   localhost: {
  //     url: "http://localhost:8545"
  //   },
  //   rinkeby: {
  //     url: process.env.RINKEBY_URL,
  //     accounts: [process.env.PRIVATE_KEY]
  //   }
  // }
};