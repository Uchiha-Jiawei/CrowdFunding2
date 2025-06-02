<template>
  <div>
    <div>
      <a-card class="ant-card-shadow">
        <template #title>
          <h3>
            账户信息
          </h3>
        </template>
        <a-descriptions>
          <a-descriptions-item label="当前账户">
            {{ state.account }}
          </a-descriptions-item>
          <a-descriptions-item label="账户余额">
            {{ state.balance }} ETH
          </a-descriptions-item>
        </a-descriptions>
      </a-card>

      <a-card class="ant-card-shadow" style="margin-top: 1em;">
        <template #title>
          <h3>
            交易记录
          </h3>
        </template>
        <a-table :columns="transactionColumns" :loading="state.loading" :data-source="state.transactions">
          <template #time="{text, record}">
            {{new Date(text * 1000).toLocaleString()}}
          </template>
          <template #tag="{text, record}">
            <a-tag :color="record.type === 'in' ? 'success' : 'warning'">
              {{ record.type === 'in' ? '收款' : '支出' }}
            </a-tag>
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
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'

const columns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题'
  },
  {
    title: '目标金额(eth)',
    dataIndex: 'goal',
    key: 'goal'
  },
  {
    title: '目前金额(eth)',
    dataIndex: 'amount',
    key: 'amount'
  },
  {
    title: '我投资的金额',
    dataIndex: 'myAmount',
    key: 'amount'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' }
  },
  {
    title: '当前状态',
    dataIndex: 'success',
    key: 'success',
    slots: { customRender: 'tag' }
  },
  {
    title: '详情',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  },
]

const transactionColumns = [
  {
    title: '时间',
    dataIndex: 'timestamp',
    key: 'timestamp',
    slots: { customRender: 'time' },
    sorter: (a: Transaction, b: Transaction) => (a.timestamp || 0) - (b.timestamp || 0)
  },
  {
    title: '类型',
    dataIndex: 'txType',
    key: 'txType'
  },
  {
    title: '金额(ETH)',
    dataIndex: 'amount',
    key: 'amount',
    sorter: (a: Transaction, b: Transaction) => (parseInt(a.amount) || 0) - (parseInt(b.amount) || 0)
    
  },
  {
    title: '发送方',
    dataIndex: 'from',
    key: 'from'
  },
  {
    title: '接收方',
    dataIndex: 'to',
    key: 'to'
  }
]

export default defineComponent({
  name: 'Myself',
  components: { Modal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined },
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

    const router = useRouter();
    const clickFunding = (index : number) => {
      router.push(`/funding/${index}`)
    }
    addListener(fetchData)
    fetchData();

    return { state, columns, clickFunding, transactionColumns }
  }
});
</script>
