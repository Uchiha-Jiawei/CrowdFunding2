const fs = require('fs');
const path = require('path');

// 定义文件路径
const crowdfundingPath = path.join(__dirname, '../sloc/build/contracts/CrowdFunding.json');
const contractTsPath = path.join(__dirname, '../web/src/api/contract.ts');
const crowdfundingDestPath = path.join(__dirname, '../web/src/api/CrowdFunding.json');

try {
    // 确保目标目录存在
    const apiDir = path.dirname(crowdfundingDestPath);
    if (!fs.existsSync(apiDir)) {
        fs.mkdirSync(apiDir, { recursive: true });
    }

    // 读取合约JSON文件
    const crowdfundingJson = JSON.parse(fs.readFileSync(crowdfundingPath, 'utf8'));
    
    // 获取最新的网络ID和合约地址
    const networks = crowdfundingJson.networks;
    const networkIds = Object.keys(networks);
    const latestNetworkId = networkIds[networkIds.length - 1];
    const contractAddress = networks[latestNetworkId].address;

    // 1. 复制 CrowdFunding.json 到 src/api 目录
    fs.copyFileSync(crowdfundingPath, crowdfundingDestPath);
    console.log('CrowdFunding.json 已复制到 src/api 目录');

    // 2. 更新 contract.ts 中的合约地址
    let contractTsContent = fs.readFileSync(contractTsPath, 'utf8');
    const addressRegex = /(Contract\(CrowdFunding\.abi,\s*['"])[^'"]*(['"])/;
    const updatedContent = contractTsContent.replace(addressRegex, `$1${contractAddress}$2`);
    fs.writeFileSync(contractTsPath, updatedContent);

    console.log('更新完成：');
    console.log('1. CrowdFunding.json 已复制到 web/src/api/目录');
    console.log('2. contract.ts 中的合约地址已更新为:', contractAddress);
} catch (error) {
    console.error('更新过程中发生错误:', error);
    console.error('错误详情:', error.message);
    process.exit(1);
} 