import Web3 from 'web3'
//@ts-ignore
import CrowdFunding from './CrowdFunding.json'

//@ts-ignore
const web3 = new Web3(window.ethereum);
const contract = new web3.eth.Contract(CrowdFunding.abi, '0x5200F3aF69902a18A8471dAf793e0Ef8c115576c');

function addListener(fn: Function) {
    //@ts-ignore
    ethereum.on('accountsChanged', fn)
}

export declare interface Funding {
    index: number,
    title: string,
    info: string,
    goal: number,
    startTime: number,
    endTime: number,
    initiator: string,
    over: boolean,
    isCancel: boolean,
    success: boolean,
    amount: number,
    numFunders: number,
    numUses: number,
    myAmount?: number
}

export declare interface Use {
    index: number,
    info: string,
    goal: string,
    agreeAmount: string,
    disagree: string,
    over: boolean,
    agree: number // 0: 没决定，1同意，2不同意
}

export declare interface Transaction {
    from: string,
    to: string,
    amount: string,
    timestamp: number,
    txType: string
}

async function authenticate() {
    //@ts-ignore
    await window.ethereum.enable();
}

async function getAccount() {
    return (await web3.eth.getAccounts())[0];
}

async function getAllFundings() : Promise<Funding[]> {
    console.log("hello")
    const length = await contract.methods.numFundings().call();
    const result = []
    for(let i=1; i<=length; i++)
        result.push(await getOneFunding(i));
    return result;
}

async function getOneFunding(index:number) : Promise<Funding> {
    const data = await contract.methods.fundings(index).call();
    data.goal = Web3.utils.fromWei(data.goal, 'ether')
    data.amount = Web3.utils.fromWei(data.amount, 'ether')

    return {index, ...data}
}

async function getMyFundingAmount(index:number) : Promise<number> {
    const account = await getAccount();
    return parseInt(Web3.utils.fromWei(await contract.methods.getMyFundings(account, index).call(), 'ether'));
}

async function getMyFundings() : Promise<{init: Funding[], contr: Funding[]}> {
    const account = await getAccount();
    const all = await getAllFundings();
    const result : {
        init: Funding[],
        contr: Funding[]
    } = {
        init: [],
        contr: []
    };
    for(let funding of all) {
        const myAmount = await getMyFundingAmount(funding.index);
        if(funding.initiator == account) {
            result.init.push({
                myAmount,
                ...funding
            })
        }
        if(myAmount != 0) {
            result.contr.push({
                myAmount,
                ...funding
            })
        }
    }
    return result;
}

async function contribute(id:number, value:number) {
    return await contract.methods.contribute(id).send({from: await getAccount(), value: Web3.utils.toWei(value.toString(10), 'ether')});
}

async function newFunding(account:string, title:string, info:string, amount:number, seconds:number) {
    return await contract.methods.newFunding(account, title, info, Web3.utils.toWei(amount.toString(10), 'ether'), seconds).send({
        from: account,
        gas: 1000000
    });
}

async function getAllUse(id:number) : Promise<Use[]> {
    const length = await contract.methods.getUseLength(id).call();
    const account = await getAccount();
    const rusult : Use[] = []
    for(let i=1; i<=length; i++) {
        const use = await contract.methods.getUse(id, i, account).call();
        rusult.push({
            index: i,
            info: use[0],
            goal: Web3.utils.fromWei(use[1], 'ether'),
            agreeAmount: Web3.utils.fromWei(use[2], 'ether'),
            disagree: Web3.utils.fromWei(use[3], 'ether'),
            over: use[4],
            agree: use[5]
        });
    }
    return rusult;
}

async function agreeUse(id:number, useID: number, agree:boolean) {
    const accont = await getAccount();
    return await contract.methods.agreeUse(id, useID, agree).send({
        from: accont,
        gas: 1000000
    })
}

async function newUse(id:number, goal:number, info:string) {
    const account = await getAccount();
    const eth = Web3.utils.toWei(goal.toString(10), 'ether')
    return await contract.methods.newUse(id, eth, info).send({
        from: account,
        gas: 1000000
    })
}

async function returnMoney(id: number, amount: number) {
    const account = await getAccount();
    return await contract.methods.returnMoney(id, Web3.utils.toWei(amount.toString(), 'ether')).send({
        from: account,
        gas: 1000000
    });
}

async function getBalance() : Promise<string> {
    const account = await getAccount();
    const balance = await web3.eth.getBalance(account);
    return Web3.utils.fromWei(balance, 'ether');
}

async function getTransactionHistory() : Promise<Transaction[]> {
    const account = await getAccount();
    const ids = await contract.methods.getUserTransactionIds(account).call();
    const transactions: Transaction[] = [];
    
    for(const id of ids) {
        const tx = await contract.methods.getTransaction(id).call();
        transactions.push({
            from: tx[0],
            to: tx[1],
            amount: Web3.utils.fromWei(tx[2].toString(), 'ether'),
            timestamp: parseInt(tx[3]),
            txType: tx[4]
        });
    }

    return transactions.sort((a, b) => b.timestamp - a.timestamp);
}

async function cancelFunding(id: number) {
    const account = await getAccount();
    return await contract.methods.cancelFunding(id).send({
        from: account,
        gas: 1000000
    });
}

// 检查众筹是否超时并退款
async function checkTimeoutAndRefund(id: number) {
  const account = await getAccount();
  return await contract.methods.checkTimeoutAndRefund(id).send({from: account});
}

async function getInvestors(id: number) : Promise<{investor: string, amount: string}[]> {
    try {
        const numFunders = await contract.methods.getFunderCount(id).call();
        const investorMap = new Map<string, string>();       
        // 收集所有投资记录
        for(let i = 1; i <= parseInt(numFunders); i++) {
            try {
                const result = await contract.methods.getFunder(id, i).call();            
                // 从返回对象中获取数据
                const addr = result[0];
                const amount = result[1];
                
                if(addr && addr !== '0x0000000000000000000000000000000000000000') {
                    const currentAmount = investorMap.get(addr) || '0';
                    const newAmount = (BigInt(currentAmount) + BigInt(amount)).toString();
                    investorMap.set(addr, newAmount);
                }
            } catch (error) {
                console.error(`Error fetching funder ${i}:`, error);
                continue;
            }
        }
               
        // 转换为数组格式
        const investors = Array.from(investorMap.entries())
            .filter(([_, amount]) => BigInt(amount) > BigInt(0))
            .map(([investor, amount]) => ({
                investor,
                amount: Web3.utils.fromWei(amount, 'ether')
            }));
        
        // 按投资金额降序排序
        investors.sort((a, b) => parseFloat(b.amount) - parseFloat(a.amount));
        return investors;
    } catch (error) {
        console.error('Error in getInvestors:', error);
        return [];
    }
}

export {
    getAccount,
    authenticate,
    contract,
    getAllFundings,
    getOneFunding,
    getMyFundingAmount,
    contribute,
    newFunding,
    getAllUse,
    agreeUse,
    newUse,
    getMyFundings,
    returnMoney,
    addListener,
    getBalance,
    getTransactionHistory,
    cancelFunding,
    checkTimeoutAndRefund,
    getInvestors
}
