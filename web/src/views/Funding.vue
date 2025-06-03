<template>
  <div class="funding-container">
    <a-card 
      class="funding-detail-card" 
      :loading="state.loading" 
      :tab-list="tabList"
      :active-tab-key="key"
      @tabChange="onTabChange"
    >
      <template #title>
        <div class="card-header">
          <h2 class="title">{{state.data.title}}</h2>
          <div class="header-actions">
            <span class="investment-amount">当前投资: {{state.myAmount}} ETH</span>
            <div class="action-buttons">
              <a-button 
                type="primary" 
                v-if="new Date(state.data.endTime * 1000) > new Date() && state.data.success == false" 
                @click="openInvestModal"
                class="action-button"
              >
                <wallet-outlined />
                我要投资
              </a-button>
              <a-button 
                danger 
                v-if="!state.data.success && state.myAmount != 0" 
                @click="openReturnModal"
                class="action-button"
              >
                <rollback-outlined />
                退钱
              </a-button>
            </div>
          </div>
        </div>
      </template>

      <a-descriptions bordered v-if="key==='info'" class="funding-info">
        <a-descriptions-item label="众筹标题" :span="2">
          {{state.data.title}}
        </a-descriptions-item>
        <a-descriptions-item label="众筹发起人" :span="2">
          <tag-outlined /> {{state.data.initiator}}
        </a-descriptions-item>
        <a-descriptions-item label="开始日期" :span="2">
          <calendar-outlined /> {{new Date(state.data.startTime * 1000).toLocaleString()}}
        </a-descriptions-item>
        <a-descriptions-item label="截止日期" :span="2">
          <clock-circle-outlined /> {{new Date(state.data.endTime * 1000).toLocaleString()}}
        </a-descriptions-item>
        <a-descriptions-item label="当前状态">
          <a-tag :class="getStatusClass(state.data)">
            <template #icon>
              <component :is="getStatusIcon(state.data)" />
            </template>
            {{getStatusText(state.data)}}
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="目标金额">
          <a-statistic 
            :value="state.data.goal"
            class="funding-statistic"
          >
            <template #suffix>ETH</template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="当前金额">
          <a-statistic 
            :value="state.data.amount"
            class="funding-statistic"
          >
            <template #suffix>ETH</template>
          </a-statistic>
        </a-descriptions-item>
        <a-descriptions-item label="众筹进度">
          <a-progress 
            type="circle" 
            :percent="state.data.success ? 100 : (state.data.amount * 100 / state.data.goal).toFixed(2)" 
            :width="80"
            :stroke-color="getProgressColor(state.data)"
          />
        </a-descriptions-item>
        <a-descriptions-item label="众筹介绍" class="funding-description">
          {{state.data.info}}
        </a-descriptions-item>
      </a-descriptions>

      <div class="investors-section">
        <h3 class="section-title">投资人列表</h3>
        <a-table
          :columns="investorColumns"
          :data-source="state.investors"
          :pagination="{ 
            pageSize: 5,
            showTotal: total => `共 ${total} 位投资人`
          }"
          :row-class-name="(_record, index) => index % 2 === 0 ? 'table-striped' : ''"
        >
          <template #address="{text}">
            <span class="investor-address" :title="text">
              <user-outlined />
              {{formatAddress(text)}}
            </span>
          </template>
          <template #amount="{text}">
            <span class="amount-text">{{text}} ETH</span>
          </template>
        </a-table>
      </div>

      <Use v-if="key==='use'" :id="id" :data="state.data" :amount="state.myAmount"></Use>
    </a-card>

    <Modal v-model:visible="isInvestOpen">
      <a-card class="modal-card">
        <template #title>
          <div class="modal-header">
            <h2>投资项目</h2>
          </div>
        </template>
        <create-form :model="investModel" :form="investForm" :fields="investFields" class="create-form" />
      </a-card>
    </Modal>

    <Modal v-model:visible="isReturnOpen">
      <a-card class="modal-card">
        <template #title>
          <div class="modal-header">
            <h2>申请退款</h2>
          </div>
        </template>
        <create-form :model="returnModel" :form="returnForm" :fields="returnFields" class="create-form" />
      </a-card>
    </Modal>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, reactive, computed } from 'vue';
