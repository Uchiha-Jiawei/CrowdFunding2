// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CrowdFunding {
  
  // 交易记录结构定义
  struct Transaction {
    address from;           // 发送方地址
    address to;            // 接收方地址
    uint amount;          // 交易金额
    uint timestamp;       // 交易时间
    string txType;        // 交易类型（投资/退款/使用资金）
  }

  // 投资人结构定义
  struct Funder {
    address payable addr;   // 投资人的地址，应该是 address payable 类型
    uint amount;            // 出资数额
  }

  // 资金使用请求结构定义
  struct Use {
    string info;                     // 使用请求的说明
    uint goal;                       // 使用请求的数额
    uint agreeAmount;                // 目前的同意数额
    uint disagree;                   // 目前的不同意数额
    bool over;                       // 请求是否结束
    mapping(uint => uint) agree;     // 出资人是否同意 0: 还没决定，1：同意，2：不同意
  }

  // 众筹项目的结构定义
  struct Funding {
    address payable initiator;       // 发起人，应该是 address payable 类型
    string title;                    // 项目标题
    string info;                     // 项目简介
    uint goal;                       // 目标金额
    uint startTime;                  // 众筹开始时间
    uint endTime;                    // 众筹结束时间

    bool success;                    // 众筹是否成功，成功则 amount 含义为项目剩余的钱
    bool isCancel;                   // 判断众筹是否取消
    uint amount;                     // 当前已经筹集到的金额
    uint numFunders;                 // 投资记录数量
    uint numUses;                    // 使用请求数量
    mapping(uint => Funder) funders; // 投资记录具体信息
    mapping(uint => Use) uses;       // 所有的使用请求
  }

  uint public numFundings;                  // 众筹项目数量
  mapping(uint => Funding) public fundings; // 所有的众筹项目

  uint public numTransactions;                      // 交易记录数量
  mapping(uint => Transaction) public transactions; // 所有的交易记录
  mapping(address => uint[]) userTransactions;      // 用户参与的交易记录ID

  /**
   * 发起众筹项目
   * @param initiator 发起人
   * @param title 项目标题
   * @param info 项目简介
   * @param goal 目标金额
   * @param endTime 结束时间
   */
  function newFunding(address payable initiator, string memory title, string memory info, uint goal, uint endTime) public returns(uint) {
    require(endTime > block.timestamp);

    numFundings = numFundings + 1;
    Funding storage f = fundings[numFundings];
    f.initiator = initiator;
    f.title = title;
    f.info = info;
    f.goal = goal;
    f.startTime = block.timestamp;
    f.endTime = endTime;
    f.isCancel = false;
    f.success = false;
    f.amount = 0;
    f.numFunders = 0;
    f.numUses = 0;
    
    return numFundings;
  }

  // 记录交易
  function recordTransaction(address from, address to, uint amount, string memory txType) internal {
    numTransactions++;
    Transaction storage t = transactions[numTransactions];
    t.from = from;
    t.to = to;
    t.amount = amount;
    t.timestamp = block.timestamp;
    t.txType = txType;
    
    userTransactions[from].push(numTransactions);
    if(from != to) {
      userTransactions[to].push(numTransactions);
    }
  }

  // 获取用户交易记录数量
  function getUserTransactionCount(address user) public view returns(uint) {
    return userTransactions[user].length;
  }

  // 获取用户交易记录ID
  function getUserTransactionIds(address user) public view returns(uint[] memory) {
    return userTransactions[user];
  }

  // 获取交易记录详情
  function getTransaction(uint id) public view returns(address, address, uint, uint, string memory) {
    require(id > 0 && id <= numTransactions, "Invalid transaction ID");
    Transaction storage t = transactions[id];
    return (t.from, t.to, t.amount, t.timestamp, t.txType);
  }

  function contribute(uint ID) public payable {
    // 贡献的钱必须大于0，不能超过差额
    require(msg.value > 0 && msg.value <= fundings[ID].goal - fundings[ID].amount);
    // 时间上必须还没结束
    require(fundings[ID].endTime > block.timestamp);
    // 必须是未完成的众筹
    require(fundings[ID].success == false);
    Funding storage f = fundings[ID];
    f.amount += msg.value;
    f.numFunders = f.numFunders + 1;
    f.funders[f.numFunders].addr = msg.sender;
    f.funders[f.numFunders].amount = msg.value;
    // 考虑本项目是否达成目标
    f.success = f.amount >= f.goal;
    // 记录交易
    recordTransaction(msg.sender, address(this), msg.value, "投资");
  }

  // 退钱
  function returnMoney(uint ID, uint returnAmount) public {
    require(ID <= numFundings && ID >= 1, "Invalid funding ID");
    require(fundings[ID].success == false, "Cannot return money from successful funding");

    Funding storage f = fundings[ID];
    uint totalInvested = 0;
    
    // 先计算用户在此项目中的总投资
    for(uint i=1; i<=f.numFunders; i++) {
      if(f.funders[i].addr == msg.sender) {
        totalInvested += f.funders[i].amount;
      }
    }
    
    require(totalInvested >= returnAmount, "Cannot return more than invested");
    require(returnAmount > 0, "Return amount must be greater than 0");
    
    uint remainingToReturn = returnAmount;
    
    // 从最新的投资记录开始退款
    for(uint i=f.numFunders; i>=1 && remainingToReturn > 0; i--) {
      if(f.funders[i].addr == msg.sender && f.funders[i].amount > 0) {
        uint currentReturn = remainingToReturn;
        if(currentReturn > f.funders[i].amount) {
          currentReturn = f.funders[i].amount;
        }
        
        f.funders[i].amount -= currentReturn;
        remainingToReturn -= currentReturn;
        f.amount -= currentReturn;
        
        if(remainingToReturn == 0) {
          msg.sender.transfer(returnAmount);
          // 记录交易
          recordTransaction(address(this), msg.sender, returnAmount, "退款");
          break;
        }
      }
    }
  }

  function newUse(uint ID, uint goal, string memory info) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].success == true);
    require(goal <= fundings[ID].amount);
    require(msg.sender == fundings[ID].initiator);

    Funding storage f = fundings[ID];
    f.numUses = f.numUses + 1;
    f.uses[f.numUses].info = info;
    f.uses[f.numUses].goal = goal;
    f.uses[f.numUses].agreeAmount = 0;
    f.uses[f.numUses].disagree = 0;
    f.uses[f.numUses].over = false;
    f.amount = f.amount - goal;
    
  }

  function agreeUse(uint ID, uint useID, bool agree) public {
    require(ID <= numFundings && ID >= 1);
    require(useID <= fundings[ID].numUses && useID >= 1);
    require(fundings[ID].uses[useID].over == false);

    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == msg.sender) {
        if(fundings[ID].uses[useID].agree[i] == 1) {
          fundings[ID].uses[useID].agreeAmount -= fundings[ID].funders[i].amount;
        } else if(fundings[ID].uses[useID].agree[i] == 2) {
          fundings[ID].uses[useID].disagree -= fundings[ID].funders[i].amount;
        }
        if(agree) {
          fundings[ID].uses[useID].agreeAmount += fundings[ID].funders[i].amount;
          fundings[ID].uses[useID].agree[i] = 1;
        }
        else {
          fundings[ID].uses[useID].disagree += fundings[ID].funders[i].amount;
          fundings[ID].uses[useID].agree[i] = 2;
        }
      }
    checkUse(ID, useID);
  }

  function checkUse(uint ID, uint useID) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].uses[useID].over == false);

    if(fundings[ID].uses[useID].agreeAmount >= fundings[ID].goal / 2) {
      fundings[ID].uses[useID].over = true;
      fundings[ID].initiator.transfer(fundings[ID].uses[useID].goal); // 转账时，使用 address payable 类型
      // 记录交易
      recordTransaction(address(this), fundings[ID].initiator, fundings[ID].uses[useID].goal, "使用资金");
    }
    if(fundings[ID].uses[useID].disagree > fundings[ID].goal / 2) {
      fundings[ID].amount = fundings[ID].amount + fundings[ID].uses[useID].goal;
      fundings[ID].uses[useID].over = true;
    }
  }

  function getUseLength(uint ID) public view returns (uint) {
    require(ID <= numFundings && ID >= 1);

    return fundings[ID].numUses;
  }

  function getUse(uint ID, uint useID, address addr) public view returns (string memory, uint, uint, uint, bool, uint) {
    require(ID <= numFundings && ID >= 1);
    require(useID <= fundings[ID].numUses && useID >= 1);

    Use storage u = fundings[ID].uses[useID];
    uint agree = 0;
    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == addr) {
        agree = fundings[ID].uses[useID].agree[i];
        break;
      }
    return (u.info, u.goal, u.agreeAmount, u.disagree, u.over, agree);
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }
  
  function getMyFundings(address addr, uint ID) public view returns (uint) {
      uint res = 0;
      for(uint i=1; i<=fundings[ID].numFunders; i++) {
          if(fundings[ID].funders[i].addr == addr)
            res += fundings[ID].funders[i].amount;
      }
      return res;
  } 

  // 取消众筹
  function cancelFunding(uint ID) public {
    require(ID <= numFundings && ID >= 1, "Invalid funding ID");
    require(fundings[ID].success == false, "Cannot cancel successful funding");
    require(msg.sender == fundings[ID].initiator, "Only initiator can cancel funding");

    Funding storage f = fundings[ID];
    
    // 退还所有投资者的资金
    for(uint i=1; i<=f.numFunders; i++) {
      if(f.funders[i].amount > 0) {
        uint amount = f.funders[i].amount;
        f.funders[i].addr.transfer(amount);
        
        // 记录退款交易
        recordTransaction(address(this), f.funders[i].addr, amount, "众筹取消退款");
        
        // 清零投资记录
        f.funders[i].amount = 0;
      }
    }
    
    // 更新众筹状态
    f.amount = 0;
    f.isCancel = true;
    f.endTime = block.timestamp;
    // 记录取消操作
    recordTransaction(msg.sender, address(this), 0, "取消众筹");
  }

  // 检查众筹是否超时并处理退款
  function checkTimeoutAndRefund(uint ID) public {
    require(ID <= numFundings && ID >= 1, "Invalid funding ID");
    Funding storage f = fundings[ID];
    
    // 检查是否已超时且未成功
    require(block.timestamp > f.endTime, "Funding not timeout yet");
    require(!f.success, "Funding is successful");
    require(!f.isCancel, "Funding is already cancelled");
    
    // 退还所有投资者的资金
    for(uint i=1; i<=f.numFunders; i++) {
      if(f.funders[i].amount > 0) {
        uint amount = f.funders[i].amount;
        f.funders[i].addr.transfer(amount);
        
        // 记录退款交易
        recordTransaction(address(this), f.funders[i].addr, amount, "众筹超时退款");
        
        // 清零投资记录
        f.funders[i].amount = 0;
      }
    }
    // 更新众筹状态
    f.amount = 0;
  }

  // 获取众筹项目的投资人数量
  function getFunderCount(uint ID) public view returns (uint) {
    require(ID <= numFundings && ID >= 1, "Invalid funding ID");
    return fundings[ID].numFunders;
  }

  // 获取指定众筹项目中某个投资人的信息
  function getFunder(uint ID, uint funderIndex) public view returns (address, uint) {
    require(ID <= numFundings && ID >= 1, "Invalid funding ID");
    require(funderIndex <= fundings[ID].numFunders && funderIndex >= 1, "Invalid funder index");
    
    Funder storage funder = fundings[ID].funders[funderIndex];
    return (funder.addr, funder.amount);
  }
}
