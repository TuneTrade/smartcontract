pragma solidity 0.5.0;

// TOKEN

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
	/**
	* @dev Multiplies two unsigned integers, reverts on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	/**
	* @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Adds two unsigned integers, reverts on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	/**
	* @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
	* reverts when dividing by zero.
	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
	function transfer(address to, uint256 value) external returns (bool);

	function approve(address spender, uint256 value) external returns (bool);

	function transferFrom(address from, address to, uint256 value) external returns (bool);

	function totalSupply() external view returns (uint256);

	function balanceOf(address who) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ISongERC20 interface
 */
interface ISongERC20 {
	function assignICOTokens(address _ico, uint256 _amount) external;

	function setDetails(
		string calldata,
		string calldata,
		uint8 _entryType,
		string calldata,
		string calldata,
		string calldata,
		string calldata
	)
		external returns (bool);

	function getDetails() external view returns (
		string memory,
		string memory,
		uint8,
		string memory,
		string memory,
		string memory,
		string memory,
		uint256
	);

	function getTokenDetails() external view returns (
		address,
		uint256,
		string memory,
		string memory,
		uint256,
		uint256
	);

    function getOwner() external view returns (address);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowed;

	uint256 private _totalSupply;

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param owner The address to query the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address owner) public view returns (uint256) {
		return _balances[owner];
	}

	/**
	 * @dev Function to check the amount of tokens that an owner allowed to a spender.
	 * @param owner address The address which owns the funds.
	 * @param spender address The address which will spend the funds.
	 * @return A uint256 specifying the amount of tokens still available for the spender.
	 */
	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowed[owner][spender];
	}

	/**
	* @dev Transfer token for a specified address
	* @param to The address to transfer to.
	* @param value The amount to be transferred.
	*/
	function transfer(address to, uint256 value) public returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	/**
	 * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	 * Beware that changing an allowance with this method brings the risk that someone may use both the old
	 * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	 * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 * @param spender The address which will spend the funds.
	 * @param value The amount of tokens to be spent.
	 */
	function approve(address spender, uint256 value) public returns (bool) {
		require(spender != address(0));

		_allowed[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	/**
	 * @dev Transfer tokens from one address to another.
	 * Note that while this function emits an Approval event, this is not required as per the specification,
	 * and other compliant implementations may not emit the event.
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 the amount of tokens to be transferred
	 */
	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
		_transfer(from, to, value);
		emit Approval(from, msg.sender, _allowed[from][msg.sender]);
		return true;
	}

	/**
	 * @dev Increase the amount of tokens that an owner allowed to a spender.
	 * approve should be called when allowed_[_spender] == 0. To increment
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * Emits an Approval event.
	 * @param spender The address which will spend the funds.
	 * @param addedValue The amount of tokens to increase the allowance by.
	 */
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		require(spender != address(0));

		_allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
		emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
		return true;
	}

	/**
	 * @dev Decrease the amount of tokens that an owner allowed to a spender.
	 * approve should be called when allowed_[_spender] == 0. To decrement
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * Emits an Approval event.
	 * @param spender The address which will spend the funds.
	 * @param subtractedValue The amount of tokens to decrease the allowance by.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		require(spender != address(0));

		_allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
		emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
		return true;
	}

	/**
	* @dev Transfer token for a specified addresses
	* @param from The address to transfer from.
	* @param to The address to transfer to.
	* @param value The amount to be transferred.
	*/
	function _transfer(address from, address to, uint256 value) internal {
		require(to != address(0));

		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);
		emit Transfer(from, to, value);
	}

	/**
	 * @dev Internal function that mints an amount of the token and assigns it to
	 * an account. This encapsulates the modification of balances such that the
	 * proper events are emitted.
	 * @param account The account that will receive the created tokens.
	 * @param value The amount that will be created.
	 */
	function _mint(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.add(value);
		_balances[account] = _balances[account].add(value);
		emit Transfer(address(0), account, value);
	}

	/**
	 * @dev Internal function that burns an amount of the token of a given
	 * account.
	 * @param account The account whose tokens will be burnt.
	 * @param value The amount that will be burnt.
	 */
	function _burn(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value);
		emit Transfer(account, address(0), value);
	}

	/**
	 * @dev Internal function that burns an amount of the token of a given
	 * account, deducting from the sender's allowance for said account. Uses the
	 * internal burn function.
	 * Emits an Approval event (reflecting the reduced allowance).
	 * @param account The account whose tokens will be burnt.
	 * @param value The amount that will be burnt.
	 */
	function _burnFrom(address account, uint256 value) internal {
		_allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
		_burn(account, value);
		emit Approval(account, msg.sender, _allowed[account][msg.sender]);
	}
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
	/**
	 * @dev Burns a specific amount of tokens.
	 * @param value The amount of token to be burned.
	 */
	function burn(uint256 value) public {
		_burn(msg.sender, value);
	}

	/**
	 * @dev Burns a specific amount of tokens from the target address and decrements allowance
	 * @param from address The account whose tokens will be burned.
	 * @param value uint256 The amount of token to be burned.
	 */
	function burnFrom(address from, uint256 value) public {
		_burnFrom(from, value);
	}
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev ERC20Detailed Constructor
	 */
	constructor (string memory name, string memory symbol, uint8 decimals) public {
		_name = name;
		_symbol = symbol;
		_decimals = decimals;
	}

	/**
	 * @return the name of the token.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @return the symbol of the token.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @return the number of decimals of the token.
	 */
	function decimals() public view returns (uint8) {
		return _decimals;
	}
}

