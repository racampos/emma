const fs = require('fs');

async function main() {
  const Emma = await hre.ethers.getContractFactory("Emma");
  const emma = await Emma.deploy();

  await emma.deployed();

  console.log("Emma deployed to:", emma.address);

  const config = {
    address: emma.address
  }

  fs.writeFileSync("./app/__config.json", JSON.stringify(config, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
