// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Escrow{
  
  address payable public requesterWallet;
  address public approvalWallet;
  IERC20 immutable private token;
  uint public amountReleased;
  struct RequestPayments{
      uint milestone;
      uint amount;
      bool requested;
      bool completed;
      bool approved;
  }
  mapping (uint=>RequestPayments) public paymentsCheck;
  mapping (uint=>bool) public paymentsCheckExist;


  event Withdraw(address indexed withdrawer);
  
  
  
  constructor(
    address payable _requestWallet, 
    RequestPayments[] memory _payments,
    address _token

    ) {
    
    requesterWallet= _requestWallet;
    approvalWallet = msg.sender; 
      token=IERC20(_token);
    // payments=_payments;
    for (uint i=0;i<_payments.length;i++){
        paymentsCheck[i]=_payments[i];
        paymentsCheckExist[i]=true;

    }
      
    
        
  }
  modifier onlyApprovalWallet(){
      require(msg.sender==approvalWallet,"You are not allowed to approve funds");
      _;

  }
  modifier onlyRequestedWallet(){
      require(msg.sender==requesterWallet,"You are not allowed to request funds");
      _;

  }
  function requestPayment(uint index) public onlyRequestedWallet{
        require(paymentsCheck[index].completed==false,"Milestones not completed");
        require(paymentsCheck[index].requested==false,"Milestones already requested");

        paymentsCheck[index].requested=true;


  }
  function approvePayment(uint index) public onlyApprovalWallet{

      require(token.balanceOf(address(this))>paymentsCheck[index].amount,"Contract have not suffient tokens");
      require(paymentsCheck[index].requested==true,"Payment not requested");
      require(paymentsCheck[index].completed==true,"Milestone not copleted");
      require(paymentsCheck[index].approved==false,"Payment already approved");


      if(index!=0 && paymentsCheck[--index].completed==false){
         revert("Previous milestone not completed");
      }

      paymentsCheck[index].approved=true;
      amountReleased+=paymentsCheck[index].amount;
      token.transfer(requesterWallet,paymentsCheck[index].amount);
       
  }

  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }
  function updateCompleteMileStone(uint index)public onlyRequestedWallet{
       require(paymentsCheckExist[index],"Payment index not exits");
       paymentsCheck[index].completed=true;

  }
 
  fallback() external payable{

  }
  receive() external payable{

  }
  function withdrawFunds() public onlyApprovalWallet{
    require(address(this).balance>0,"no funds availabe");
    payable(approvalWallet).transfer(address(this).balance);
    emit Withdraw(approvalWallet);
 }
  
}