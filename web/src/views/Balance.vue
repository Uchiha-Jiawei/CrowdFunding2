<template>
  <div class="balance-container">
    <div class="balance-content">
      <a-card class="balance-card account-info">
        <template #title>
          <div class="card-header">
            <h2 class="title">账户信息</h2>
          </div>
        </template>
        <a-descriptions class="account-descriptions">
          <a-descriptions-item label="当前账户">
            <wallet-outlined />
            <span class="account-address">{{ state.account }}</span>
          </a-descriptions-item>
          <a-descriptions-item label="账户余额">
            <account-book-outlined />
            <span class="balance-amount">{{ state.balance }} ETH</span>
          </a-descriptions-item>
        </a-descriptions>
      </a-card>

      <a-card class="balance-card transaction-history">
        <template #title>
          <div class="card-header">
            <h2 class="title">交易记录</h2>
          </div>
        </template>
        <a-table 
          :columns="transactionColumns" 
          :loading="state.loading" 
          :data-source="state.transactions"
          :pagination="{ 
            pageSize: 10,
            showTotal: total => `共 ${total} 条交易记录`
          }"
          :row-class-name="(_record, index) => index % 2 === 0 ? 'table-striped' : ''"
        >
          <template #time="{text}">
            <span class="time-text">
              <calendar-outlined />
              {{new Date(text * 1000).toLocaleString()}}
            </span>
          </template>
          <template #tag="{record}">
            <a-tag :class="getTransactionClass(record)">
              <template #icon>
                <component :is="getTransactionIcon(record)" />
              </template>
              {{ record.type === 'in' ? '收款' : '支出' }}
            </a-tag>
          </template>
          <template #amount="{text}">
            <span class="amount-text">{{text}} ETH</span>
          </template>
          <template #address="{text}">
            <span class="address-text" :title="text">
              {{formatAddress(text)}}
            </span>
          </template>
          <template #type="{text}">
            <span class="type-text">{{formatTxType(text)}}</span>
          </template>
        </a-table>
      </a-card>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import { Model, Fields, Form } from '../type/form'
import { contract, getAccount, getAllFundings, Funding, newFunding, getMyFundings, addListener, getBalance, getTransactionHistory, Transaction } from '../api/contract'
import { message } from 'ant-design-vue'
import { 
  CheckCircleOutlined, 
  SyncOutlined, 
  CloseCircleOutlined,
  WalletOutlined,
  AccountBookOutlined,
  CalendarOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined
} from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'

const transactionColumns = [
  {
    title: '时间',
    dataIndex: 'timestamp',
    key: 'timestamp',
    slots: { customRender: 'time' },
    sorter: (a: Transaction, b: Transaction) => (a.timestamp || 0) - (b.timestamp || 0),
    width: '180px'
  },
  {
    title: '类型',
    dataIndex: 'txType',
    key: 'txType',
    slots: { customRender: 'type' },
    width: '120px'
  },
  {
    title: '金额',
    dataIndex: 'amount',
    key: 'amount',
    sorter: (a: Transaction, b: Transaction) => (parseFloat(a.amount) || 0) - (parseFloat(b.amount) || 0),
    slots: { customRender: 'amount' },
    width: '120px'
  },
  {
    title: '发送方',
    dataIndex: 'from',
    key: 'from',
    slots: { customRender: 'address' }
  },
  {
    title: '接收方',
    dataIndex: 'to',
    key: 'to',
    slots: { customRender: 'address' }
  }
]

export default defineComponent({
  name: 'Balance',
  components: { 
    Modal, 
    CreateForm, 
    CheckCircleOutlined, 
    SyncOutlined, 
    CloseCircleOutlined,
    WalletOutlined,
    AccountBookOutlined,
    CalendarOutlined,
    ArrowUpOutlined,
    ArrowDownOutlined
  },
  setup() {
    const isOpen = ref<boolean>(false);
    const state = reactive<{
      loading: boolean, 
      init: Funding[], 
      contr: Funding[],
      account: string,
      balance: string,
      transactions: Transaction[]
    }>({
      loading: true,
      init: [],
      contr: [],
      account: '',
      balance: '0',
      transactions: []
    })

    async function fetchData() {
      state.loading = true;
      try {
        const res = await getMyFundings();
        const account = await getAccount();
        const balance = await getBalance();
        const transactions = await getTransactionHistory();
        state.init = res.init;
        state.contr = res.contr;
        state.account = account;
        state.balance = balance;
        state.transactions = transactions;
        state.loading = false;
      } catch (e) {
        console.log(e);
        message.error('获取数据失败!');
      }
    }

    const getTransactionClass = (record: any) => {
      return record.type === 'in' ? 'status-tag success' : 'status-tag warning'
    }

    const getTransactionIcon = (record: any) => {
      return record.type === 'in' ? ArrowDownOutlined : ArrowUpOutlined
    }

    const formatAddress = (address: string) => {
      if (!address) return '';
      return `${address.slice(0, 6)}...${address.slice(-4)}`
    }

    const formatTxType = (type: string) => {
      const typeMap: {[key: string]: string} = {
        'contribute': '投资众筹',
        'return': '退回资金',
        'withdraw': '提取资金',
        'cancel': '取消众筹'
      }
      return typeMap[type] || type
    }

    const router = useRouter();
    const clickFunding = (index : number) => {
      router.push(`/funding/${index}`)
    }
    addListener(fetchData)
    fetchData();

    return { 
      state, 
      clickFunding, 
      transactionColumns,
      getTransactionClass,
      getTransactionIcon,
      formatAddress,
      formatTxType
    }
  }
});
</script>

<style scoped>
.balance-container {
  padding: 24px;
  background: #f0f2f5;
  min-height: calc(100vh - 64px);
}

.balance-content {
  max-width: 1200px;
  margin: 0 auto;
}

.balance-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03),
              0 1px 6px -1px rgba(0, 0, 0, 0.02),
              0 2px 4px rgba(0, 0, 0, 0.02);
}

.transaction-history {
  margin-top: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header .title {
  margin: 0;
  color: #1f1f1f;
  font-size: 18px;
}

.account-descriptions {
  padding: 16px;
}

:deep(.ant-descriptions-item-label) {
  color: #666;
  font-weight: 500;
}

:deep(.ant-descriptions-item-content) {
  display: flex;
  align-items: center;
  gap: 8px;
}

.account-address {
  color: #1890ff;
  font-family: monospace;
  font-size: 14px;
}

.balance-amount {
  color: #52c41a;
  font-weight: 500;
  font-size: 16px;
}

.table-striped {
  background-color: #fafafa;
}

.time-text {
  color: #666;
  display: flex;
  align-items: center;
  gap: 8px;
}

.amount-text {
  color: #1890ff;
  font-weight: 500;
}

.address-text {
  font-family: monospace;
  color: #666;
}

.type-text {
  color: #1f1f1f;
}

.status-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  padding: 4px 12px;
  border-radius: 4px;
}

.status-tag.success {
  color: #52c41a;
  background: #f6ffed;
  border-color: #b7eb8f;
}

.status-tag.warning {
  color: #faad14;
  background: #fffbe6;
  border-color: #ffe58f;
}

:deep(.ant-table-thead > tr > th) {
  background: #fafafa;
  font-weight: 500;
}

:deep(.ant-table-tbody > tr > td) {
  padding: 12px 16px;
}

:deep(.ant-table-column-sorter) {
  color: #bfbfbf;
}

:deep(.ant-pagination) {
  margin-top: 16px;
}

:deep(.ant-card-body) {
  padding: 0;
}

:deep(.ant-descriptions) {
  padding: 24px;
}
</style>