import { getOneFunding, Funding, getAccount, getMyFundingAmount, contribute, returnMoney, addListener, getMyFundings, checkTimeoutAndRefund, getInvestors } from '../api/contract'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue';
import { 
  CheckCircleOutlined, 
  SyncOutlined, 
  CloseCircleOutlined,
  WalletOutlined,
  RollbackOutlined,
  TagOutlined,
  CalendarOutlined,
  ClockCircleOutlined,
  UserOutlined
} from '@ant-design/icons-vue'
import Modal from '../components/base/modal.vue'
import CreateForm from '../components/base/createForm.vue'
import Use from '../components/Use.vue'
import { Model, Fields, Form } from '../type/form'

const column = [
  {
    dataIndex: ''
  }
]

const tabList = [
  {
    key: 'info',
    tab: '项目介绍',
  },
  {
    key: 'use',
    tab: '使用请求',
  },
];

const investorColumns = [
  {
    title: '投资人地址',
    dataIndex: 'investor',
    key: 'investor',
    slots: { customRender: 'address' },
    width: '60%'
  },
  {
    title: '投资金额',
    dataIndex: 'amount',
    key: 'amount',
    slots: { customRender: 'amount' },
    sorter: (a: any, b: any) => (parseFloat(a.amount) || 0) - (parseFloat(b.amount) || 0)
  }
]

export default defineComponent({
  name: 'Funding',
  components: { 
    Modal, 
    CreateForm, 
    CheckCircleOutlined, 
    SyncOutlined, 
    CloseCircleOutlined,
    WalletOutlined,
    RollbackOutlined,
    TagOutlined,
    CalendarOutlined,
    ClockCircleOutlined,
    UserOutlined,
    Use 
  },
  setup() {
    // =========基本数据==========
    const route = useRoute();
    const id = parseInt(route.params.id as string);
    const account = ref('');
    const state = reactive<{
      data: Funding | {}, 
      loading: boolean, 
      myAmount: number,
      investors: any[]
    }>({
      data: {},
      loading: true,
      myAmount: 0,
      investors: []
    })

    // ===========发起投资表单============
    const isInvestOpen = ref(false);
    const isReturnOpen = ref(false);
    function openInvestModal() { isInvestOpen.value = true }
    function closeInvestModal() { isInvestOpen.value = false }
    function openReturnModal() { isReturnOpen.value = true }
    function closeReturnModal() { isReturnOpen.value = false }

    const investModel = reactive<Model>({
      value: 1
    })
    const investFields = reactive<Fields>({
      value: {
        type: 'number',
        min: 1,
        label: '投资金额'
      }
    })
    const investForm = reactive<Form>({
      submitHint: '投资',
      cancelHint: '取消',
      cancel: () => {
        closeInvestModal();
      },
      finish: async () => {
        try {
          await contribute(id, investModel.value);
          message.success('投资成功')
          fetchData();
          closeInvestModal();
        } catch (e) {
          message.error('投资失败')
        }
      }
    })

    const returnModel = reactive<Model>({
      value: 1
    })
    const returnFields = reactive<Fields>({
      value: {
        type: 'number',
        min: 0.000000000000000001, // 最小单位为1 Wei
        label: '退款金额'
      }
    })
    const returnForm = reactive<Form>({
      submitHint: '退款',
      cancelHint: '取消',
      cancel: () => {
        closeReturnModal();
      },
      finish: async () => {
        try {
          await returnMoney(id, returnModel.value);
          message.success('退款成功');
          fetchData();
          closeReturnModal();
        } catch (e) {
          message.error('退款失败')
        }
      }
    })

    // =========切换标签页===========
    const key = ref('info');
    const onTabChange = (k : 'use' | 'info') => {
      key.value = k;
    }

    // =========加载数据===========
    async function fetchData() {
      state.loading = true;
      try {    
        const [fundingData, myAmount, investors] = await Promise.all([
          getOneFunding(id), 
          getMyFundingAmount(id),
          getInvestors(id)
        ]);
        
        state.data = fundingData;
        state.myAmount = myAmount;
        state.investors = investors;
        
        state.loading = false;
        //@ts-ignore
        investFields.value.max = state.data.goal - state.data.amount;
        returnFields.value.max = state.myAmount;
      } catch (e) {
        console.log(e);
        message.error('获取详情失败');
      }
    }

    addListener(fetchData)

    getAccount().then(res => account.value = res)
    fetchData();

    const getStatusClass = (data: any) => {
      if (data.success === true) return 'status-tag success'
      if (data.isCancel === true) return 'status-tag warning'
      if (new Date(data.endTime * 1000) > new Date()) return 'status-tag processing'
      return 'status-tag error'
    }

    const getStatusIcon = (data: any) => {
      if (data.success === true) return CheckCircleOutlined
      if (data.isCancel === true) return CloseCircleOutlined
      if (new Date(data.endTime * 1000) > new Date()) return SyncOutlined
      return CloseCircleOutlined
    }

    const getStatusText = (data: any) => {
      if (data.success === true) return '众筹成功'
      if (data.isCancel === true) return '众筹取消'
      if (new Date(data.endTime * 1000) > new Date()) return '正在众筹'
      return '众筹超时'
    }

    const getProgressColor = (data: any) => {
      if (data.success === true) return '#52c41a'
      if (data.isCancel === true) return '#faad14'
      if (new Date(data.endTime * 1000) > new Date()) return '#1890ff'
      return '#ff4d4f'
    }

    const formatAddress = (address: string) => {
      if (!address) return '';
      return `${address.slice(0, 6)}...${address.slice(-4)}`
    }

    return {
      state, 
      account, 
      isInvestOpen,
      isReturnOpen, 
      openInvestModal,
      openReturnModal, 
      investForm,
      returnForm, 
      investModel,
      returnModel, 
      investFields,
      returnFields, 
      tabList, 
      key, 
      onTabChange, 
      id,
      getStatusClass,
      getStatusIcon,
      getStatusText,
      getProgressColor,
      investorColumns,
      formatAddress
    }
  }
});
</script>