/**
 * @title SongERC20 token
 * @dev The token of Song which contain info about song and about the ERC20 basic token
 */
contract SongERC20 is ERC20Detailed, ERC20Burnable, ISongERC20 {
	address public owner;
	address public tuneTrader;

	uint256 public id;
	uint256 public creationTime;

	string public author;
	string public genre;
	string public website;
	string public soundcloud;
	string public youtube;
	string public description;

	bool public icoTokensAssigned;

	enum Type { Song, Band, Influencer }
	Type public entryType;

	/**
	 * @dev modifier, that only the tune trader address can call method
	 */
	modifier onlyTuneTrader {
		require(msg.sender == tuneTrader, "onlyTuneTrader: Only the contract administrator can execute this function");
		_;
	}

	/**
	 * @dev SongERC20 Constructor
	 */
	constructor (
		address _owner,
		uint256 _supply,
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _id
	)
		public ERC20Detailed(_name, _symbol, _decimals)
	{
		id = _id;
		owner = _owner;
		creationTime = now;
		_mint(_owner, _supply);
		tuneTrader = msg.sender;
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	/**
	 * @dev set details of songERC20 token
	 * @return true if transaction successed
	 */
	function setDetails(
		string calldata _author,
		string calldata _genre,
		uint8 _entryType,
		string calldata _website,
		string calldata _soundcloud,
		string calldata _youtube,
		string calldata _description
	)
		external returns (bool)
	{
		author = _author;
		genre = _genre;
		entryType = Type(_entryType);
		website = _website;
		soundcloud = _soundcloud;
		youtube = _youtube;
		description = _description;

		return true;
	}

	/**
	 * @dev the method will call the tokenFallback method from TTPositionManager contract
	 */
	function transfer(address to, uint256 value) public returns (bool) {
		super.transfer(to,value);

		if (_isContract(to)) {
			ITuneTraderManager(to).tokenFallback(msg.sender, value);
		}

		return true;
	}

	/**
	 * @dev assing tokens to ICO contract
	 */
	function assignICOTokens(address _ico, uint256 _amount) external onlyTuneTrader {
		require(icoTokensAssigned == false, "assignICOTokens: TuneTrader already has assigned the tokens");

		_transfer(owner, _ico, _amount);
		icoTokensAssigned = true;
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	/**
	 * @dev check if the _addr is a contract or just a basic address
	 */
	function _isContract(address _addr) private view returns (bool) {
		uint256 length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}

		return (length > 0);
	}
	
	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	/**
	 * @dev get details of SongERC20 token
	 */
	function getDetails() external view returns (
		string memory,
		string memory,
		uint8,
		string memory,
		string memory,
		string memory,
		string memory,
		uint256
	) {
		return (
			author,
			genre,
			uint8(entryType),
			website,
			soundcloud,
			youtube,
			description,
			id
		);
	}

	/**
	 * @dev get details of ERC20 standard of SongERC20 token
	 */
	function getTokenDetails() external view returns (
		address,
		uint256,
		string memory,
		string memory,
		uint256,
		uint256
	) {
		return (
			owner,
			totalSupply(),
			name(),
			symbol(),
			decimals(),
			creationTime
		);
	}
	
	function getOwner() external view returns (address) {
	    return owner;
	}
}

// CROWDSALE

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor (address owner) internal {
		_owner = owner;
		emit OwnershipTransferred(address(0), _owner);
	}

	/**
	 * @return the address of the owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(isOwner());
		_;
	}

	/**
	 * @return true if `msg.sender` is the owner of the contract.
	 */
	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	/**
	 * @dev Allows the current owner to relinquish control of the contract.
	 * @notice Renouncing to ownership will leave the contract without an owner.
	 * It will not be possible to call the functions with the `onlyOwner`
	 * modifier anymore.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

/**
 * @title SongCrowdSale
 * @dev This is Song ICO sale contract based on Open Zeppelin Crowdsale contract.
 * @dev It's purpose is to sell song tokens in main sale and presale.
 */
contract SongCrowdSale is Ownable {
	using SafeMath for uint256;

	uint256 public rate;
	uint256 public weiRaised;

	// number of tokens reserved for a team. It is not possible to sell them.
	uint256 public teamTokens;

    // minimum amount of tokens sold in presale. If not sold then it is not possible to go to main sale
	uint256 public minPreSaleETH;

	// minimum number of tokens which have to be sold in MainSale so it is successfull. If not then contributors are allowed to have a refund.
	uint256 public minMainSaleETH;

    // maximum Ether contribution. Sale contract can't sell tokens for more than this number.
	uint256 public maxEth;

	// maximum number of tokens which can be sold.
	uint256 public maxCap;

	// minimum number of tokens which have to be sold or sale will be cancelled.
	uint256 public minCap;

    // main sale campaign duration in days
	uint256 public durationDays;

	// presale capaign duration in days
	uint256 public preSaleDays;

	uint256 public preSaleEnd;
	uint256 public saleEnd;

	uint256 public bonusPresalePeriod;
	uint256 public firstPeriod;
	uint256 public secondPeriod;
	uint256 public thirdPeriod;

	uint256 public bonusPreSaleValue;
	uint256 public bonusFirstValue;
	uint256 public bonusSecondValue;
	uint256 public bonusThirdValue;

	uint256 public saleStart;

	// 0 - presale, 1 - first period, 2-second period, 3 - third period
	uint256 public volume;

	uint256 public phase = 1;

	// The token being sold
	IERC20 public token;

	// Address where funds will collected
	address payable public wallet;

	bool public closed;
	bool public refundAvailable;
	bool public isRefundable;

	enum State { PreSale, Campaign, Ended, Refund, Closed }

	mapping (address => uint256) public collectedFunds;

	bool public debug = true;
	uint256 public testNow = 0;

	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount amount of tokens purchased
	 */
	event TokenPurchase (
		address indexed purchaser,
		address indexed beneficiary,
		uint256 value,
		uint256 amount
	);

	/**
	 * @dev SongCrowdsale Constructor
	 */
	constructor (
		uint256 _rate,
		address payable _wallet,
		IERC20 _song,
		uint256 _teamTokens,
		uint256[] memory constraints,
		uint256 _duration,
		uint256 _presaleduration,
		uint8[] memory bonuses,
		address _owner
	) public Ownable(_owner) {
		require(_rate > 0, "SongCrowdSale: the rate should be bigger then zero");
		require(_wallet != address(0), "SongCrowdSale: invalid wallet address");
		require(address(_song) != address(0), "SongCrowdSale: invalid SongERC20 token address");

		rate = _rate;
		wallet = _wallet;
		token = _song;
		minPreSaleETH = constraints[0];
		minMainSaleETH = constraints[1];
		maxEth = constraints[2];
		maxCap = constraints[3];
		minCap = constraints[4];
		durationDays = _duration;
		preSaleDays = _presaleduration;
		saleStart = _now();
		preSaleEnd = saleStart + (preSaleDays * 24 * 60 * 60);
		saleEnd = preSaleEnd + (durationDays * 24 * 60 * 60);
		teamTokens = _teamTokens;

		if (bonuses.length == 8) {
			// The bonus periods for presale and main sale must be smaller or equal than presale and mainsail themselves
			require(bonuses[0] <= preSaleDays, "SongCrowdSale: the presale bonus period must be smaller than presale period");
			require((bonuses[2] + bonuses [4] + bonuses[6]) <= durationDays, "SongCrowdSale: the main sale bonus period must be smaller then main sale period");

			_defineBonusValues(bonuses[1], bonuses[3], bonuses[5], bonuses[7]);
			_defineBonusPeriods(bonuses[0], bonuses[2], bonuses[4], bonuses[6]);
		}

		if (minPreSaleETH > 0 || minMainSaleETH > 0) {
			isRefundable = true;
		}
	}

	/**
	 * @dev fallback function ***DO NOT OVERRIDE***
	 * Note that other contracts will transfer fund with a base gas stipend
	 * of 2300, which is not enough to call buyTokens. Consider calling
	 * buyTokens directly when purchasing tokens from a contract.
	 */
	function () external payable {
		buyTokens(msg.sender);
	}

	/**
	 * @dev low level token purchase ***DO NOT OVERRIDE***
	 * @param _beneficiary Address performing the token purchase
	 */
	function buyTokens(address _beneficiary) public payable {
		_preValidatePurchase(_beneficiary, msg.value);

		if (refundAvailable == true || _campaignState() == State.Refund) {
			if (refundAvailable == false) {
				refundAvailable = true;
			}

			msg.sender.transfer(msg.value);
		} else {
			uint256 weiAmount = msg.value;
			uint256 tokens = _getTokenAmount(weiAmount);

			_processPurchase(_beneficiary, tokens);
			_updatePurchasingState(_beneficiary, weiAmount, tokens);
			_postValidatePurchase();

			emit TokenPurchase(
				msg.sender,
				_beneficiary,
				weiAmount,
				tokens
			);
		}
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	/**
	 * @dev refund invested amount if the crowdsale has finished and the refund is available
	 */
	function refund() external {
		require(collectedFunds[msg.sender] > 0, "refund: user must have some funds to get refund");
		require(refundAvailable || _campaignState() == State.Refund, "refund: refund must be available or Campaing must be in Refund State");

		uint256 toRefund = collectedFunds[msg.sender];
		collectedFunds[msg.sender] = 0;

		if (refundAvailable == false) {
			refundAvailable = true;
		}

		msg.sender.transfer(toRefund);
	}


	/**
	 * @dev only the owner can change the wallet address
	 * @return true if transaction successed
	 */
	function changeWallet(address payable _newWallet) public onlyOwner returns (bool) {
		require(_newWallet != address(0), "changeWallet: the new wallet address is invalid");
		wallet = _newWallet;

		return true;
	}

	/**
	 * @dev the wallet address can withdraw all funds in this contract after if the crowdasle finished
	 * @return true if transaction successed
	 */
	function withdrawFunds() public returns (bool) {
		require(msg.sender == wallet, "withdrawFunds: only wallet address can withdraw funds");
		require(_campaignState() == State.Ended, "withdrawFunds: sale must be ended to receive funds");

		wallet.transfer(address(this).balance);
		closed = true;

		return true;
	}

	/**
	 * @dev set the test block.timestamp value (debug mode only)
	 */
	function setTestNow(uint256 _testNow) public onlyOwner {
		testNow = _testNow;
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	/**
	 * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
	 * Use `super` in contracts that inherit from Crowdsale to extend their validations.
	 * Example from CappedCrowdsale.sol's _preValidatePurchase method:
	 *     super._preValidatePurchase(beneficiary, weiAmount);
	 *     require(weiRaised().add(weiAmount) <= cap);
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) private view {
		require(_beneficiary != address(0), "_preValidatePurchase: beneficiary can not be the zero address");
		require(_weiAmount > 0, "_preValidatePurchase: wei Amount must be greater than zero");
		require(_campaignState() != State.Ended, "_preValidatePurchase: the campaign is already ended");
		require(refundAvailable == false, "_preValidatePurchase: the sale is in refund state");
	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
	 * tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) private {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
	 * its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) private {
		token.transfer(_beneficiary, _tokenAmount);

		if (isRefundable == false) {
			_forwardFunds();
		}
	}

	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds() private {
		wallet.transfer(msg.value);
	}

	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
	 * conditions are not met.
	 */
	function _postValidatePurchase() private view {
		if (maxEth > 0) {
			require(weiRaised < maxEth, "_postValidatePurchase: can not raise more than the max Eth");
		}

		if (maxCap > 0) {
			require(volume < maxCap, "_postValidatePurchase: can not sell more tokens than the max cap");
		}

		require(teamTokens <= _balanceOf(address(this)), "_postValidatePurchase: sale is not possible because there must be enough tokens for a team");
	}

	/**
	 * @dev Override for extensions that require an internal state to check for validity (current user contributions,
	 * etc.)
	 * @param _beneficiary Address receiving the tokens
	 * @param _weiAmount Value in wei involved in the purchase
	 * @param _tokenAmount value which investor bought
	 */
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) private {
		volume = volume.add(_tokenAmount);
		weiRaised = weiRaised.add(_weiAmount);
		collectedFunds[_beneficiary] = collectedFunds[_beneficiary].add(_weiAmount);
	}

	/**
	 * @return the state of the campaign
	 */
	function _campaignState() private view returns (State _state) {
		if (refundAvailable == true) {
			return State.Refund;
		}

		if (closed) {
			return State.Closed;
		}

		if (_now() <= preSaleEnd) {
			return State.PreSale;
		}

		if (_now() > preSaleEnd && _now() <= saleEnd) {
			if (weiRaised < minPreSaleETH) {
				return State.Refund;
			} else {
				return State.Campaign;
			}
		}
		if (weiRaised < minMainSaleETH) {
			return State.Refund;
		}

		if (minCap > 0 && volume < minCap && _now() > saleEnd) {
			return State.Refund;
		}

		return State.Ended;
	}

	/**
	 * @return the value of tokens based on the _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
		uint256 tokenAmount = _weiAmount.mul(rate);
		return tokenAmount.mul(100 + _currentBonusValue()).div(100);
	}

	/**
	 * @dev set the bonus values
	 */
	function _defineBonusValues(uint8 value1, uint8 value2, uint8 value3, uint8 value4) private returns (bool) {
		bonusPreSaleValue = value1;
		bonusFirstValue = value2;
		bonusSecondValue = value3;
		bonusThirdValue = value4;

		return true;
	}

	/**
	 * @dev set the bonus periods
	 */
	function _defineBonusPeriods(uint8 period1,uint8 period2,  uint8 period3, uint8 period4) private returns (bool) {
		bonusPresalePeriod = period1;
		firstPeriod = period2;
		secondPeriod = period3;
		thirdPeriod = period4;

		return true;
	}

	/**
	 * @return the current timestamp
	 */
	function _now() private view returns (uint256) {
		if (debug == true) {
			return testNow;
		} else {
			return block.timestamp;
		}
	}

	/**
	 * @dev It will fail if for any reason now is smaller than saleStart
	 * @return Return bonus value for current moment in %. If sale is already out of bonus period it will return 0.
	 */
	function _currentBonusValue() private view returns (uint256) {
		if (_campaignState() == State.PreSale) {
			if (_now() <= (saleStart + (bonusPresalePeriod * 24 * 60 * 60))) {
				return bonusPreSaleValue;
			}

			return 0;
		}

		if (_campaignState() == State.Campaign) {
			if (_now() > ((preSaleEnd + (firstPeriod + secondPeriod + thirdPeriod) * 24 * 3600 ))) return 0;
			if (_now() > ((preSaleEnd + (firstPeriod + secondPeriod) * 24 * 3600 ))) return bonusThirdValue;
			if (_now() > ((preSaleEnd + (firstPeriod) * 24 * 3600 ))) return bonusSecondValue;
			if (_now() > (preSaleEnd)) return bonusFirstValue;

			return 0;
		}

		return 0;
	}

	/**
	 * @return the token balance of the _who
	 */
	function _balanceOf(address _who) private view returns (uint256) {
		return token.balanceOf(_who);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	/**
	 * @return the token address
	 */
	function getToken() external view returns (address) {
		return address(token);
	}

	/**
	 * @return the token balance of this contract without team tokens amount
	 */
	function getBalance() external view returns (uint256) {
		return token.balanceOf(address(this)).sub(teamTokens);
	}

	/**
	 * @return the current state of this crowdsale
	 */
	function getCampaignState() external view returns (string memory) {
		if (_campaignState() == State.PreSale) return "Presale";
		if (_campaignState() == State.Refund) return "Refund";
		if (_campaignState() == State.Campaign) return "Main Sale";
		if (_campaignState() == State.Ended) return "Ended";
		if (_campaignState() == State.Closed) return "Closed";
	}

	/**
	 * @dev the rate is defined as TOKENS ( full tokens not mini tokens ) per ETH. To calculate minitokens per wei we have to
	 * multiply it by 10 to power of decimals and divide by 10 to power of 18 ( because there is 10^18 weis in ETH)
	 * and then we can multiply it by amount of wei to get number of tokens.
	 * token_amount = ((price * 10**decimals) * weiAmount) / 10**18
	 * @return calculated value for this _weiAmount, _decimals and _rate
	 */
	function getTokensForWei(uint256 _weiAmount, uint256 _decimals, uint256 _rate) external pure returns (
		uint256,
		uint256,
		uint256,
		uint256
	) {
		uint256 tokensAmount;
		uint256 minitokensAmount;
		uint256 base = 10;

		minitokensAmount = _rate.mul(base**_decimals).mul(_weiAmount).div(10**18);
		tokensAmount = minitokensAmount.div(base**_decimals);

		uint256 valueInWei = minitokensAmount.mul(10**18).div(10**_decimals).div(_rate);
		uint256 weiToReturn = _weiAmount.sub(valueInWei);

		return (
			minitokensAmount,
			tokensAmount,
			valueInWei,
			weiToReturn
		);
	}

	/**
	 * @return the information about the crowdsale sale
	 */
	function getSaleInformation() external view returns (
		uint256,
		address,
		address,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256
	) {
		return (
			rate,
			wallet,
			address(token),
			teamTokens,
			minPreSaleETH,
			minMainSaleETH,
			maxEth,minCap,
			durationDays,
			preSaleDays
		);
	}

	/**
	 * @return the stats of the current state
	 */
	function getStats() external view returns (
		uint256,
		uint256,
		uint8,
		uint256
	) {
		uint256 bonus = _currentBonusValue();
		return (
			weiRaised,
			volume,
			uint8(phase),
			bonus
		);
	}
}

// TUNETRADER

/**
 * @title SongsLib
 */
library SongsLib {
	function removeSong(IContractStorage DS, address _song, address contractOwner) public {
		require(address(DS) != address(0), "removeSong: contractStorage address is zero");
		require(_song != address(0), "removeSong: song Address can not be zero");
		require(DS.getBool(DS.key(_song, "songExist")), "removeSong: song with this address is not on the list");

		//REMOVE SONG TOKEN
		address songOwner = DS.getAddress(DS.key(_song, "songOwner"));
		require(msg.sender == songOwner || msg.sender == contractOwner, "removeSong: song can be deleted by Administrator or Song Owner only");

		//REMOVE SONG FROM GENERAL SONGS LIST
		uint256 index = DS.getUint(DS.key(_song, "songIndex")) - 1;
		uint256 maxIndex = DS.getAddressTableLength(DS.key("Songs")) - 1;
		address miAddress = DS.getAddressFromTable(DS.key("Songs"), maxIndex);

		DS.setAddressInTable(DS.key("Songs"), index, miAddress);

		if (index < maxIndex) {
			DS.setUint(DS.key(miAddress, "songIndex"), index + 1);
		}

		DS.delLastAddressInTable(DS.key("Songs"));
		DS.delUint(DS.key(_song, "songIndex"));
		DS.setBool(DS.key(_song, "songExist"), false);
	}

	function getSongsLength(IContractStorage DS, address _song) public view returns (uint256, uint256, address) {
		uint256 maxIndex = DS.getAddressTableLength(DS.key("Songs")) - 1;
		address miAddress = DS.getAddressFromTable(DS.key("Songs"), maxIndex);
		uint256 index = DS.getUint(DS.key(_song, "songIndex")) - 1;

		return (
			maxIndex,
			index,
			miAddress
		);
	}
}

/**
 * @title ITuneTraderManager
 * @dev Interface for interacting with TTManager contract
 */
interface ITuneTraderManager {
  function tokenFallback(address _tokenSender, uint256 _value) external;
}

/**
 * @title TuneTrader
 */
contract TuneTrader is ITuneTraderManager {
	IContractStorage public DS;
	address payable public owner;

	enum Type { Song, Band, Influencer }

	/**
	 * @dev TuneTrader Constructor
	 */
	constructor (IContractStorage _storage) public {
		owner = msg.sender;
		DS = _storage;
		DS.registerName("ContractOwner");
		DS.registerName("userToSongICO");
		DS.registerName("songToSale");
		DS.registerName("Songs");
		DS.registerName("songOwner");
		DS.registerName("songExist");
		DS.registerName("songIndex");
		DS.registerName("usersSongs");
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addICO(
		address payable _wallet,
		uint256 _teamTokens,
		uint256[] memory  constraints,
		uint256 _price,
		uint256 _durationDays,
		uint256 _presaleDuration,
		uint8[] memory _bonuses,
		uint256 assignedTokens
	)
		public
  {
		require(DS.getAddress(DS.key(msg.sender, "userToSongICO")) != address(0), "addICO: no Song assigned to this msg.sender to create ICO");

		SongERC20 songToken = SongERC20(DS.getAddress(DS.key(msg.sender, "userToSongICO")));
		SongCrowdSale saleContract = new SongCrowdSale(
			_price,
			_wallet,
			songToken,
			_teamTokens,
			constraints,
			_durationDays,
			_presaleDuration,
			_bonuses,
			msg.sender
		);

		songToken.assignICOTokens(address(saleContract), assignedTokens);

		DS.setAddress(DS.key(address(songToken), "songToSale"), address(saleContract));
		DS.setAddress(DS.key(msg.sender, "userToSongICO"), address(0));
	}

	function addSong(
		string memory _name,
		string memory _author,
		string memory _genre,
		uint8 _entryType,
		string  memory _website,
		uint256 _totalSupply,
		string memory _symbol,
		string memory _description,
		string memory _soundcloud,
		string memory _youtube,
		bool _ico,
		uint8 _decimals,
		uint256 _id
	)
		public
	{
		SongERC20 song = new SongERC20(msg.sender, _totalSupply, _name, _symbol, _decimals, _id);
		song.setDetails(_author, _genre, _entryType, _website, _soundcloud, _youtube, _description);

		uint256 index = DS.pushAddress(DS.key('Songs'), address(song));

		DS.setAddress(DS.key(address(song), "songOwner"), msg.sender);
		DS.setBool(DS.key(address(song), "songExist"), true);
		DS.setUint(DS.key(address(song), "songIndex"), index);

		if (_ico) {
			DS.setAddress(DS.key(msg.sender, 'userToSongICO'), address(song));
		}

		DS.pushAddress(DS.key(msg.sender, "usersSongs"), address(song));
	}

	function removeSong(address _song) external {
		require(_song != address(0), "removeSong: invalid song address");
		SongsLib.removeSong(DS, _song, owner);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getSongs() external view returns (address[] memory) {
		return DS.getAddressTable(DS.key('Songs'));
	}

	function getMySongs() external view returns (address[] memory) {
		return DS.getAddressTable(DS.key(msg.sender, "usersSongs"));
	}

	function getSongsLength(address song) external view returns (uint, uint, address) {
		return SongsLib.getSongsLength(DS, song);
	}

	function getICO(address song) external view returns (address) {
		require(DS.getAddress(DS.key(song, "songToSale")) != address(0), "getICO: there is no sale for this song");
		return DS.getAddress(DS.key(song, "songToSale"));
	}

	function getContractOwner() public view returns (address payable) {
		return owner;
	}
}

// CONTRACT STORAGE

/**
 * @title IContractStorage
 * @dev Interface for interacting with ContractStorage contract
 */
interface IContractStorage {
	function getBool(bytes32 _key) external view returns (bool);
	function getAddress(bytes32 _key) external view returns (address);
	function getUint(bytes32 _key) external view returns (uint256);

	function setBool(bytes32 _key, bool val) external;
	function setAddress(bytes32 _key, address val) external;
	function setUint(bytes32 _key, uint256 val) external;

	function delBool(bytes32 _key) external;
	function delAddress(bytes32 _key) external;
	function delUint(bytes32 _key) external;

	function pushAddress(bytes32 key, address val) external returns (uint256);
	function getAddressTable(bytes32 key) external view returns (address[] memory);
	function getAddressFromTable(bytes32 key, uint256 index) external view returns (address);
	function setAddressInTable(bytes32 key, uint256 index, address val) external;
	function getAddressTableLength(bytes32 key) external view returns (uint256);
	function delLastAddressInTable(bytes32 key) external returns (uint256);

	function key(string calldata name) external view returns (bytes32);
	function key(uint256 index,string calldata name) external view returns (bytes32);
	function key(address adr,string calldata name) external view returns (bytes32);

	function registerName(string calldata name) external;
}

/**
 * @title ContractStorage
 */
contract ContractStorage is Ownable, IContractStorage {
	mapping (address => bool) public authorizedAddress;
	mapping (bytes32 => bool) public boolStorage;
	mapping (bytes32 => address) public addressStorage;
	mapping (bytes32 => uint256) public uintStorage;
	mapping (bytes32 => address[]) public addressTable;
	mapping (string => bool) internal varNames;

	event UnauthorizedAccess(address account);
	event AuthorizeAddress(address account);

	modifier onlyAuthorized() {
		if (isOwner() == false && isAddressAuthorized(msg.sender) == false) {
			emit UnauthorizedAccess(msg.sender);
		}

		require(isOwner() == true || isAddressAuthorized(msg.sender) == true, "onlyAuthorized: the sender is not authorized or not the owner for using the ContractStorage");
		_;
	}

    /**
	 * @dev ContractStorage Constructor
	 */
	constructor (IContractStorage _storage) public Ownable(msg.sender) {}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function authorizeAddress(address account) external onlyOwner {
		authorizedAddress[account] = true;
		emit AuthorizeAddress(account);
	}

	function removeAuthorizedAddress(address account) external onlyOwner {
		authorizedAddress[account] = false;
	}

	function registerName(string calldata name) external {
		require(varNames[name] == false, _error("registerName: variable is registered: ", name));
		varNames[name] = true;
	}

	function setBool(bytes32 _key, bool value) external onlyAuthorized {
		boolStorage[_key] = value;
	}

	function setAddress(bytes32 _key, address account) external onlyAuthorized {
		addressStorage[_key] = account;
	}

	function setUint(bytes32 _key, uint256 value) external onlyAuthorized {
		uintStorage[_key] = value;
	}

	function setAddressInTable(bytes32 _key, uint256 index, address account) external onlyAuthorized {
		addressTable[_key][index] = account;
	}

	function pushAddress(bytes32 _key, address account) external onlyAuthorized returns (uint256) {
		addressTable[_key].push(account);

		return addressTable[_key].length;
	}

	function delLastAddressInTable(bytes32 _key) external onlyAuthorized returns (uint256) {
		addressTable[_key].length--;

		return addressTable[_key].length;
	}

	function delBool(bytes32 _key) external onlyAuthorized {
		delete boolStorage[_key];
	}

	function delAddress(bytes32 _key) external onlyAuthorized {
		delete addressStorage[_key];
	}

	function delUint(bytes32 _key) external onlyAuthorized {
		delete uintStorage[_key];
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _error(string memory text, string memory variable) private pure returns (string memory) {
		bytes memory message = abi.encodePacked(text, variable);

		return string(message);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function isAddressAuthorized(address account) public view returns (bool) {
		return authorizedAddress[account];
	}

	function key(string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: variable name not registered:", name));
		return keccak256(abi.encodePacked(name));
	}

	function key(uint256 index, string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: ariable name not registered:", name));
		return keccak256(abi.encodePacked(name, index));
	}

	function key(address account, string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: ariable name not registered:", name));
		return keccak256(abi.encodePacked(name, account));
	}

	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	function getUint(bytes32 _key) external view returns (uint256) {
		return uintStorage[_key];
	}

	function getAddressTable(bytes32 _key) external view returns (address[] memory) {
		return addressTable[_key];
	}

	function getAddressFromTable(bytes32 _key, uint256 index) external view returns (address) {
		return addressTable[_key][index];
	}

	function getAddressTableLength(bytes32 _key) external view returns (uint256) {
		return addressTable[_key].length;
	}
}

// TUNETRADER EXCHANGE

/**
 * @title ITuneTraderExchange
 */
interface ITuneTraderExchange {
	function terminatePosition(bool closedOrCancelled) external;
}

/**
 * @title TTPositionManager
 */
contract TTPositionManager {
	uint256 public cost;
	uint256 public volume;
	uint256 public created;

	enum Position { Buy, Sell }
	Position public position;

	IERC20 public token;

	address payable owner;
	address public tokenExchange;
	address public tokenReceiver;

	event PositionClosed();
	event PositionCancelled();
	event ReceivedPayment(uint256 weiAmount, address from);
	event ReceivedTokens(uint256 tokenAmount, address tokenOwner, address from);

	/**
	 * @dev TTPositionManager Constructor
	 */
	constructor (address _token, uint256 _volume, bool _isBuyPosition, uint256 _cost, address payable _owner) public payable {
		require(_isBuyPosition == false || msg.value == _cost, "TTPositionManager: the buying positions must include some ETH in the msg");

		owner = _owner;
		token = IERC20(_token);
		volume = _volume;
		position = _isBuyPosition ? Position.Buy : Position.Sell;
		cost = _cost;
		created = block.timestamp;
		tokenExchange = msg.sender;
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function buyTokens() external payable {
		require(position == Position.Sell, "buyTokens: you can buy tokens only from selling positions");
		require(token.balanceOf(address(this)) == volume, "buyTokens: tokens must be already transfered");
		require(msg.value == cost, "buyTokens: you must send exact amount of ETH to buy tokens");

		token.transfer(msg.sender, volume);
		owner.transfer(msg.value);

		emit ReceivedPayment(msg.value, msg.sender);
		emit PositionClosed();

		_removeFromExchange();
	}

	function tokenFallback(address payable _tokenSender, uint256 _value) external {
		require(msg.sender == address(token), "tokenFallback: tokens can be accepted only from designated token contract");

		uint256 balance = token.balanceOf(address(this));
		require(balance == volume, "tokenFallback: contract only accepts exact token amount equal to volume");

		if (position == Position.Buy) {
			require(address(this).balance == cost, "tokenFallback: ETH to buy tokens must be already transfered to the contract");

			// transfering the funds to the seller and to the buyer
			token.transfer(owner, volume);
			_tokenSender.transfer(cost);

			emit PositionClosed();
			emit ReceivedTokens(balance, _tokenSender, msg.sender);

			_removeFromExchange();
		} else {
			emit ReceivedTokens(balance, _tokenSender, msg.sender);
		}
	}

	function cancelPosition() external {
		require(msg.sender == owner, "cancelPosition: only the owner can call this method");

		uint256 balance = token.balanceOf(address(this));
		if (position == Position.Buy) {
			//buyig position. we have to send ETHEREUM back to the owner.
			//the question is what to do when by any chance there are tokens from token contract on this position.
			// We send it to Token Exchange Contract for manual action to be taken.
			if (balance > 0) {
				token.transfer(tokenExchange, balance);
			}
		} else {
			//this is the "Sell" position, sending back all tokens to the owner.
			token.transfer(owner, balance);
		}

		ITuneTraderExchange(tokenExchange).terminatePosition(false);

		emit PositionCancelled();

		selfdestruct(owner);
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _removeFromExchange() private {
		ITuneTraderExchange(tokenExchange).terminatePosition(true);
		selfdestruct(owner);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getPositionData() external view returns (
		address _token,
		uint256 _volume,
		bool _buyPosition,
		uint256 _created,
		uint256 _cost,
		address payable _customer,
		address _managerAddress,
		bool _active,
		uint256 _tokenBalance,
		uint256 _weiBalance
	) {
		bool active;
		uint256 weiBalance = address(this).balance;
		uint256 tokenBalance = token.balanceOf(address(this));

		if (position == Position.Buy) {
			// this a position when somebody wants to buy tokens. They have to send ETH to make it happen.
			active = weiBalance >= cost ? true : false;
		} else {
			// this is a position when somebody wants to sell tokens.
			active = tokenBalance >= volume ? true : false;
		}

		return (
			address(token),
			volume,
			position == Position.Buy,
			created,
			cost,
			owner,
			address(this),
			active,
			tokenBalance,
			weiBalance
		);
	}
}

/**
 * @title TuneTraderExchange
 */
contract TuneTraderExchange is Ownable {
	address[] public positionsAddresses;

	mapping (address => bool) public positionExist;
	mapping (address => uint256) public positionIndex;

	IContractStorage public DS;

	event ReceivedTokens(uint256 volume, address tokenSender, address tokenAddress);
	event NewPosition(address token, uint256 volume, bool buySell, uint256 cost, address owner);
	event PositionClosed(address indexed position);
	event PositionCancelled(address indexed position);

	/**
	 * @dev TuneTraderExchange Constructor
	 */
	constructor (address _DS) public Ownable(msg.sender) {
		DS = IContractStorage(_DS);
		DS.registerName("positions");
		DS.registerName("positionExist");
		DS.registerName("positionIndex");
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addPosition(address token, uint256 volume, bool buySell, uint256 cost) public payable {
		require(buySell == false || msg.value == cost, "Buying positions must be created with ETH");

		TTPositionManager manager = (new TTPositionManager).value(msg.value)(token, volume, buySell, cost, msg.sender);
		uint256 index = DS.pushAddress(DS.key("positions"),address(manager));
		DS.setBool(DS.key(address(manager), "positionExist"),true);
		DS.setUint(DS.key(address(manager), "positionIndex"),index);

		emit NewPosition(token, volume, buySell, cost, msg.sender);
	}

	function terminatePosition(bool closedOrCancelled) external {
		require((DS.getBool(DS.key(msg.sender, "positionExist")) == true), "Position must exist on the list");

		uint256 index = DS.getUint(DS.key(msg.sender, "positionIndex"));
		uint256 maxIndex = getPositionsCount() - 1;

		if (index < maxIndex) {
			address miAddr = DS.getAddressFromTable(DS.key("positions"), maxIndex);
			DS.setUint(DS.key(miAddr, "positionIndex"), index);
			DS.setAddressInTable(DS.key("positions"), index, miAddr);
		}

		DS.delLastAddressInTable(DS.key("positions"));
		DS.delUint(DS.key(msg.sender, "positionIndex"));
		DS.delBool(DS.key(msg.sender, "positionExist"));

		if (closedOrCancelled == true) {
			emit PositionClosed(msg.sender);
		} else {
			emit PositionCancelled(msg.sender);
		}
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getPositions() public view returns (address[] memory) {
		return DS.getAddressTable(DS.key("positions"));
	}

	function getPositionsCount() public view returns (uint256) {
		return DS.getAddressTable(DS.key("positions")).length;
	}

	function tokenFallback(address _tokenSender, uint256 _value) public {
		emit ReceivedTokens(_value, _tokenSender, msg.sender);
	}
}