const TuneTrader = artifacts.require('./TuneTrader.sol')
const TuneTraderExchange = artifacts.require('./TuneTraderExchange.sol')
const ContractStorage = artifacts.require('./ContractStorage.sol')
const SongsLib = artifacts.require('./SongsLib.sol')

module.exports = function (deployer) {
  deployer.then(async () => {
    // DEPLOY LIB
    await deployer.deploy(SongsLib)
    await deployer.link(SongsLib, TuneTrader)

    // DEPLOY STORAGE
    await deployer.deploy(ContractStorage)
    let storageInstance = await ContractStorage.deployed()

    // DEPLOY MAIN TUNETRADER
    await deployer.deploy(TuneTrader, storageInstance.address)
    let tunetraderInstance = await TuneTrader.deployed()
    await storageInstance.authorizeAddress(tunetraderInstance.address)

    // DEPLOY TUNE TRADER EXCHANGE
    await deployer.deploy(TuneTraderExchange, storageInstance.address)
    let ttexchangeInstance = await TuneTraderExchange.deployed()
    await storageInstance.authorizeAddress(ttexchangeInstance.address)
  })
}