<style scoped>
.funding-container {
  padding: 24px;
  background: #f0f2f5;
  min-height: calc(100vh - 64px);
}

.funding-detail-card {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03),
              0 1px 6px -1px rgba(0, 0, 0, 0.02),
              0 2px 4px rgba(0, 0, 0, 0.02);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.card-header .title {
  margin: 0;
  color: #1f1f1f;
  font-size: 20px;
  flex: 1;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.investment-amount {
  font-size: 16px;
  color: #1890ff;
  font-weight: 500;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.action-button {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  padding: 0 16px;
  border-radius: 6px;
}

.funding-info {
  margin-top: 24px;
}

:deep(.ant-descriptions-item-label) {
  width: 120px;
  background: #fafafa;
}

:deep(.ant-descriptions-item-content) {
  display: flex;
  align-items: center;
  gap: 8px;
}

.funding-statistic {
  :deep(.ant-statistic-content) {
    display: flex;
    align-items: baseline;
    gap: 4px;
    color: #1890ff;
    font-size: 20px;
  }
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

.status-tag.processing {
  color: #1890ff;
  background: #e6f7ff;
  border-color: #91d5ff;
}

.status-tag.error {
  color: #ff4d4f;
  background: #fff2f0;
  border-color: #ffccc7;
}

.funding-description {
  white-space: pre-wrap;
  line-height: 1.6;
}

.modal-card {
  width: 600px;
  margin: 0 2em;
  border-radius: 8px;
}

.modal-header {
  text-align: center;
}

.modal-header h2 {
  margin: 0;
  color: #1f1f1f;
  font-size: 20px;
}

.create-form {
  margin-top: 16px;
}

:deep(.ant-form-item) {
  margin-bottom: 24px;
}

:deep(.ant-input),
:deep(.ant-input-number),
:deep(.ant-picker) {
  border-radius: 6px;
}

:deep(.ant-tabs-nav) {
  margin-bottom: 24px;
}

:deep(.ant-tabs-tab) {
  font-size: 15px;
  padding: 12px 16px;
}

:deep(.ant-progress-text) {
  color: #1f1f1f;
  font-weight: 500;
}

.investors-section {
  margin-top: 24px;
  padding: 0 24px 24px;
}

.section-title {
  margin: 0 0 16px;
  color: #1f1f1f;
  font-size: 16px;
  font-weight: 500;
}

.investor-address {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #666;
  font-family: monospace;
}

.amount-text {
  color: #1890ff;
  font-weight: 500;
}

:deep(.ant-table-thead > tr > th) {
  background: #fafafa;
  font-weight: 500;
}

.table-striped {
  background-color: #fafafa;
}
</style>
